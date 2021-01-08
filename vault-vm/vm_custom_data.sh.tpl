#!/bin/bash

# Prepare to install packages
apt-get update

# Install Azure CLI package
apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-get update
apt-get install -y azure-cli

# Install required system packages
apt-get install -y jq unzip cifs-utils

# Clean up
apt autoremove -y

# Disable SMB 1.0 for security
# See https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-linux#securing-linux
echo "options cifs disable_legacy_dialects=Y" | tee -a /etc/modprobe.d/local.conf > /dev/null

# Set up a UNIX user and group for Vault
VAULT_CONFIG_PATH="${vault_config_path}"
VAULT_RAFT_DATA="${vault_data_path}"
VAULT_SNAPSHOTS_PATH="${vault_snapshots_path}"
mkdir -p $VAULT_CONFIG_PATH $VAULT_RAFT_DATA $VAULT_SNAPSHOTS_PATH
groupadd --system -g ${gid} vault
useradd --system -u ${uid} -g vault --home $VAULT_CONFIG_PATH --shell /bin/false vault
chown root:${gid} $VAULT_CONFIG_PATH $VAULT_RAFT_DATA $VAULT_SNAPSHOTS_PATH
chmod 770 $VAULT_CONFIG_PATH $VAULT_RAFT_DATA
chmod 775 $VAULT_SNAPSHOTS_PATH

# Attach an Azure Files volume to store Vault snapshots in a redundant manner
smbPath="//${azure_files_endpoint}/${azure_files_share_name}"
uid=${uid}
gid=${gid}

mkdir -p "/etc/smbcredentials"

smbCredentialFile="/etc/smbcredentials/${storage_account_name}.cred"
echo "username=${storage_account_name}" | sudo tee $smbCredentialFile > /dev/null
echo "password=${storage_account_access_key}" | sudo tee -a $smbCredentialFile > /dev/null
chown root:root $smbCredentialFile
chmod 600 $smbCredentialFile

echo "$smbPath ${vault_snapshots_path} cifs nofail,vers=3.0,credentials=$smbCredentialFile,uid=$uid,gid=$gid,dir_mode=0755,file_mode=0644,serverino" | tee -a /etc/fstab > /dev/null

mount -a

# Install acme.sh so we can request an SSL certificate for TFE
ACME_INSTALL="/home/${username}/acme-sh-install"
ACME_HOME="/home/${username}/.acme.sh"
git clone https://github.com/acmesh-official/acme.sh.git $ACME_INSTALL
cd $ACME_INSTALL
./acme.sh --install --home $ACME_HOME
chown -R ${username}:${username} $ACME_HOME
cd $ACME_HOME
rm -rf $ACME_INSTALL

# Write to disk a script that will be run automatically after renewing the certificate
touch $ACME_HOME/hook_scripts.sh
chmod +x $ACME_HOME/hook_scripts.sh
cat << "EOF" | tee $ACME_HOME/hook_scripts.sh
#!/bin/bash

# Log in to Azure using the VM's managed identity
az login --identity

ACME_HOME="/home/${username}/.acme.sh"

# Check if cert files were modified recently
# Input file
FILE=$ACME_HOME/${vault_fqdn}/fullchain.cer
# The cert is arbitrarily considered to be old if the last modified time is more than 5 minutes ago
OLDTIME=300
# Get the current time
CURTIME=$(date +%s)
# Get the time the file was last modified
FILETIME=$(stat $FILE -c %Y)
# Get the difference between the two values
TIMEDIFF=$(expr $CURTIME - $FILETIME)

# Check if the file is older than $OLDTIME above
if [ $TIMEDIFF -gt $OLDTIME ]
then
  # If yes, then assume the cert renewal failed and exit with an error
  exit 1
else
  # If not, assume the cert was renewed successfully in the past few minutes, and upload it to Key Vault

  # Set the names of the Key Vault secrets
  SECRET_NAME_PREFIX=$(echo ${vault_fqdn} | tr "." "-")
  SECRET_CA_CERT="$SECRET_NAME_PREFIX-cert-ca"
  SECRET_FULLCHAIN_CERT="$SECRET_NAME_PREFIX-cert-fullchain"
  SECRET_CERT_FILE="$SECRET_NAME_PREFIX-cert-file"
  SECRET_CONF_FILE="$SECRET_NAME_PREFIX-cert-conf"
  SECRET_CSR_FILE="$SECRET_NAME_PREFIX-cert-csr"
  SECRET_CSR_CONF_FILE="$SECRET_NAME_PREFIX-cert-csr-conf"
  SECRET_PRIVATE_KEY="$SECRET_NAME_PREFIX-cert-private-key"

  # Store the files relating to the cert as base64 strings for ease of management
  CA_CERT=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/ca.cer)
  FULLCHAIN_CERT=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/fullchain.cer)
  CERT_FILE=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.cer)
  CONF_FILE=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.conf)
  CSR_FILE=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.csr)
  CSR_CONF_FILE=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.csr.conf)
  PRIVATE_KEY=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.key)

  az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CA_CERT --encoding base64 --value $CA_CERT
  az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_FULLCHAIN_CERT --encoding base64 --value $FULLCHAIN_CERT
  az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CERT_FILE --encoding base64 --value $CERT_FILE
  az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CONF_FILE --encoding base64 --value $CONF_FILE
  az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CSR_FILE --encoding base64 --value $CSR_FILE
  az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CSR_CONF_FILE --encoding base64 --value $CSR_CONF_FILE
  az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_PRIVATE_KEY --encoding base64 --value $PRIVATE_KEY
fi
EOF

# Log in to Azure using the VM's managed identity
az login --identity

# Set some env variables for acme.sh
export AZUREDNS_SUBSCRIPTIONID="${dns_validation_subscription_id}"
export AZUREDNS_TENANTID="${azure_tenant_id}"
export AZUREDNS_APPID="${azure_dns_client_id}"
export AZUREDNS_CLIENTSECRET="${azure_dns_client_secret}"

# Reusable function to check if a secret exists in Azure Key Vault
secret_exists () {
  local vault_name=$1
  local secret_name=$2
  if az keyvault secret show --vault-name $1 --name $2 2>&1 | grep file-encoding >/dev/null
  then
    retval=0
  else
    retval=1
  fi
  return "$retval"
}

# Set the names of the Key Vault secrets
SECRET_NAME_PREFIX=$(echo ${vault_fqdn} | tr "." "-")
SECRET_CA_CERT="$SECRET_NAME_PREFIX-cert-ca"
SECRET_FULLCHAIN_CERT="$SECRET_NAME_PREFIX-cert-fullchain"
SECRET_CERT_FILE="$SECRET_NAME_PREFIX-cert-file"
SECRET_CONF_FILE="$SECRET_NAME_PREFIX-cert-conf"
SECRET_CSR_FILE="$SECRET_NAME_PREFIX-cert-csr"
SECRET_CSR_CONF_FILE="$SECRET_NAME_PREFIX-cert-csr-conf"
SECRET_PRIVATE_KEY="$SECRET_NAME_PREFIX-cert-private-key"

# This checks if the full chain cert created by acme.sh already exists in Key Vault
# If yes, we attempt to pull the cert files from Key Vault.
# If not, we request a new cert from LetsEncrypt using acme.sh.
if secret_exists "${key_vault_name}" "$SECRET_FULLCHAIN_CERT" == 0
then
  echo "Found existing certificate for ${vault_fqdn} in Key Vault ${key_vault_name}, don't generate a new one."
  # Create the path where acme.sh expects cert files
  mkdir -p $ACME_HOME/${vault_fqdn}

  # acme.sh produces a bunch of files, gotta catch 'em all!
  echo "Downloading cert data from Key Vault..."
  az keyvault secret show --vault-name ${key_vault_name} --name $SECRET_CA_CERT | jq -r .value | base64 -d | tee $ACME_HOME/${vault_fqdn}/ca.cer > /dev/null
  az keyvault secret show --vault-name ${key_vault_name} --name $SECRET_FULLCHAIN_CERT | jq -r .value | base64 -d | tee $ACME_HOME/${vault_fqdn}/fullchain.cer > /dev/null
  az keyvault secret show --vault-name ${key_vault_name} --name $SECRET_CERT_FILE | jq -r .value | base64 -d | tee $ACME_HOME/${vault_fqdn}/${vault_fqdn}.cer > /dev/null
  az keyvault secret show --vault-name ${key_vault_name} --name $SECRET_CONF_FILE | jq -r .value | base64 -d | tee $ACME_HOME/${vault_fqdn}/${vault_fqdn}.conf > /dev/null
  az keyvault secret show --vault-name ${key_vault_name} --name $SECRET_CSR_FILE | jq -r .value | base64 -d | tee $ACME_HOME/${vault_fqdn}/${vault_fqdn}.csr > /dev/null
  az keyvault secret show --vault-name ${key_vault_name} --name $SECRET_CSR_CONF_FILE | jq -r .value | base64 -d | tee $ACME_HOME/${vault_fqdn}/${vault_fqdn}.csr.conf > /dev/null
  az keyvault secret show --vault-name ${key_vault_name} --name $SECRET_PRIVATE_KEY | jq -r .value | base64 -d | tee $ACME_HOME/${vault_fqdn}/${vault_fqdn}.key > /dev/null
  echo "Pulled existing certificate data from Key Vault." | tee /home/ubuntu/cert_status

  # This will add the Azure tenant/subscription/API creds to the acme.sh config file
  echo "Setting up acme.sh for future renewals..."
  echo "SAVED_AZUREDNS_SUBSCRIPTIONID=$AZUREDNS_SUBSCRIPTIONID" | tee -a $ACME_HOME/account.conf > /dev/null
  echo "SAVED_AZUREDNS_TENANTID=$AZUREDNS_TENANTID" | tee -a $ACME_HOME/account.conf > /dev/null
  echo "SAVED_AZUREDNS_APPID=$AZUREDNS_APPID" | tee -a $ACME_HOME/account.conf > /dev/null
  echo "SAVED_AZUREDNS_CLIENTSECRET=$AZUREDNS_CLIENTSECRET" | tee -a $ACME_HOME/account.conf > /dev/null

  echo "Finished setting up acme.sh."
else
  echo "Secret $SECRET_FULLCHAIN_CERT not found in Key Vault ${key_vault_name}, request a new cert from LetsEncrypt..."
  # Request a cert
  # Check whether Terraform was run with var.vm_certs_acme_staging = true or false
  # This controls whether we talk to LetsEncrypt's staging or prod endpoint
  if "${acme_staging}" == "true"
  then
    ACME_STAGING=" --staging"
  fi
  cd $ACME_HOME
  ./acme.sh$ACME_STAGING --home $ACME_HOME --issue --dns dns_azure -d ${vault_fqdn} --renew-hook $ACME_HOME/hook_scripts.sh
  cd -

  if [[ -f $ACME_HOME/${vault_fqdn}/fullchain.cer ]]
  then
    echo "The certificate was issued successfully, uploading it to Key Vault..."

    Store the files relating to the cert as base64 strings for ease of management
    CA_CERT=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/ca.cer)
    FULLCHAIN_CERT=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/fullchain.cer)
    CERT_FILE=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.cer)
    CONF_FILE=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.conf)
    CSR_FILE=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.csr)
    CSR_CONF_FILE=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.csr.conf)
    PRIVATE_KEY=$(base64 -w 0 $ACME_HOME/${vault_fqdn}/${vault_fqdn}.key)

    az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CA_CERT --encoding base64 --value $CA_CERT
    az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_FULLCHAIN_CERT --encoding base64 --value $FULLCHAIN_CERT
    az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CERT_FILE --encoding base64 --value $CERT_FILE
    az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CONF_FILE --encoding base64 --value $CONF_FILE
    az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CSR_FILE --encoding base64 --value $CSR_FILE
    az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_CSR_CONF_FILE --encoding base64 --value $CSR_CONF_FILE
    az keyvault secret set --vault-name ${key_vault_name} --name $SECRET_PRIVATE_KEY --encoding base64 --value $PRIVATE_KEY

    echo "A new cert was generated and uploaded to Key Vault." | tee /home/ubuntu/cert_status
  fi
fi

# This should stay at the end
echo "This file appears in /home/${username} to tell you when the VM custom data script is done running. It does NOT mean that the script ran without issues!" | tee /home/${username}/finished
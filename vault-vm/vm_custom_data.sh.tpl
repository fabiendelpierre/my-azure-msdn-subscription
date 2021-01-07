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
# ...
# ...

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

echo "This file appears in /home/${username} to tell you when the VM custom data script is done running. It does NOT mean that the script ran without issues!" | tee /home/${username}/finished
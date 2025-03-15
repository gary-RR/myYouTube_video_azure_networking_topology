!/bin/bash
export MSYS_NO_PATHCONV=1
location='westus' #'westus3' #'westus3' #'centralus' 'e'astus' #
env='test'
resourceGroup='rs_vnet_test_topology_mesh_'$env
sshkey_vm1_name='VM1-spoke1-Key'
sshkey_vm2_name='VM1-spoke2-Key'
sshkey_vm3_name='VM1-spoke3-Key'

az group create --name ${resourceGroup} --location $location --query id --output tsv

existing_files="$v(ls ~/.ssh)"
az sshkey create --name $sshkey_vm1_name --resource-group $resourceGroup 
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file1_name=$(echo "$new_files" | grep -v '\.pub$')

existing_files=$(ls ~/.ssh)
az sshkey create --name $sshkey_vm2_name --resource-group $resourceGroup
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file2_name=$(echo "$new_files" | grep -v '\.pub$')

existing_files=$(ls ~/.ssh)
az sshkey create --name $sshkey_vm3_name --resource-group $resourceGroup
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file3_name=$(echo "$new_files" | grep -v '\.pub$')

echo $key_file1_name  $key_file2_name $key_file3_name 

az deployment group create --resource-group ${resourceGroup} --name create_vnet_mesh   --template-file ./mesh/main.bicep \
 --parameters createGateway=true setupNsgRule=flase sshVm1KeyName=$sshkey_vm1_name sshVm2KeyName=$sshkey_vm2_name \
 sshVm3KeyName=$sshkey_vm3_name  principalId=$(az ad signed-in-user show --query id -o tsv)

vm1PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_vnet_mesh  --query "properties.outputs.vm1PrivateIPAddress.value" -o tsv) 
vm2PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_vnet_mesh  --query "properties.outputs.vm2PrivateIPAddress.value" -o tsv) 
vm3PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_vnet_mesh  --query "properties.outputs.vm3PrivateIPAddress.value" -o tsv) 
bastionHostname=$(az deployment group show -g ${resourceGroup}  -n create_vnet_mesh --query "properties.outputs.bastionHostName.value" -o tsv)
vpnGateWayName=$(az deployment group show -g ${resourceGroup}  -n create_vnet_mesh --query "properties.outputs.vpnGateWayName.value" -o tsv)

echo $vm1PrivateIPAddress $vm2PrivateIPAddress $vm3PrivateIPAddress  $vpnGateWayName

# Download client VPN config file
clientVPNConfigFileURL=$(az network vnet-gateway vpn-client generate --name $vpnGateWayName --resource-group ${resourceGroup})
clientVPNConfigFileURL="${clientVPNConfigFileURL//\"/}"
echo $clientVPNConfigFileURL
curl -o vpnClientConfig.zip $clientVPNConfigFileURL
unzip -o vpnClientConfig.zip 

#VPN to Vnet1

alias sshVm1='ssh -i ~/.ssh/$key_file1_name gary@$vm1PrivateIPAddress'

sshVm1 "ping -c 3 $vm2PrivateIPAddress"
sshVm1 "ping -c 3 $vm3PrivateIPAddress"

scp -i ~/.ssh/$key_file1_name ~/.ssh/$key_file2_name gary@$vm1PrivateIPAddress:/home/gary/
sshVm1  sudo chown gary ${key_file2_name} 
sshVm1 chmod 500 ${key_file2_name}

sshVm1    
    ssh -i $(ls | grep '_') gary@10.3.1.4

ssh -i ~/.ssh/$key_file2_name gary@$vm2PrivateIPAddress
#*************************Clean up********************************************************************************************************************************************

#Clean up
az group delete --name ${resourceGroup} --yes --no-wait

rm  ~/.ssh/*

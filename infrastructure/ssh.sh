# Example: https://github.com/johankardell/azurebastiondemo

vmid=$(az vm show -n ubuntu -g aca-network-demo --query id -o tsv)

az network bastion ssh --name "bastion" --resource-group "aca-network-demo" --target-resource-id $vmid --auth-type ssh-key --username azureuser --ssh-key ~/.ssh/id_rsa
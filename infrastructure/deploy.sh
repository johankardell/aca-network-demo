sshKey=`cat ~/.ssh/id_rsa.pub`
az deployment sub create --location westeurope --template-file main.bicep --parameters publicKey="$sshKey"

echo "Remember to approve PE connections in PLS"
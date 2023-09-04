sshKey=`cat ~/.ssh/id_rsa.pub`
az deployment sub create --location francecentral --template-file main.bicep --parameters publicKey="$sshKey" -n france

echo "Remember to approve PE connections in PLS"
sshKey=$(<~/.ssh/id_rsa.pub)
az deployment sub create --location westeurope --template-file main.bicep --parameters publicKey="$sshKey"
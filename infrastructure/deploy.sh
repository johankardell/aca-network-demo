sshKey=`cat ~/.ssh/id_rsa.pub`
myIp=`curl -s ipinfo.io/ip`

az deployment sub create --location francecentral --template-file main.bicep -n france --parameters publicKey="$sshKey" myIp="$myIp" 

echo "Remember to approve PE connections in PLS"
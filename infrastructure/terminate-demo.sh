# az group delete -n aca-network-demo-service2 -y --no-wait
# az group delete -n aca-network-demo-service1 -y --no-wait
# az group delete -n aca-network-demo -y --no-wait

az deployment sub delete -n service1 -y
az deployment sub delete -n service2 -y
az deployment sub delete -n infrastructure -y


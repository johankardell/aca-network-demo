# az group delete -n aca-network-demo-service2 -y --no-wait
# az group delete -n aca-network-demo-service1 -y --no-wait
# az group delete -n aca-network-demo -y --no-wait

az deployment sub delete -n service1
az deployment sub delete -n service2
az deployment sub delete -n infrastructure


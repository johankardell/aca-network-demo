curl -H Host:demoapp2.happypebble-3f479f51.westeurope.azurecontainerapps.io http://10.0.0.5:80 -v

curl --resolve demoapp1--c7oyd15.gentlerock-74ef499f.westeurope.azurecontainerapps.io:443:20.23.77.176 https://demoapp1--c7oyd15.gentlerock-74ef499f.westeurope.azurecontainerapps.io


#From VM in same subnet as ILB: (172. ip is ILB)
curl --resolve demoapp1--c7oyd15.gentlerock-74ef499f.westeurope.azurecontainerapps.io:80:172.16.2.240 http://demoapp1--c7oyd15.gentlerock-74ef499f.westeurope.azurecontainerapps.io

#Fom VM in hub subnet, where PE for PLS is deployed
# Does not work: 
curl -H "Host:demoapp1--c7oyd15.gentlerock-74ef499f.westeurope.azurecontainerapps.io" https://10.0.0.5
# Works
curl --resolve demoapp1--c7oyd15.gentlerock-74ef499f.westeurope.azurecontainerapps.io:443:10.0.0.5 https://demoapp1--c7oyd15.gentlerock-74ef499f.westeurope.azurecontainerapps.io

curl --resolve nginx-helloworld.whiteglacier-9d6c7978.francecentral.azurecontainerapps.io:443:10.0.0.5 https://nginx-helloworld.whiteglacier-9d6c7978.francecentral.azurecontainerapps.io
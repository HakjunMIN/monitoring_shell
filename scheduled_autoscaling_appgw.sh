#!/bin/bash

resourceGroupName=$1
appGwName=$2
percentIncrease=$3

appGw=$(az network application-gateway show --name $appGwName --resource-group $resourceGroupName)

currentMinCapacity=$(echo "$appGw" | jq ".autoscaleConfiguration.minCapacity")
if [ $currentMinCapacity -eq 0 ]; then
    currentMinCapacity=1
fi    

minCapacity=$((currentMinCapacity * (1 + ($percentIncrease / 100))))

az network application-gateway update --name $appGwName --resource-group $resourceGroupName --min-capacity $minCapacity
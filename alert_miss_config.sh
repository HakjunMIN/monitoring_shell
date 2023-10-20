#!/bin/bash

if [ -z "$1" ]; then
    echo "Execute it with parameters like ./alert_miss_conig.sh <minimum_route_table> \"<resource_group> <resource_group\""
    exit 1
fi

minimum_route_table=$1
shift 1
resource_groups=("$@")

nic_list=()
echo $resource_groups

for resource_group in $resource_groups
do 
    nics=$(az network nic list --resource-group $resource_group --query "[?virtualMachine!=null].id" -o tsv)

    for nic in $nics
    do
        nic_name=$(basename $nic)
        route_table=$(az network nic show-effective-route-table --ids $nic --query "value[].addressPrefix" -o tsv )
        route_count=$(echo "$route_table" | wc -l)
        echo "$nic_name has $route_count route rules"
        if [ $route_count -lt $((minimum_route_table)) ]
        then            
            nic_list+=("$nic_name")
        fi
    done
done

nic_string=$(IFS=,; echo "${nic_list[*]}")
echo "$nic_string"
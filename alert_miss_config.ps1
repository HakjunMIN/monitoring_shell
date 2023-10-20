# Check if parameters are provided

if ($args.Length -eq 0) {
    Write-Host "Execute it with parameters like .\alert_miss_conig.ps1 <minimum_route_table> <resource_group1> <resource_group2> .."
    exit
}

Connect-AzAccount

$minimum_route_table = $args[0]
$resource_groups = $args[1..($args.Length-1)]

$nic_list = @()

foreach ($resource_group in $resource_groups) {
    $nics = az network nic list --resource-group $resource_group --query "[?virtualMachine!=null].id" -o tsv 

    foreach ($nic in $nics) {
        $nic_name = Split-Path $nic -Leaf
        $route_table = az network nic show-effective-route-table --ids $nic --query "value[].addressPrefix" -o tsv 
        $route_count = ($route_table -split "`n").Count
        Write-Host "$nic_name has $route_count route rules"
        if ($route_count -lt [int]$minimum_route_table) {
            $nic_list += $nic_name
        }
    }
}

$nic_string = [string]::Join(",", $nic_list)
Write-Host $nic_string

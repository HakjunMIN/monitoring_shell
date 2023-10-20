param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppGwName,

    [Parameter(Mandatory=$true)]
    [int]$PercentIncrease
)

try {
    $AzureContext = (Connect-AzAccount -Identity).context
}
catch{
    Write-Output "There is no system-assigned user identity. Aborting."; 
    exit
}

$appGw = Get-AzApplicationGateway -Name $AppGwName -ResourceGroupName $ResourceGroupName

$autoscaleConfiguration = Get-AzApplicationGatewayAutoscaleConfiguration -ApplicationGateway $appGw
$currentMinCapacity = $autoscaleConfiguration.MinCapacity

if ($currentMinCapacity -eq 0) {
    $currentMinCapacity = 1
}

$minCapacity = [int]($currentMinCapacity * (1 + ($PercentIncrease / 100)))

$appGw = Set-AzApplicationGatewayAutoscaleConfiguration -ApplicationGateway $appGw -MinCapacity $minCapacity

Set-AzApplicationGateway -ApplicationGateway $appGw
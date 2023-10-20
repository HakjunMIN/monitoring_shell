# Shells for Monitoring 

2가지 특수한 상황에서 활용할 수 있는 Powershell과 Bash shell임.

1. 특정 리소스 그룹 내 전체 VM에 대해 Route Table의 적정 갯수가 유지되는지는 체크하는 스크립트

    * BGP전파 오류를 엔드포인트 (VM의 NIC)단에서 검출하는데 도움.

2. 특정 이벤트에 대응하기 위한 Application Gateway의 스케일링 아웃.

> [!Note]
> Azure Automation을 활용할 경우 Powershell을 활용하고 Azure Batch나 별도의 linux 머신에서 구동 시 Bash shell 활용

## Routes Table Monitoring

* 사용법

리소스 그룹은 여러개 넣을 수 있으며 리소스 그룹 내 전체 NIC를 검출. (단 VM Attached NIC만 검출)

```bash
    alert_miss_config.sh <Route Table 목표갯수> <리소스그룹1> <리소스그룹2> <리소스그룹3> ....
```

예제: 아래는 리소스그룹 rg1, rg2의 Nic중 VM과 Attache되어 있으면서 30개 이하의 Route table을 가지고 있는 Nic들을 검출

```bash  
    ./alert_miss_config.sh 30 rg1 rg2   

    winproxy811 has 22 route rules   
    agentvm259 has 20 route rules
    winproxy811,agentvm259    
```
> [!Note]
> 위 검출된 내용은 Azure Communication Service나 기존 사용중인 Communication Tools(예: 팀즈), 모니터링 시스템 등으로 연결할 수 있음.

## Application Gateway Pre Scaling out 

* 사용법

리소스 그룹은 여러개 넣을 수 있으며 리소스 그룹 내 전체 NIC를 검출. (단 VM Attached NIC만 검출)

```bash
    scheduled_autoscaling_appgw.sh <리소스그룹> <AppGW> <증가퍼센트>  
```

> [!Important]
> 단, 현재 인스턴스가 0일 경우 1로 가정하여 증가 퍼센트를 적용. 소숫점은 절사

예제: 아래는 ingress-appgateway를 현재 대비 50% 인스턴스를 늘림, 아래 `minCapacity`가 변경되어 출력.

```bash  
    ./scheduled_autoscaling_appgw.sh MC_rg_spr-cluster_koreacentral ingress-appgateway 50 
    
    {
        "autoscaleConfiguration": {
            "maxCapacity": 10,
            "minCapacity": 3
        },
        "backendAddressPools": [
            {
            "backendAddresses": [],
            "etag": "W/\"279e61e2-6a1e-4eae-a6fe-733ef52cc203\"",
    ...        

```

## Azure Automation 적용방법

1. Azure 내 검색창에서 Automation Accounts생성

2. 생성된 Account내 왼쪽 메뉴에서 Process Automation > Runbooks선택 > `Create a runbook`

    * Name, Runbook type은 `Powershell`, Runbook version은 `7.2(preview)`

3. Edit Powershell Runbook에서 Powershell 코드 작성 (예: scheduled_autoscaling_appgw.ps1)

```ps1
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
```

4. Test 수행

    * 테스트가 수행되면 Parameter를 입력한 후 수행결과 확인. 이후 정상이면 기존화면으로 돌아와서 `Publish` 수행

5. Runbook내 Resources > Schedules > `Add a schedule`실행

    * Link a schedule to your runbook 클릭
    * Add a schedule로 스케일아웃 수행될 시간 선택, Recurrence여부 선택 (예: 매주 월요일 아침 8시)

6. Parameters and run setting 선택

    * Scale out할 대상 AppGW정보 입력 
        * `RESOURCEGROUPNAME`, `APPGWNAME`, `PERCENTAGEINCREASE` 


Param(
	[Parameter()]
    [string]$StagingCloudURL,

	[Parameter()]
    [string]$StagingActivateJsonURL,

    [Parameter()]
    [bool]$Extension,
	
	[Parameter(Mandatory = $true)]
    [string]$InstallType,

	[Parameter(Mandatory = $true)]
    [string]$Key,

    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $true)]
    [string]$Email,

    [Parameter(Mandatory = $true)]
    [string]$Company
)

function SetFirewallRules 
{
    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-management-port -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8250'

    if ($status -ne $null) {
        (Get-Date).ToString() + ' nc-management-port inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-management-port -Direction Outbound -Action Allow -Protocol TCP -LocalPort 8250'

    if ($status -ne $null) {
        (Get-Date).ToString() + ' nc-management-port outbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-server-port -Direction Inbound -Action Allow -Protocol TCP -LocalPort 9800'

    if ($status -ne $null) {
        (Get-Date).ToString() + ' nc-server-port inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-server-port -Direction Outbound -Action Allow -Protocol TCP -LocalPort 9800'

    if ($status -ne $null) {
        (Get-Date).ToString() + ' nc-server-port outbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-cluster-management-port -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8300-8399'

    if ($status -ne $null) {
        (Get-Date).ToString() + ' nc-cluster-management-port inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-cluster-management-port -Direction Outbound -Action Allow -Protocol TCP -LocalPort 8300-8399'

    if ($status -ne $null) {
        (Get-Date).ToString() + ' nc-cluster-management-port outbound rule defined successfully' >> C:\NCache-Init-Status.txt 
    }
}

function RestartNCacheService
{
    $ncserviceState = Get-Service -Name NCacheSvc
    Invoke-Expression -Command 'Restart-Service NCacheSvc' | Out-Null
    $ncserviceState = Get-Service -Name NCacheSvc
    $ncserviceState.Status >> C:\NCache-Init-Status.txt
}

function RegisterNCache
{
    if ($Key.Equals("NotSpecified")) {
        $Key = ""
    }

    if ($Key -ne "") {
        
        if ($Extension) {
            $NActivateExpression = '& "C:\Program Files\NCache\bin\NActivate\NActivate.exe" -k ' + $Key + ' -f "' + $FirstName + '" -l "' + $LastName + '" -e "' + $Email + '" -comp "' + $Company + '" -ext'
        }
        else {
            $NActivateExpression = '& "C:\Program Files\NCache\bin\NActivate\NActivate.exe" -RegisterNCacheForEvaluation -k ' + $Key + ' -f "' + $FirstName + '" -l "' + $LastName + '" -e "' + $Email + '" -comp "' + $Company + '" -EvaluationKey'
        }

        try {
            Invoke-Expression -Command $NActivateExpression >> C:\NCache-Init-Status.txt
        }
        catch {
            $_.Exception.Message >> C:\NCache-Init-Status.txt
        }
    }
}

function SetRegistryValues
{
	try {
		Set-ItemProperty -Path HKLM:\\SOFTWARE\\Alachisoft\\NCache -Name InstallType -Value $InstallType
	}
	catch {
		$_.Exception.Message >> C:\NCache-Init-Status.txt
	}
	
	try {
		if ($StagingCloudURL -ne "") {
			Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Alachisoft\\NCache\\UserInfo' -Name cloud-url -Value $StagingCloudURL
		}
	}
	catch {
		$_.Exception.Message >> C:\NCache-Init-Status.txt
	}	
}

function PlaceActivateJson
{
	try {
		if ($StagingActivateJsonURL -ne "") {
			Invoke-WebRequest -Uri $StagingActivateJsonURL -OutFile "C:/Program Files/NCache/bin/NActivate/activate.json"
		}
	}
	catch {
		$_.Exception.Message >> C:\NCache-Init-Status.txt
	}
}

if (!(Test-Path C:\NCache-Init-Status.txt)) {
    SetFirewallRules
    RegisterNCache
	SetRegistryValues
	PlaceActivateJson
    RestartNCacheService
}

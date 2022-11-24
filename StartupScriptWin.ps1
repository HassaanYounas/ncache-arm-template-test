Param(
	[Parameter()]
    [string]$StagingCloudURL,

	[Parameter()]
    [string]$StagingActivateJsonURL,
		
	[Parameter()]
    [string]$StubDLLUpdatedURL,

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

        $EVAL_SUCCESS = "NCache has been successfully registered for FREE evaluation on server"
        $EXT_SUCCESS = "NCache evaluation period has been extended"
        $TOTAL_RETRIES = 10
        $RETRY_DELAY = 30
        $retries = 0
    
        while ($retries -lt $TOTAL_RETRIES) {
            
            if ($Extension) {
                $NActivateExpression = '& "Register-NCache" -Key ' + $Key + ' -FirstName "' + $FirstName + '" -LastName "' + $LastName + '" -Email "' + $Email + '" -Company "' + $Company + '" -KeyType Extension'
            } else {
                $NActivateExpression = '& "Register-NCacheEvaluation" -Key ' + $Key + ' -FirstName "' + $FirstName + '" -LastName "' + $LastName + '" -Email "' + $Email + '" -Company "' + $Company + '"'
            }
    
            try {
                $response = Invoke-Expression -Command $NActivateExpression 
                $response >> C:\NCache-Init-Status.txt

				if (-not [string]::IsNullOrEmpty($error)) {
					$error >> C:\NCache-Init-Status.txt
					Start-Sleep -seconds $RETRY_DELAY
					$retries++;
					$error.clear();
				}
				else
				{
					break;
				}
			}
            catch {
                $_.Exception.Message >> C:\NCache-Init-Status.txt
				Start-Sleep -seconds $RETRY_DELAY
				$retries++;
            }	
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
}

function PlaceUpdatedStubDLL
{
	try {
		if ($StubDLLUpdatedURL -ne "") {
			Invoke-WebRequest -Uri $StubDLLUpdatedURL -OutFile "C:\Program Files\NCache\bin\NActivate\Alachisoft.NCache.StubDll.dll"
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
    
    $STARTUP_DELAY = 30
    Start-Sleep -seconds $STARTUP_DELAY
    
    SetRegistryValues
    PlaceActivateJson
	PlaceUpdatedStubDLL
    RegisterNCache
    RestartNCacheService
}

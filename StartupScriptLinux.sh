Param(
	[Parameter()]
    [string]$StagingCloudURL,

	[Parameter()]
    [string]$StagingActivateJsonURL,
		
	[Parameter()]
    [string]$StubDLLUpdatedURL,

    [Parameter()]
    [string]$Extension,
	
	[Parameter()]
    [string]$EnableHttps,
	
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

$logFile = "/tmp/NCache-Init-Status.txt"

function RestartNCacheService {
    try {
        systemctl stop ncached;
		"NCache Service Stopped Successfully." >> $logFile

		systemctl start ncached;
		"NCache Service Started Successfully." >> $logFile    
    }
    catch {
        "Exception in restarting" >> $logFile;
        $_.Exception.Message >> $logFile
    }
}

function CreateSSLCertificate
{
	if ($EnableHttps.Equals("True")) {
		
	}
}

function RegisterNCache {

	if ($Key.Equals("NotSpecified")) {
        $Key = ""
    }
	
	if ($Key -ne "") {

        $EVAL_SUCCESS = "NCache has been successfully registered for FREE evaluation on server"
        $EXT_SUCCESS = "NCache evaluation period has been extended"
        $TOTAL_RETRIES = 10
        $RETRY_DELAY = 30
        $retries = 0
    
		Import-Module '/opt/ncache/bin/tools/ncacheps'
		
        while ($retries -lt $TOTAL_RETRIES) {
            
            if ($Extension.Equals("True")) {
                $NActivateExpression = '& "Register-NCache" -Key ' + $Key + ' -FirstName "' + $FirstName + '" -LastName "' + $LastName + '" -Email "' + $Email + '" -Company "' + $Company + '" -KeyType Extension'
            } else {
                $NActivateExpression = '& "Register-NCacheEvaluation" -Key ' + $Key + ' -FirstName "' + $FirstName + '" -LastName "' + $LastName + '" -Email "' + $Email + '" -Company "' + $Company + '"'
            }
    
            try {
                $response = Invoke-Expression -Command $NActivateExpression 
                $response >> $logFile

				if (-not [string]::IsNullOrEmpty($error)) {
					$error >> $logFile
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
                $_.Exception.Message >> $logFile
				Start-Sleep -seconds $RETRY_DELAY
				$retries++;
            }	
        }       
    }
}

function PlaceUpdatedStubDLL
{
	try {
		if ($StubDLLUpdatedURL -ne "") {
			Invoke-WebRequest -Uri $StubDLLUpdatedURL -OutFile "/opt/ncache/lib/Alachisoft.NCache.StubDll.dll"
		}
	}
	catch {
		$_.Exception.Message >> $logFile
	}
}

function PlaceActivateJson
{
	try {
		if ($StagingActivateJsonURL -ne "") {
					
			Invoke-WebRequest -Uri $StagingActivateJsonURL -OutFile "/opt/ncache/lib/activate.json"
		}
	}
	catch {
		$_.Exception.Message >> $logFile
	}
}

if (!(Test-Path $logFile)) {
        
    PlaceActivateJson
	PlaceUpdatedStubDLL
	CreateSSLCertificate
    RegisterNCache
    RestartNCacheService
}
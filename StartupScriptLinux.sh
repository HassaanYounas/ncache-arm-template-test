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
		sudo kill $(ps aux | grep 'Alachisoft.NCache.WebManager.dll' | awk '{print $2}')
		"NCache Web Manager Stopped Successfully." >> $logFile
		
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
	
		sudo openssl req -x509 -sha256 -days 3650 -nodes -newkey rsa:2048 -keyout ~/MyCertificate.key -out ~/MyCertificate.crt -subj "/CN=localhost" -passin pass:password1234

		sudo chmod +r ~/MyCertificate.crt
		sudo chmod +r ~/MyCertificate.key

		sudo mkdir /home/ncache

		sudo cp ~/MyCertificate.crt /home/ncache
		sudo cp ~/MyCertificate.key /home/ncache

		sudo chown ncache /home/ncache
		
		$kestrelSettings = '{"Kestrel":{"EndPoints":{"Http":{"Url":"http://0.0.0.0:8251"},"HttpsInlineCertStore":{"Url":"https://0.0.0.0:8252","Certificate":{"Path":"/home/ncache/MyCertificate.crt","KeyPath":"/home/ncache/MyCertificate.key","AllowInvalid":"true"}}}}}'

		$kestrelSettings | Out-File "/opt/ncache/bin/tools/web/config.json"
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
	RestartNCacheService
    RegisterNCache
    RestartNCacheService
}
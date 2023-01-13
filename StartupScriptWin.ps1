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

function CreateSSLCertificate
{
	if ($EnableHttps.Equals("True")) {
		$cert = New-SelfSignedCertificate -KeyAlgorithm RSA -CertStoreLocation "Cert:\LocalMachine\My"  -Subject "localhost" -FriendlyName "MyCertificate" -TextExtension @("2.5.29.17={critical}{text}DNS=localhost")
		
		$pwd = ConvertTo-SecureString -String 'password1234' -Force -AsPlainText;
		$path = 'Cert:\LocalMachine\My\' + $cert.thumbprint
		
		Export-PfxCertificate -cert $path -FilePath 'C:\\MyCertificate.pfx' -Password $pwd
		
		whoami >> C:\NCache-Init-Status.txt
		
		Import-PfxCertificate -FilePath 'C:\\MyCertificate.pfx' -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $pwd
		
		$kestrelSettings = '{"Kestrel":{"EndPoints":{"Http":{"Url":"http://0.0.0.0:8251"},"HttpsDefaultCert":{"Url":"https://0.0.0.0:8252"}},"Certificates":{"Default":{"Path":"C:\\MyCertificate.pfx","Password":"password1234"}}}}'

		$kestrelSettings | Out-File "C:\Program Files\NCache\bin\tools\web\config.json"
	}
}

function RestartNCacheService
{
	taskkill /IM Alachisoft.NCache.Service.exe /F;
	taskkill /IM Alachisoft.NCache.WebManager.exe /F;
	Start-Sleep -seconds 3
	
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
            
            if ($Extension.Equals("True")) {
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
	CreateSSLCertificate
    RegisterNCache
    RestartNCacheService
}

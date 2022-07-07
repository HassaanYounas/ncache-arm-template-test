Param(
    [Parameter(Mandatory = $true)]
    [string]$serverIP,
	[Parameter(Mandatory = $true)]
    [Int32]$edition
)
$logFile = "C:\Windows\Temp\NCache-Init-Status.txt"

function SetFirewallRules {
    
	"Setting firewall rules" >> $logFile
	
    New-NetFirewallRule -DisplayName NCache -Direction Inbound -Action Allow -Protocol TCP -LocalPort 9800, 8250-8260, 7800-7900, 8300-8400, 9900, 10000-11000;
	
	New-NetFirewallRule -DisplayName NCache -Direction Outbound -Action Allow -Protocol TCP -LocalPort
	7800-7900, 10000-11000;    
}

function RestartNCacheService {
    try {
        Stop-Service NCacheSvc
        $ncserviceState = (Get-Service -Name NCacheSvc).Status
        if ($ncserviceState -eq 'Stopped') {
            "NCache Service Stopped Successfully." >> $logFile
            cd $Env:NCHOME;
            cscript.exe $Env:NCHOME\bin\updateIPs.vbs >> $logFile;

            "IPs Updated" >> $logFile

            Start-Service NCacheSvc
            $ncserviceState = (Get-Service -Name NCacheSvc).Status
            if ($ncserviceState -eq 'Running') {
                "NCache Service Started Successfully." >> $logFile
                cat 'C:\Program Files\NCache\bin\service\Alachisoft.NCache.Service.exe.config' | Select-String 'BindToClusterIP' >> $logFile
				cat 'C:\Program Files\NCache\bin\service\Alachisoft.NCache.Service.dll.config' | Select-String 'BindToClusterIP' >> $logFile
                return 0;
            }
            "NCache service not running">> $logFile;
            return 1;
        } 
    }
    catch {
        "Exception in restarting" >> $logFile;
        $_.Exception.Message >> $logFile
        return 1;
    }
}

function HandleClusterAndCache {
    "Handling Cluster Creation">>$logFile

    Import-Module 'C:\Program Files\NCache\bin\tools\ncacheps'
    
    $defaultTopology = "PartitionedOfReplica"
		
	if ($serverIP -eq " ") {	
		if( $edition -eq 66){	
			$Expression = "New-Cache -Name demoCache -Server " + $currentIP + " -Topology " + $defaultTopology + " -Size 1024 -ReplicationStrategy Async -EvictionPolicy LRU -NoLogo";
		}
		else{
			$Expression="echo 'Its not 5.1' >> $logFile";
		}
	}
	else {
		Start-Sleep -s 10
		$Expression = "Add-Node -CacheName demoCache -ExistingServer " + $serverIP + " -NewServer " + $currentIP + " -NoLogo";
	}
	

	try {
		Invoke-Expression -Command $Expression -OutVariable output -ErrorVariable errors
	
		$output >> $logFile

		$errors >> $logFile
	}
	catch {
		"Error in creating cluster: ">> $logFile
		$_ >> $logFile
	}
	Start-Sleep -s 2

	$Expression = "Start-Cache -Name demoCache -Server " + $currentIP + " -NoLogo"

	try {
		Invoke-Expression -Command $Expression -OutVariable output -ErrorVariable errors

		$output >> $logFile

		$errors >> $logFile
	}
	catch {
		"Error in starting cluster:" >> $logFile
		$_ >> $logFile
	}
    
}

function GetNCacheActivation {
    Import-Module 'C:\Program Files\NCache\bin\tools\ncacheps'   
    try {
		
		Invoke-WebRequest -Uri "https://armtestahmed.blob.core.windows.net/blobtest/GenerateStub.exe" -OutFile C:/GenerateStub.exe;
		C:/GenerateStub.exe -e $edition;
            
        if ($ProcessError.Count -gt 0) {
            "Got an error in Evaluation" >> $logFile;
            $ProcessError >> $logFile;
            "Terminating Process.." >> $logFile;
            return 1;
        }
        "Evaluation done" >> $logFile;
        Get-NCacheVersion >> $logFile;
        return 0;
    }
    catch {
        "Exception in register" >> $logFile
        $_.Exception.Message >> $logFile
        "Terminating Process.." >> $logFile
        return 1;
    }
}

function DeleteFiles{
	rm C:\ClusterFormation.ps1;
	rm C:\GenerateStub.exe;
}

function GetCurrentIP{
	$exeConfigPath= 'C:\Program Files\NCache\bin\service\Alachisoft.NCache.Service.exe.config';
	$dllConfigPath= 'C:\Program Files\NCache\bin\service\Alachisoft.NCache.Service.dll.config';
	if(Test-Path $exeConfigPath)
	{
		$configPath=$exeConfigPath;
	}
	else
	{
		$configPath=$dllConfigPath;
	}
	
	$config=Select-Xml -Path $configPath -XPath /configuration/appSettings | Select-Object -ExpandProperty Node
	  foreach ($node in $config.add)
		{
			if($node.Key -eq "NCacheServer.BindToClusterIP" -or $node.Key -eq "NCacheServer.BindToIP")
				{
					return $node.value;
				}
		}
}

if (!(Test-Path $logFile)) {
		
    $status = RestartNCacheService;
    "Status of Restart: " + $status >> $logFile;
    if ($status -eq 1) {
        return 1;
    }
    $status = GetNCacheActivation;
    "Status of Activation: " + $status >> $logFile;
    if ($status -eq 1) {
        return 1;
    }
	
	$currentIP= GetCurrentIP;	
	"Current IP: "+$currentIP >> $logFile;
	
	SetFirewallRules;
	
	Start-Sleep -s 60;
    HandleClusterAndCache
	DeleteFiles
}

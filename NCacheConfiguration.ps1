Param(
    [Parameter(Mandatory = $true)]
    [string]$clusterName,

    [Parameter(Mandatory = $true)]
    [string]$topology,

    [Parameter]
    [Int32]$port,

    [Parameter(Mandatory = $true)]
    [string]$currentIP,

    [Parameter(Mandatory = $true)]
    [string]$serverIP,

    [Parameter(Mandatory = $true)]
    [string]$replicationStrategy,

    [Parameter(Mandatory = $true)]
    [string]$evictionPolicy,

    [Parameter(Mandatory = $true)]
    [Int32]$maxSize,

    [Parameter(Mandatory = $true)]
    [Int32]$evictionPercentage,

    [Parameter(Mandatory = $true)]
    [string]$firstName,

    [Parameter(Mandatory = $true)]
    [string]$lastName,

    [Parameter(Mandatory = $true)]
    [string]$emailAddress,

    [Parameter(Mandatory = $true)]
    [string]$company,

    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$licenseKey,

    [Parameter(Mandatory = $true)]
    [Int32]$vmCount,

    [Parameter(Mandatory = $true)]
    [string]$environment,

    [Parameter(Mandatory = $true)]
    [string]$phone,

    [Parameter(Mandatory = $true)]
    [string]$ncacheVersion,

    [Parameter]
    [string]$sku,

    [Parameter]
    [string]$defaultPriority
)

function SetFirewallRules 
{
    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-management-port -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8250'

    if ($status -ne $null) {
        (Get-Date).ToString() + '    nc-management-port inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-management-port -Direction Outbound -Action Allow -Protocol TCP -LocalPort 8250'

    if ($status -ne $null) {
        (Get-Date).ToString() + '    nc-management-port outbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-server-port -Direction Inbound -Action Allow -Protocol TCP -LocalPort 9800'

    if ($status -ne $null) {
        (Get-Date).ToString() + '    nc-server-port inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-server-port -Direction Outbound -Action Allow -Protocol TCP -LocalPort 9800'

    if ($status -ne $null) {
        (Get-Date).ToString() + '    nc-server-port outbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-cluster-management-port -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8300-8399'

    if ($status -ne $null) {
        (Get-Date).ToString() + '    nc-cluster-management-port inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }

    $status = Invoke-Expression -Command 'New-NetFirewallRule -DisplayName nc-cluster-management-port -Direction Outbound -Action Allow -Protocol TCP -LocalPort 8300-8399'

    if ($status -ne $null) {
        (Get-Date).ToString() + '    nc-cluster-management-port outbound rule defined successfully' >> C:\NCache-Init-Status.txt    
    }
}

function InstallNCache 
{
    $setups = @{}

    $setups.Add("4.6-SP3", "https://ncentazuresa.blob.core.windows.net/ent-cont/NCache4.6_Enterprise_DotNet_x64.msi")
    $setups.Add("4.8", "https://ncentazuresa.blob.core.windows.net/ent-cont/ncache.ent48.x64.msi")
    $setups.Add("4.9", "https://ncentazuresa.blob.core.windows.net/ent-cont/ncache.ent.x64.msi")
    
    if ($ncacheVersion.Equals("4.9")) {

        (Get-Date).ToString() + '    Version 4.9 selected' >> C:\NCache-Init-Status.txt 
        (new-object System.Net.WebClient).DownloadFile("https://ncentazuresa.blob.core.windows.net/ent-cont/vcredist_x64.exe", "vcredist_x64.exe")
        
        (Get-Date).ToString() + '    vcredist_x64.exe downloaded' >> C:\NCache-Init-Status.txt
        $installExpression = 'vcredist_x64.exe /q'

        cmd /C $installExpression
        (Get-Date).ToString() + '    vcredist_x64.exe installed' >> C:\NCache-Init-Status.txt

        (new-object System.Net.WebClient).DownloadFile("https://ncentazuresa.blob.core.windows.net/ent-cont/vcredist_x86.exe", "vcredist_x86.exe")

        (Get-Date).ToString() + '    vcredist_x86.exe downloaded' >> C:\NCache-Init-Status.txt
        $installExpression = 'vcredist_x86.exe /q'
 
        cmd /C $installExpression

        $installExpression = 'msiexec /I ' + $setups.Get_Item($ncacheVersion) + ' KEY=YLPT3IWJYWIZNOJKE emailaddress=' + $emailAddress + ' USERFIRSTNAME="' + $firstName + '" USERLASTNAME="' + $lastName + '" COMPANYNAME="' + $company + '" /l setupLogs.txt /qn'   
        (Get-Date).ToString() + '    NCache setup downloaded and installed' >> C:\NCache-Init-Status.txt
    }

    if ($ncacheVersion.Equals("4.8")) {

        (new-object System.Net.WebClient).DownloadFile("https://ncentazuresa.blob.core.windows.net/ent-cont/vcredist_x64.exe", "vcredist_x64.exe")
        
        (Get-Date).ToString() + '    vcredist_x64.exe downloaded' >> C:\NCache-Init-Status.txt
        $installExpression = 'vcredist_x64.exe /q'

        cmd /C $installExpression
        
        (new-object System.Net.WebClient).DownloadFile("https://ncentazuresa.blob.core.windows.net/ent-cont/vcredist_x86.exe", "vcredist_x86.exe")

        $installExpression = 'vcredist_x86.exe /q'
 
        cmd /C $installExpression

        $installExpression = 'msiexec /I ' + $setups.Get_Item($ncacheVersion) + ' KEY=EYP3TIWJYNWIZOYEE emailaddress=' + $emailAddress + ' USERFIRSTNAME="' + $firstName + '" USERLASTNAME="' + $lastName + '" COMPANYNAME="' + $company + '" /l setupLogs.txt /qn'   

    }

    if ($ncacheVersion.Equals("4.6-SP3")) {
        $installExpression = 'msiexec /I ' + $setups.Get_Item($ncacheVersion) + ' emailaddress=' + $emailAddress + ' USERFIRSTNAME="' + $firstName + '" USERLASTNAME="' + $lastName + '" COMPANYNAME="' + $company + '" /l setupLogs.txt /qn'
    }

    cmd /C $installExpression

    Start-Sleep -s 5

    (Get-Date).ToString() + '    NCache installed successfully: ' + $env:NCHOME >> C:\NCache-Init-Status.txt

    $InstallDir = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Alachisoft\NCache\ | Select-Object -ExpandProperty InstallDir

}

function RestartNCacheService
{
    $ncserviceState = Get-Service -Name NCacheSvc
    Invoke-Expression -Command 'Restart-Service NCacheSvc' | Out-Null
    $ncserviceState = Get-Service -Name NCacheSvc
    $ncserviceState.Status >> C:\NCache-Init-Status.txt
}

function HandleClusterAndCache
{
  # NCache Version 4.6 SP3
  if ($ncacheVersion.Equals("4.6-SP3")) 
  {
        if ($serverIP -eq $currentIP) {
            if ($evictionPolicy.Equals("none")) {
                $Expression = "& 'C:\Program Files\NCache\bin\tools\" + "createCache.exe' " + $clusterName + " /s " + $currentIP + " /c " + $port + " /t " + $topology + " /S " + $maxSize + " /R " + $replicationStrategy + " /G"
            }
            else {
                $Expression = "& 'C:\Program Files\NCache\bin\tools\" + "createCache.exe' " + $clusterName + " /s " + $currentIP + " /c " + $port + " /t " + $topology + " /S " + $maxSize + " /R " + $replicationStrategy + " /y " + $evictionPolicy + " /d " + $defaultPriority + " /o " + $evictionPercentage + " /G"
            }
        }
        else {
            $Expression = "& 'C:\Program Files\NCache\bin\tools\" + "addNode.exe' " + $clusterName + " /x " + $serverIP + " /N " + $currentIP + " /G"
        }

        Invoke-Expression -Command $Expression >> C:\NCache-Init-Status.txt

        $Expression = "& 'C:\Program Files\NCache\bin\tools\" + "getCacheConfiguration.exe' " + $clusterName + " /s " + $currentIP + " /T C:\ /G"
        Invoke-Expression -Command $Expression >> C:\NCache-Init-Status.txt
    
        $configPath = 'C:\' + $clusterName + '.ncconf'
    
        $line = Get-Content $configPath | where-Object {$_ -like '*cluster-port="*"*'}
        $clusterport = [regex]::match($line, '(cluster-port="\d{4,5}")').Groups[1].Value
        $port = [regex]::match($clusterport, '(\d{4,5})').Groups[1].Value
        $port
        $portInInt = [convert]::ToInt32($port)
    
        $portrange = [regex]::match($line, '(port-range="\d{1,3}")').Groups[1].Value
        $range = [regex]::match($portrange, '(\d{1,3})').Groups[1].Value
        $range
    
        $rangeInInt = [convert]::ToInt32($range)
        for ($i = 0; $i -lt $rangeInInt; $i++) {
            $currentPort = $portInInt + $i

            $clusterRule = 'New-NetFirewallRule -DisplayName nc-cluster-port-' + $i + ' -Direction Inbound -Action Allow -Protocol TCP -LocalPort ' + ($currentPort).ToString()
    
            $status = Invoke-Expression -Command $clusterRule
    
            if ($status -ne $null) {
                (Get-Date).ToString() + '    nc-cluster-port-' + $i + 'inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
            }
        
            $clusterRule = 'New-NetFirewallRule -DisplayName nc-cluster-port-' + $i + ' -Direction Outbound -Action Allow -Protocol TCP -LocalPort ' + ($currentPort).ToString()
        
            $status = Invoke-Expression -Command $clusterRule
        
            if ($status -ne $null) {
                (Get-Date).ToString() + '    nc-cluster-port-' + $i + ' outbound rule defined successfully' >> C:\NCache-Init-Status.txt    
            }
        }

        Remove-Item -Path $configPath

        if (Test-Path $configPath)
        {
            $configPath + " removed successfully" >> C:\NCache-Init-Status.txt            
        }

        Start-Sleep -s 2

        $Expression = "& 'C:\Program Files\NCache\bin\tools\" + "startCache.exe' " + $clusterName + " /s " + $currentIP  + " /G"

        Invoke-Expression -Command $Expression >> C:\NCache-Init-Status.txt
    }

    # NCache Version 4.8 
    if ($ncacheVersion.Equals("4.8")) {
        # to support parameter differences in powershell and CLI
        if ($topology.Equals("partitioned-replica")) {
            $topology = "partitionedofreplica"
        }
        if ($topology.Equals("mirrored")) {
            $topology = "mirror"
        }

        Import-Module "C:\Program Files\NCache\bin\tools\ncacheps\ncacheps.dll"

        if ($serverIP -eq $currentIP) {
            if ($evictionPolicy.Equals("none")) {
            
                $Expression = "New-Cache -Name " + $clusterName + " -Server " + $currentIP + " -ClusterPort " + $port + " -Topology " + $topology + " -Size " + $maxSize + " -ReplicationStrategy " + $replicationStrategy + " -EvictionPolicy " + $evictionPolicy + " -NoLogo"
            }
            else {
                $Expression = "New-Cache -Name " + $clusterName + " -Server " + $currentIP + " -ClusterPort " + $port + " -Topology " + $topology + " -Size " + $maxSize + " -ReplicationStrategy " + $replicationStrategy + " -EvictionPolicy " + $evictionPolicy + " -DefaultPriority " + $defaultPriority + " -EvictionRatio " + $evictionPercentage + " -NoLogo"
            }
        }
        else {
            $Expression = "Add-Node -CacheName " + $clusterName + " -ExistingServer " + $serverIP + " -NewServer " + $currentIP + " -NoLogo"
        }

        try {
            Invoke-Expression -Command $Expression -OutVariable output -ErrorVariable errors
        
            $ouput >> C:\NCache-Init-Status.txt

            $errors >> C:\NCache-Init-Status.txt
        }
        catch {
            #"Error in creating cluster" >> C:\createCluster.txt
            $_ >> C:\NCache-Init-Status.txt
        }

        $Expression = "Export-CacheConfiguration -Name " + $clusterName + " -Server " + $currentIP + " -Path C:\ -NoLogo"
        Invoke-Expression -Command $Expression >> C:\NCache-Init-Status.txt
    
        $configPath = 'C:\' + $clusterName + '.ncconf'
    
        $line = Get-Content $configPath | where-Object {$_ -like '*cluster-port="*"*'}
        $clusterport = [regex]::match($line, '(cluster-port="\d{4,5}")').Groups[1].Value
        $port = [regex]::match($clusterport, '(\d{4,5})').Groups[1].Value
        $port
        $portInInt = [convert]::ToInt32($port)
    
        $portrange = [regex]::match($line, '(port-range="\d{1,3}")').Groups[1].Value
        $range = [regex]::match($portrange, '(\d{1,3})').Groups[1].Value
        $range
    
        $rangeInInt = [convert]::ToInt32($range)
        for ($i = 0; $i -lt $rangeInInt; $i++) {
            $currentPort = $portInInt + $i

            $clusterRule = 'New-NetFirewallRule -DisplayName nc-cluster-port-' + $i + ' -Direction Inbound -Action Allow -Protocol TCP -LocalPort ' + ($currentPort).ToString()
    
            $status = Invoke-Expression -Command $clusterRule
    
            if ($status -ne $null) {
                (Get-Date).ToString() + '    nc-cluster-port-' + $i + 'inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
            }
        
            $clusterRule = 'New-NetFirewallRule -DisplayName nc-cluster-port-' + $i + ' -Direction Outbound -Action Allow -Protocol TCP -LocalPort ' + ($currentPort).ToString()
        
            $status = Invoke-Expression -Command $clusterRule
        
            if ($status -ne $null) {
                (Get-Date).ToString() + '    nc-cluster-port-' + $i + ' outbound rule defined successfully' >> C:\NCache-Init-Status.txt    
            }
        }

        Remove-Item -Path $configPath
        
        if (Test-Path $configPath)
        {
            $configPath + " removed successfully" >> C:\NCache-Init-Status.txt            
        }

        Start-Sleep -s 2

        $Expression = "Start-Cache -Name " + $clusterName + " -Server " + $currentIP + " -NoLogo"

        try {
            Invoke-Expression -Command $Expression -OutVariable output -ErrorVariable errors

            $output >> C:\NCache-Init-Status.txt

            $errors >> C:\NCache-Init-Status.txt
        }
        catch {
            #"Error in starting cluster" >> C:\startCluster.txt
            $_ >> C:\NCache-Init-Status.txt
        }
    }

    # NCache Version 4.9 
    if ($ncacheVersion.Equals("4.9")) {
        # to support parameter differences in powershell and CLI
        if ($topology.Equals("partitioned-replica")) {
            $topology = "partitionedofreplica"
        }
        if ($topology.Equals("mirrored")) {
            $topology = "mirror"
        }

        Import-Module 'C:\Program Files\NCache\bin\tools\ncacheps\ncacheps.dll'

        if ($serverIP -eq $currentIP) {
            if ($evictionPolicy.Equals("none")) {
            
                $Expression = "New-Cache -Name " + $clusterName + " -Server " + $currentIP + " -ClusterPort " + $port + " -Topology " + $topology + " -Size " + $maxSize + " -ReplicationStrategy " + $replicationStrategy + " -EvictionPolicy " + $evictionPolicy + " -NoLogo"
            }
            else {
                $Expression = "New-Cache -Name " + $clusterName + " -Server " + $currentIP + " -ClusterPort " + $port + " -Topology " + $topology + " -Size " + $maxSize + " -ReplicationStrategy " + $replicationStrategy + " -EvictionPolicy " + $evictionPolicy + " -DefaultPriority " + $defaultPriority + " -EvictionRatio " + $evictionPercentage + " -NoLogo"
            }
        }
        else {
            $Expression = "Add-Node -CacheName " + $clusterName + " -ExistingServer " + $serverIP + " -NewServer " + $currentIP + " -NoLogo"
        }

        try {
            Invoke-Expression -Command $Expression -OutVariable output -ErrorVariable errors
        
            $ouput >> C:\NCache-Init-Status.txt

            $errors >> C:\NCache-Init-Status.txt
        }
        catch {
            #"Error in creating cluster" >> C:\createCluster.txt
            $_ >> C:\NCache-Init-Status.txt
        }

        $Expression = "Export-CacheConfiguration -Name " + $clusterName + " -Server " + $currentIP + " -Path C:\ -NoLogo"
        Invoke-Expression -Command $Expression >> C:\NCache-Init-Status.txt
    
        $configPath = 'C:\' + $clusterName + '.ncconf'
    
        $line = Get-Content $configPath | where-Object {$_ -like '*cluster-port="*"*'}
        $clusterport = [regex]::match($line, '(cluster-port="\d{4,5}")').Groups[1].Value
        $port = [regex]::match($clusterport, '(\d{4,5})').Groups[1].Value
        $port
        $portInInt = [convert]::ToInt32($port)
    
        $portrange = [regex]::match($line, '(port-range="\d{1,3}")').Groups[1].Value
        $range = [regex]::match($portrange, '(\d{1,3})').Groups[1].Value
        $range
    
        $rangeInInt = [convert]::ToInt32($range)
        for ($i = 0; $i -lt $rangeInInt; $i++) {
            $currentPort = $portInInt + $i

            $clusterRule = 'New-NetFirewallRule -DisplayName nc-cluster-port-' + $i + ' -Direction Inbound -Action Allow -Protocol TCP -LocalPort ' + ($currentPort).ToString()
    
            $status = Invoke-Expression -Command $clusterRule

            (Get-Date).ToString() + 'status of nc-cluster-port inbound rule ' + $status  >> C:\NCache-Init-Status.txt 

            if ($status -ne $null) {
                (Get-Date).ToString() + 'New-NetFirewallRule -DisplayName nc-cluster-port-' + $i + ' -Direction Inbound -Action Allow -Protocol TCP -LocalPort ' + ($currentPort).ToString() >> C:\NCache-Init-Status.txt 

                (Get-Date).ToString() + '    nc-cluster-port-' + $i + 'inbound rule defined successfully' >> C:\NCache-Init-Status.txt    
            }
        
            $clusterRule = 'New-NetFirewallRule -DisplayName nc-cluster-port-' + $i + ' -Direction Outbound -Action Allow -Protocol TCP -LocalPort ' + ($currentPort).ToString()
        
            $status = Invoke-Expression -Command $clusterRule

             (Get-Date).ToString() + 'status of nc-cluster-port inbound rule ' + $status  >> C:\NCache-Init-Status.txt 
        
            if ($status -ne $null) {

                (Get-Date).ToString() + 'New-NetFirewallRule -DisplayName nc-cluster-port-' + $i + ' -Direction Outbound -Action Allow -Protocol TCP -LocalPort ' + ($currentPort).ToString() >> C:\NCache-Init-Status.txt    
                (Get-Date).ToString() + '    nc-cluster-port-' + $i + ' outbound rule defined successfully' >> C:\NCache-Init-Status.txt    
            }
        }

        Remove-Item -Path $configPath
        
        if (Test-Path $configPath)
        {
            $configPath + " removed successfully" >> C:\NCache-Init-Status.txt            
        }

        Start-Sleep -s 2

        $Expression = "Start-Cache -Name " + $clusterName + " -Server " + $currentIP + " -NoLogo"

        try {
            Invoke-Expression -Command $Expression -OutVariable output -ErrorVariable errors

            $output >> C:\NCache-Init-Status.txt

            $errors >> C:\NCache-Init-Status.txt
        }
        catch {
            #"Error in starting cluster" >> C:\startCluster.txt
            $_ >> C:\NCache-Init-Status.txt
        }
    }
}

function GetNCacheAcivation
{
    if ($licenseKey.Equals("NotSpecified")) {
        $licenseKey = ""
    }

    if ($licenseKey -ne "") {
        $NActivateExpression = '& "' + 'C:\Program Files\NCache\' + 'bin\NActivate\NActivate.exe" /k ' + $licenseKey + ' /f "' + $firstName + '" /l "' + $lastName + '" /e "' + $emailAddress + '" /comp "' + $company + '" /p "' + $phone + '" /v ' + $environment
    
        try {
            Invoke-Expression -Command $NActivateExpression >> C:\NCache-Init-Status.txt
        }
        catch {
            $_.Exception.Message >> C:\NCache-Init-Status.txt
        }
    }
}

 function GetNCacheLeads
 {
    $ncacheDownVer = @{}
    
    $ncacheDownVer.Add("4.6-SP3", "NC-ENT-46-40-64")
    $ncacheDownVer.Add("4.8", "NC-ENT-48-40-64")
    $ncacheDownVer.Add("4.9", "NC-ENT-49-40-64")
    $assemblyFileVersion = (Get-ChildItem 'C:\Program Files\NCache\bin\assembly\4.0\Alachisoft.NCache.Cache.dll').VersionInfo.FileVersion

    $alachisoftLeadURI = 'http://alachisoft.com/azurelead.php?email=' + $emailAddress + '&firstName=' + $firstName + '&lastName=' + $lastName + '&phone=' + $phone + '&company=' + $company + '&source=Azure Portal&osPlatform=' + $sku + '&vmCount=' + $vmCount + '&edition=' + $ncacheDownVer.Get_Item($ncacheVersion) + '&version=' + $assemblyFileVersion

    try {
       Invoke-WebRequest -Uri $alachisoftLeadURI -UseBasicParsing
   }
   catch {
       $_.Exception.Message >> C:\NCache-Init-Status.txt
   }

    if ($ncacheVersion.Equals("4.8")) {
        Remove-Item -Path 'vcredist_x64.exe'

       Remove-Item -Path 'vcredist_x86.exe'
   }

    if ($ncacheVersion.Equals("4.9")) {
       Remove-Item -Path 'vcredist_x64.exe'

       Remove-Item -Path 'vcredist_x86.exe'
   }
 }

if (!(Test-Path C:\NCache-Init-Status.txt)) {
    SetFirewallRules
    InstallNCache
    GetNCacheAcivation
    RestartNCacheService
    HandleClusterAndCache
    #GetNCacheLeads
}


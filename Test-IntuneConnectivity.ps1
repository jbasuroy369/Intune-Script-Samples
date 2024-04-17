<#
Script Name: Test-IntuneConnectivity.ps1
Author: Joymalya Basu Roy

DESCRIPTION
The script is created based on the Microsoft 365 IP Address and URL web service (https://aka.ms/ipurlws). 
A REST API call is made to the Worldwide instance to obtain the latest endpoint URLs 
for Service Area "MEM" and related "M365 Common" and then check connectivity to those endpoint URLs from the client.

PARAMETERS
n/a

PREREQUISITES
PS script execution policy: Bypass
PowerShell 3.0 or later
Does not require elevation
#>

Function Get-ProxySettings {
    # Check Proxy settings
    Write-Host "Checking winHTTP proxy settings..." -ForegroundColor Yellow
    $ProxyServer = "NoProxy"
    $winHTTP = netsh winhttp show proxy
    $Proxy = $winHTTP | Select-String server
    $ProxyServer = $Proxy.ToString().TrimStart("Proxy Server(s) :  ")

    if ($ProxyServer -eq "Direct access (no proxy server).") {
        $ProxyServer = "NoProxy"
        Write-Host "Access Type : DIRECT"
    }

    if ( ($ProxyServer -ne "NoProxy") -and (-not($ProxyServer.StartsWith("http://")))) {
        Write-Host "Access Type : PROXY"
        Write-Host "Proxy Server List :" $ProxyServer
        $ProxyServer = "http://" + $ProxyServer
    }
    return $ProxyServer
}

Function Get-M365CommonEndpointList {
    # Get up-to-date URLs
    $endpointListM365 = (invoke-restmethod -Uri ("https://endpoints.office.com/endpoints/WorldWide?ServiceAreas=Common`&clientrequestid=" + ([GUID]::NewGuid()).Guid)) | Where-Object { $_.ServiceArea -eq "Common" -and $_.urls }

    # Create categories to better understand what is being tested
    [PsObject[]]$endpointListCategoriesM365 = @()
    $endpointListCategoriesM365 += [PsObject]@{id = 56; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 59; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 78; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 83; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 84; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 125; category = 'M365 Common'; mandatory = $true }
    $endpointListCategoriesM365 += [PsObject]@{id = 156; category = 'M365 Common'; mandatory = $true }
    
    # Create new output object and extract relevant test information (ID, category, URLs only)
    [PsObject[]]$endpointRequestListM365 = @()
    for ($i = 0; $i -lt $endpointListM365.Count; $i++) {
        $endpointRequestListM365 += [PsObject]@{ id = $endpointListM365[$i].id; category = ($endpointListCategoriesM365 | Where-Object { $_.id -eq $endpointListM365[$i].id }).category; urls = $endpointListM365[$i].urls; mandatory = ($endpointListCategoriesM365 | Where-Object { $_.id -eq $endpointListM365[$i].id }).mandatory }
    }

    # Remove all *. from URL list (not useful)
    for ($i = 0; $i -lt $endpointRequestListM365.Count; $i++) {
        for ($j = 0; $j -lt $endpointRequestListM365[$i].urls.Count; $j++) {
            $targetUrl = $endpointRequestListM365[$i].urls[$j].replace('*.', '')
            $endpointRequestListM365[$i].urls[$j] = $targetURL
        }
        $endpointRequestListM365[$i].urls = $endpointRequestListM365[$i].urls | Sort-Object -Unique
    }
    
    return $endpointRequestListM365
}

Function Get-IntuneEndpointList {
    # Get up-to-date URLs
    $endpointList = (invoke-restmethod -Uri ("https://endpoints.office.com/endpoints/WorldWide?ServiceAreas=MEM`&clientrequestid=" + ([GUID]::NewGuid()).Guid)) | Where-Object { $_.ServiceArea -eq "MEM" -and $_.urls }

    # Create categories to better understand what is being tested
    [PsObject[]]$endpointListCategories = @()
    $endpointListCategories += [PsObject]@{id = 163; category = 'Global'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 164; category = 'Delivery Optimization'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 165; category = 'NTP Sync'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 169; category = 'Windows Notifications & Store'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 170; category = 'Scripts & Win32 Apps'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 171; category = 'Push Notifications'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 172; category = 'Delivery Optimization'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 173; category = 'Autopilot Self-deploy'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 178; category = 'Apple Device Management'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 179; category = 'Android (AOSP) Device Management'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 181; category = 'Remote Help'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 182; category = 'Collect Diagnostics'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 186; category = 'Microsoft Azure attestation - Windows 11 only'; mandatory = $true }
    $endpointListCategories += [PsObject]@{id = 187; category = 'Android Remote Help'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 188; category = 'Remote Help GCC Dependency'; mandatory = $false }
    $endpointListCategories += [PsObject]@{id = 189; category = 'Feature Flighting'; mandatory = $false }
    
    # Create new output object and extract relevant test information (ID, category, URLs only)
    [PsObject[]]$endpointRequestList = @()
    for ($i = 0; $i -lt $endpointList.Count; $i++) {
        $endpointRequestList += [PsObject]@{ id = $endpointList[$i].id; category = ($endpointListCategories | Where-Object { $_.id -eq $endpointList[$i].id }).category; urls = $endpointList[$i].urls; mandatory = ($endpointListCategories | Where-Object { $_.id -eq $endpointList[$i].id }).mandatory }
    }

    # Remove all *. from URL list (not useful)
    for ($i = 0; $i -lt $endpointRequestList.Count; $i++) {
        for ($j = 0; $j -lt $endpointRequestList[$i].urls.Count; $j++) {
            $targetUrl = $endpointRequestList[$i].urls[$j].replace('*.', '')
            $endpointRequestList[$i].urls[$j] = $targetURL
        }
        $endpointRequestList[$i].urls = $endpointRequestList[$i].urls | Sort-Object -Unique
    }
    
    return $endpointRequestList
}

Function Test-DeviceIntuneConnectivity {
    
    $ErrorActionPreference = 'SilentlyContinue'
    $TestFailed = $false
    $ProxyServer = Get-ProxySettings
    $endpointListM365Common = Get-M365CommonEndpointList
    $endpointListIntune = Get-IntuneEndpointList
    $failedEndpointList = @{}

    Write-Host "Starting Connectivity Check..." -ForegroundColor Yellow

    foreach ($endpoint in $endpointListM365Common) 
    {        
        if ($endpoint.mandatory -eq $true) 
        {  
            Write-Host "Checking Category: ..." $endpoint.category -ForegroundColor Yellow
            foreach ($url in $endpoint.urls) {
                if ($ProxyServer -eq "NoProxy") 
                {
                    $TestResult = (Invoke-WebRequest -uri $url -UseBasicParsing).StatusCode
                }
                else 
                {
                    $TestResult = (Invoke-WebRequest -uri $url -UseBasicParsing -Proxy $ProxyServer).StatusCode
                }
                if ($TestResult -eq 200) 
                {
                    if (($url.StartsWith('approdimedata') -or ($url.StartsWith("intunemaape13") -or $url.StartsWith("intunemaape17") -or $url.StartsWith("intunemaape18") -or $url.StartsWith("intunemaape19")))) {
                        Write-Host "Connection to " $url ".............. Succeeded (needed for Asia & Pacific tenants only)." -ForegroundColor Green 
                    }
                    elseif (($url.StartsWith('euprodimedata') -or ($url.StartsWith("intunemaape7") -or $url.StartsWith("intunemaape8") -or $url.StartsWith("intunemaape9") -or $url.StartsWith("intunemaape10") -or $url.StartsWith("intunemaape11") -or $url.StartsWith("intunemaape12")))) {
                        Write-Host "Connection to " $url ".............. Succeeded (needed for Europe tenants only)." -ForegroundColor Green 
                    }
                    elseif (($url.StartsWith('naprodimedata') -or ($url.StartsWith("intunemaape1") -or $url.StartsWith("intunemaape2") -or $url.StartsWith("intunemaape3") -or $url.StartsWith("intunemaape4") -or $url.StartsWith("intunemaape5") -or $url.StartsWith("intunemaape6")))) {
                        Write-Host "Connection to " $url ".............. Succeeded (needed for North America tenants only)." -ForegroundColor Green 
                    }
                    else {
                        Write-Host "Connection to " $url ".............. Succeeded." -ForegroundColor Green 
                    }
                }
                else 
                {
                    $TestFailed = $true
                    if ($failedEndpointList.ContainsKey($endpoint.category)) {
                        $failedEndpointList[$endpoint.category] += $url
                    }
                    else {
                        $failedEndpointList.Add($endpoint.category, $url)
                    }
                    if (($url.StartsWith('approdimedata') -or ($url.StartsWith("intunemaape13") -or $url.StartsWith("intunemaape17") -or $url.StartsWith("intunemaape18") -or $url.StartsWith("intunemaape19")))) {
                        Write-Host "Connection to " $url ".............. Failed (needed for Asia & Pacific tenants only)." -ForegroundColor Red 
                    }
                    elseif (($url.StartsWith('euprodimedata') -or ($url.StartsWith("intunemaape7") -or $url.StartsWith("intunemaape8") -or $url.StartsWith("intunemaape9") -or $url.StartsWith("intunemaape10") -or $url.StartsWith("intunemaape11") -or $url.StartsWith("intunemaape12")))) {
                        Write-Host "Connection to " $url ".............. Failed (needed for Europe tenants only)." -ForegroundColor Red 
                    }
                    elseif (($url.StartsWith('naprodimedata') -or ($url.StartsWith("intunemaape1") -or $url.StartsWith("intunemaape2") -or $url.StartsWith("intunemaape3") -or $url.StartsWith("intunemaape4") -or $url.StartsWith("intunemaape5") -or $url.StartsWith("intunemaape6")))) {
                        Write-Host "Connection to " $url ".............. Failed (needed for North America tenants only)." -ForegroundColor Red 
                    }
                    else {
                        Write-Host "Connection to " $url ".............. Failed." -ForegroundColor Red 
                    }
                }
            }
        }
        else 
        {
            #Write-Host "Skipping Category: ..." $endpoint.category -ForegroundColor Yellow
        }
    }

    foreach ($endpoint in $endpointListIntune) 
    {        
        if ($endpoint.mandatory -eq $true) 
        {
            Write-Host "Checking Category: ..." $endpoint.category -ForegroundColor Yellow
            foreach ($url in $endpoint.urls) {
                if ($ProxyServer -eq "NoProxy") {
                    $TestResult = (Invoke-WebRequest -uri $url -UseBasicParsing).StatusCode
                }
                else {
                    $TestResult = (Invoke-WebRequest -uri $url -UseBasicParsing -Proxy $ProxyServer).StatusCode
                }
                if ($TestResult -eq 200) {
                    if (($url.StartsWith('approdimedata') -or ($url.StartsWith("intunemaape13") -or $url.StartsWith("intunemaape17") -or $url.StartsWith("intunemaape18") -or $url.StartsWith("intunemaape19")))) {
                        Write-Host "Connection to " $url ".............. Succeeded (needed for Asia & Pacific tenants only)." -ForegroundColor Green 
                    }
                    elseif (($url.StartsWith('euprodimedata') -or ($url.StartsWith("intunemaape7") -or $url.StartsWith("intunemaape8") -or $url.StartsWith("intunemaape9") -or $url.StartsWith("intunemaape10") -or $url.StartsWith("intunemaape11") -or $url.StartsWith("intunemaape12")))) {
                        Write-Host "Connection to " $url ".............. Succeeded (needed for Europe tenants only)." -ForegroundColor Green 
                    }
                    elseif (($url.StartsWith('naprodimedata') -or ($url.StartsWith("intunemaape1") -or $url.StartsWith("intunemaape2") -or $url.StartsWith("intunemaape3") -or $url.StartsWith("intunemaape4") -or $url.StartsWith("intunemaape5") -or $url.StartsWith("intunemaape6")))) {
                        Write-Host "Connection to " $url ".............. Succeeded (needed for North America tenants only)." -ForegroundColor Green 
                    }
                    else {
                        Write-Host "Connection to " $url ".............. Succeeded." -ForegroundColor Green 
                    }
                }
                else {
                    $TestFailed = $true
                    if ($failedEndpointList.ContainsKey($endpoint.category)) {
                        $failedEndpointList[$endpoint.category] += $url
                    }
                    else {
                        $failedEndpointList.Add($endpoint.category, $url)
                    }
                    if (($url.StartsWith('approdimedata') -or ($url.StartsWith("intunemaape13") -or $url.StartsWith("intunemaape17") -or $url.StartsWith("intunemaape18") -or $url.StartsWith("intunemaape19")))) {
                        Write-Host "Connection to " $url ".............. Failed (needed for Asia & Pacific tenants only)." -ForegroundColor Red 
                    }
                    elseif (($url.StartsWith('euprodimedata') -or ($url.StartsWith("intunemaape7") -or $url.StartsWith("intunemaape8") -or $url.StartsWith("intunemaape9") -or $url.StartsWith("intunemaape10") -or $url.StartsWith("intunemaape11") -or $url.StartsWith("intunemaape12")))) {
                        Write-Host "Connection to " $url ".............. Failed (needed for Europe tenants only)." -ForegroundColor Red 
                    }
                    elseif (($url.StartsWith('naprodimedata') -or ($url.StartsWith("intunemaape1") -or $url.StartsWith("intunemaape2") -or $url.StartsWith("intunemaape3") -or $url.StartsWith("intunemaape4") -or $url.StartsWith("intunemaape5") -or $url.StartsWith("intunemaape6")))) {
                        Write-Host "Connection to " $url ".............. Failed (needed for North America tenants only)." -ForegroundColor Red 
                    }
                    else {
                        Write-Host "Connection to " $url ".............. Failed." -ForegroundColor Red 
                    }
                }
            }
        }
        else 
        {
            #Write-Host "Skipping Category: ..." $endpoint.category -ForegroundColor Yellow
        }
    }

    # If the test failed
    if ($TestFailed) 
    {
        Write-Host "Test failed. Please check the following URLs:" -ForegroundColor Red
        foreach ($failedEndpoint in $failedEndpointList.Keys) {
            Write-Host $failedEndpoint -ForegroundColor Red
            foreach ($failedUrl in $failedEndpointList[$failedEndpoint]) {
                Write-Host $failedUrl -ForegroundColor Red
            }
        }
    }
    Write-Host "Test-DeviceIntuneConnectivity completed successfully." -ForegroundColor Green -BackgroundColor Black
}

### Main ###

# Main function call
Test-DeviceIntuneConnectivity

# Get the current network config of the system and display
$NetworkConfiguration = @()
Get-NetIPConfiguration | ForEach-Object {
    $NetworkConfiguration += New-Object PSObject -Property @{
        InterfaceAlias = $_.InterfaceAlias
        ProfileName = if($null -ne $_.NetProfile.Name){$_.NetProfile.Name}else{""}
        IPv4Address = if($null -ne $_.IPv4Address){$_.IPv4Address}else{""}
        IPv6Address = if($null -ne $_.IPv6Address){$_.IPv6Address}else{""}
        IPv4DefaultGateway = if($null -ne $_.IPv4DefaultGateway){$_.IPv4DefaultGateway.NextHop}else{""}
        IPv6DefaultGateway = if($null -ne $_.IPv6DefaultGateway){$_.IPv6DefaultGateway.NextHop}else{""}
        DNSServer = if($null -ne $_.DNSServer){$_.DNSServer.ServerAddresses}else{""}
    }
}

$NetworkConfiguration | Format-Table -AutoSize

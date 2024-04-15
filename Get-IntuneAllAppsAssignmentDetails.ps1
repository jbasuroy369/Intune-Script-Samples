<#
ScriptName: Get-IntuneAllAppsAssignmentDetails.ps1
Author: Joymalya Basu Roy
Date: 15-04-2024
Version 1.0
#>

# Install the Microsoft Graph PowerShell module
if(-not (Get-Module -Name Microsoft.Graph -ListAvailable))
{
    try {
            Install-Module -Name Microsoft.Graph -Repository PSGallery -Force -AllowClobber
    }catch [Exception] {
            $_.message 
    }
}

# Import the Microsoft Graph PowerShell module to current PS session
try{
    Import-Module -Name Microsoft.Graph
}catch [Exception] {
            $_.message 
    }

# Declare path to save export CSV
$ExportCSVpath = "C:\Temp\Get-IntuneAllAppsAssignmentDetails.csv"

# Connect to Microsoft Graph
$appid = '<Your Entra Registered App ID here>'
$tenantid = '<Your Tenant ID here>'
$secret = '<Your Entra Registered App Client Secret here>'
 
$body =  @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $appid
    Client_Secret = $secret
}
 
$connection = Invoke-RestMethod `
    -Uri https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token `
    -Method POST `
    -Body $body
 
$token = $connection.access_token
$accessToken = ConvertTo-SecureString -String $token -AsPlainText -Force

Connect-MgGraph -AccessToken $accessToken -NoWelcome

### Main Section ###

# Retrieve all apps published in Intune
$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments,Category,Version"

try{
    $Apps = (Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject).Value
}catch {
    
        $ex = $_.Exception
        Write-Host "Request to $Uri failed with HTTP Status $([int]$ex.Response.StatusCode) $($ex.Response.StatusDescription)" -f Red
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
}

Write-host "Number of Apps found is: $($Apps.DisplayName.Count)" -ForegroundColor Cyan

# Create a new array object
$Output=New-Object System.Collections.ArrayList

# Get the required details of each app as retrived
foreach ($App in $Apps) 
    {
        # Display the App Name to screen

        Write-host "App Name: $($App.displayName)" -ForegroundColor Yellow
        
        # Localization of App Type

        $AppType = switch($App.'@odata.type'){
                        "#microsoft.graph.androidLobApp" { 'Android LOB' }
                        "#microsoft.graph.androidStoreApp" { 'Google Play' }
                        "#microsoft.graph.androidManagedStoreWebApp" { 'Android Managed Store Web App' }
                        "#microsoft.graph.managedAndroidLobApp" { 'Managed Android LOB' }
                        "#microsoft.graph.managedAndroidStoreApp" { 'Managed Google Play' }
                        "#microsoft.graph.androidForWorkApp" { 'Android for Work' }
                        "#microsoft.graph.iosLobApp" { 'iOS LOB' }
                        "#microsoft.graph.iosStoreApp" { 'iOS Store' }
                        "#microsoft.graph.managedIOSLobApp" { 'Managed iOS LOB' }
                        "#microsoft.graph.managedIOSStoreApp" { 'Managed iOS Store' }
                        "#microsoft.graph.iosVppApp" { 'iOS VPP' }
                        "#microsoft.graph.iosVppEBook" { 'iOS VPP Ebook' }
                        "#microsoft.graph.iosiPadOSWebClip" { 'iOS Weblink' }
                        "#microsoft.graph.webApp" { 'Web Link' }
                        "#microsoft.graph.microsoftStoreForBusiness" { 'Microsoft Store' }
                        "#microsoft.graph.winGetApp" { 'New Microsoft Store' }
                        "#microsoft.graph.windowsStoreApp" { 'Windows Store App' }
                        "#microsoft.graph.windowsPhoneXAP" { 'Windows Phone XAP' }
                        "#microsoft.graph.win32LobApp" { 'Win32' }
                        "#microsoft.graph.windowsAppX" { 'Windows AppX' }
                        "#microsoft.graph.windowsMicrosoftEdgeApp" { 'Intune Windows Built-in Edge App' }
                        "#microsoft.graph.windowsMobileMSI" { 'Windows MSI' }
                        "#microsoft.graph.windowsUniversalAppX" { 'Windows Universl AppX' }
                        "#microsoft.graph.windowsUniversalAppXContainedApp" { 'Windows Universal AppX Contained App' }
                        "#microsoft.graph.windowsWebApp"  { 'Windows Web App' }
                        "#microsoft.graph.officeSuiteApp" { 'Intune Windows Built-in M365 App for Enterprise' }
                        "#microsoft.graph.macOSDmgApp" { 'MacOS DMG' }
                        "#microsoft.graph.macOSLobApp" { 'MacOS LOB' }
                        "#microsoft.graph.macOSMdatpApp" { 'MacOS MDATP' }
                        "#microsoft.graph.macOSMicrosoftDefenderApp" { 'MacOS Defender' }
                        "#microsoft.graph.macOSMicrosoftEdgeApp" { 'MacOS Edge' }
                        "#microsoft.graph.macOSOfficeSuiteApp" { 'Intune MacOS Built-in M365 App for Enterprise' }
                        "#microsoft.graph.macOSPkgApp" { 'MacOS PKG' }
                        "#microsoft.graph.macOsVppApp" { 'MacOS VPP' }
                        *default* { 'Unknown' }
        }

        # Display the App Type to screen
        Write-host "App Type: $AppType" -ForegroundColor Cyan

        # Display the App version to screen (only for Windows Win32 and MSI)
        $AppVer = $App.displayVersion
        Write-host "App Version: $AppVer"

        # Logic below is to check for App assignment intent and assignment group
        If(($App.assignments -eq $null) -or ($App.assignments -eq "") -or ($App.assignments.count -lt 1))
        {
            Write-Host "No assignments for this app"
            $GroupName = "Not Assigned"
            $Output.Add( (New-Object -TypeName PSObject -Property @{"Name"="$($App.displayName)"; "Platform" = "$AppType"; "Version" = "$AppVer"; "Group" = "$GroupName"; "Assignment" = "$null"} ) )
        } 
        else 
        {
            foreach($assignment in $App.assignments)
            {
                # Available or Required
                write-host "Assignment intent: $($assignment.intent)"
 
                If ($($assignment.target.'@odata.type') -like "*allLicensedUsersAssignmentTarget"){
                    Write-Host "Published to All Users"
                    $GroupName = "All Users"
                } elseif($($assignment.target.'@odata.type') -like "*allDevicesAssignmentTarget"){
                    Write-Host "Published to All Devices"
                    $GroupName = "All Devices"
                }
                else
                {
                    # Lookup the AAD Group displayname
                    write-host "Group ID: $($assignment.target.GroupID)"
                    $GroupName = (Get-MgGroup -GroupId $assignment.target.GroupID).DisplayName
                }

                # Add all the properties into a new object in the array
                Write-Host "Group Name: $GroupName"
                $Output.Add( (New-Object -TypeName PSObject -Property @{"Name"="$($App.displayName)"; "Platform" = "$AppType"; "Version" = "$AppVer"; "Group" = "$GroupName"; "Assignment" = "$($assignment.intent)"} ) )
            }
        }
    }

$output | select Name,Platform,Version,Assignment,Group | Export-CSV -Path $ExportCSVpath -Encoding utf8 -NoTypeInformation -Append

Disconnect-MgGraph
try 
{
    $ReportedVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name "VersionToReport"
    $Channel = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name "CDNBaseUrl" | Select-Object -Last 1
    $CloudVersionInfo = Invoke-RestMethod 'https://clients.config.office.net/releases/v1.0/OfficeReleases'
    $UsedChannel = $cloudVersioninfo | Where-Object { $_.OfficeVersions.cdnBaseURL -eq $channel }
    if (($UsedChannel.channelId -eq "SemiAnnual") -and ($UsedChannel.latestversion -eq $ReportedVersion)) {
        Write-Host "Currently using the latest version of Office in the $($UsedChannel.Channel) Channel: $($ReportedVersion)"
        Exit 0
    }
    else {
        Write-Host "Not using Semi-Annual channel. Detected channel is the $($UsedChannel.Channel) Channel."
        Exit 1   
    }
}
catch
{
    $errMsg = $_.Exception.Message
    Write-Host $errMsg
    Exit 1
}
try
{
    # Get all certificates from Local Machine Personal store with Issuer matching Microsoft Intune MDM Device CA
    $certificates = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Issuer -eq "CN=Microsoft Intune MDM Device CA"}
    if(($certificates).Count -gt 1)
        {
            # Remediation needed on exit code 1
            Write-Output "Remediation needed"
            Exit 1
        }
    else
        {
            # Remediation not needed on exit code 0
            Write-Output "Remediation not needed"
            Exit 0
        }
}
catch 
{
    $errMsg = $_.Exception.Message
    Write-Host $errMsg
    Exit 1
}

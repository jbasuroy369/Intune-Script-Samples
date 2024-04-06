# If running as a 32-bit process on an x64 system, re-launch as a 64-bit process

if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64")
{
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe")
    {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
        Exit $lastexitcode
    }
}
    
# Logging Preparation

$AppName = "Activate_SmartCardLogon_Enforcement"
$Log_FileName = "win32-$AppName.log"
$Log_Path = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\"
$TestPath = "$Log_Path\$Log_Filename"
$BreakingLine="- - "*10
$SubBreakingLine=". . "*10
$SectionLine="* * "*10

If(!(Test-Path $TestPath))
{
New-Item -Path $Log_Path -Name $Log_FileName -ItemType "File" -Force
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Message
    )
$timestamp = Get-Date -Format "dddd MM/dd/yyyy HH:mm:ss"
Add-Content -Path $TestPath -Value "$timestamp : $Message"
}

# Start logging [Same file will be used for IME detection]

Write-Log "Begin..."
Write-Log $SectionLine

#Enforcing SmartCard Login

try
{
    if (-NOT (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System')) {
        # Creating reg path
        Write-Log "Reg path not found, hence creating Reg path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Log "Reg path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System found, updating Reg key scforceoption with value 1"
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'scforceoption' -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Log "Reg key value updated"
}
catch 
{
    $errMsg = $_.Exception.Message
    Write-Log $errMsg
}

#Enforceing Autolock upon Smart Card removal

try
{
    if (-NOT (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon')) {
        # Creating reg path
        Write-Log "Reg path not found, hence creating Reg path HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Log "Reg path HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon found, updating Reg key ScRemoveOption with value 1"
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'ScRemoveOption' -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Log "Reg key value updated"
}
catch 
{
    $errMsg = $_.Exception.Message
    Write-Log $errMsg
}

try
{
    if (-NOT (Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\SCPolicySvc')) {
        # Creating reg path
        Write-Log "Reg path not found, hence creating Reg path HKLM:\SYSTEM\CurrentControlSet\Services\SCPolicySvc"
        New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Log "Reg path HKLM:\SYSTEM\CurrentControlSet\Services\SCPolicySvc found, updating Reg key Start with value 2"
    New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\SCPolicySvc' -Name 'Start' -Value 2 -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Log "Reg key value updated"
}
catch 
{
    $errMsg = $_.Exception.Message
    Write-Log $errMsg
}


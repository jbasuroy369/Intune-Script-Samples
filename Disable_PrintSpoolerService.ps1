$service = Get-Service -Name "Spooler"
if ($service.Status -eq "Running") 
{
    Stop-Service -name "Spooler" -force
    Set-Service -name "Spooler" -startupType "Disabled"
} 
else 
{
    Set-Service -name "Spooler" -startupType "Disabled"
}
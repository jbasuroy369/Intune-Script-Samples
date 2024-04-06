$service = Get-Service -Name "Spooler"
if ($service.Status -eq "Running") 
{
    Set-Service -name "Spooler" -startupType "Automatic"
} 
else 
{
    Set-Service -name "Spooler" -startupType "Automatic"
    sleep-start 10
    Set-Service -Name "Spooler" -Status "Running"
}
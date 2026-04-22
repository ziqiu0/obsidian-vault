# Create scheduled task for daily Obsidian backup
# This script needs to be run once as Administrator

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File D:\biji_obsidian\backup.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 3:00
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable -AllowStartIfOnBatteries

Register-ScheduledTask -TaskName "Daily Obsidian Backup to GitHub" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Automatically backup Obsidian vault to GitHub every day at 3:00 AM"

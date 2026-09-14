$taskName = "AutoGitCommit-Daily"
$scriptPath = Join-Path $PSScriptRoot "auto-commit.ps1"

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -Daily -At "09:30"

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal

Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null

Write-Host "已注册计划任务: $taskName" -ForegroundColor Green
Write-Host "触发时间: 每天 09:30"
Write-Host "执行脚本: $scriptPath"
Write-Host ""
Write-Host "管理命令:"
Write-Host "  查看:   Get-ScheduledTask -TaskName '$taskName' | Get-ScheduledTaskInfo"
Write-Host "  立即运行: Start-ScheduledTask -TaskName '$taskName'"
Write-Host "  卸载:   Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"

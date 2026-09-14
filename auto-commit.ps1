$ErrorActionPreference = "Continue"
$OutputEncoding = [System.Text.Encoding]::UTF8
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$repoPath = $PSScriptRoot
$logFile = Join-Path $repoPath "auto-commit.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    Write-Host $line
}

function Run-Git {
    param([string]$Desc, [scriptblock]$Block)
    Write-Log $Desc
    $out = & $Block 2>&1
    if ($out) { $out | ForEach-Object { Write-Log ($_.ToString()) } }
    return $LASTEXITCODE
}

try {
    Set-Location -LiteralPath $repoPath
    Write-Log "===== 开始自动提交 ====="

    $code = Run-Git "拉取远程更新 (git pull --rebase --autostash)..." { git pull --rebase --autostash }
    if ($code -ne 0) { Write-Log "警告: 拉取失败 (code=$code)，继续处理本地更改。" }

    $code = Run-Git "暂存所有更改 (git add -A)..." { git add -A }

    $status = & git status --porcelain 2>&1
    if (-not $status) {
        Write-Log "没有需要提交的更改。"
        Write-Log "===== 完成 (无更改) ====="
        exit 0
    }

    $commitMsg = "auto update: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $code = Run-Git "提交更改: $commitMsg" { git commit -m $commitMsg }
    if ($code -ne 0) {
        Write-Log "错误: 提交失败 (code=$code)。"
        Write-Log "===== 失败 ====="
        exit 1
    }

    $code = Run-Git "推送到远程仓库 (git push origin main)..." { git push origin main }
    if ($code -ne 0) {
        Write-Log "错误: 推送失败 (code=$code)。"
        Write-Log "===== 失败 ====="
        exit 1
    }

    Write-Log "===== 提交并推送完成 ====="
    exit 0
}
catch {
    Write-Log ("异常: " + $_.Exception.Message)
    Write-Log "===== 失败 ====="
    exit 1
}


# Obsidian Vault Auto Backup Script
# Runs daily at 3:00 AM

$ErrorActionPreference = "Stop"

# Configuration - update these values for your repository
$githubUsername = "ziqiu0"
$repositoryName = "obsidian-vault"
$credentialsPath = "C:\Users\Administrator\.openclaw\workspace\CREDENTIALS.md"
$vaultPath = "D:\biji_obsidian"

# Read GitHub token from credentials
if (Test-Path $credentialsPath) {
    $content = Get-Content $credentialsPath -Raw
    if ($content -match 'token:\s*(ghp_\w+)') {
        $token = $matches[1]
    }
}

if (-not $token) {
    Write-Error "Failed to read GitHub token from CREDENTIALS.md"
    exit 1
}

Set-Location $vaultPath
git config user.email "agent@openclaw.local"
git config user.name "OpenClaw Agent"
git add .

$status = git status --porcelain
if ($status) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    git commit -m "Auto backup: $timestamp"
    git remote set-url origin "https://$token@github.com/$githubUsername/$repositoryName.git"
    git push -u origin master
    Write-Host "[$timestamp] Backup successful to GitHub"
} else {
    Write-Host "No changes detected, skipping backup"
}

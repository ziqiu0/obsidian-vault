# 📝 Auto Backup to GitHub

This vault is automatically backed up to GitHub every day at 3:00 AM.

## Backup Script

- **Script Location**: `D:\biji_obsidian\backup.ps1`
- **Scheduled Task**: Daily at 3:00 AM via Windows Task Scheduler
- **Remote Repository**: https://github.com/ziqiu0/obsidian-vault

## How it works

1. Check for changes using `git status --porcelain`
2. If changes detected:
   - `git add .`
   - `git commit -m "Auto backup: [timestamp]"`
   - `git push` to origin master
3. If no changes: skip backup

## Manual Backup

Run manually when needed:
```powershell
cd D:\biji_obsidian
powershell -ExecutionPolicy Bypass -File .\backup.ps1
```

## Last Test

- **Test Date**: 2026-04-22
- **Status**: ✅ Working

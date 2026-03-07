@echo off
:: MadOS 3.0 QEMU Portable Launcher
:: Ce script lance la version PowerShell en bypassant les restrictions d'execution locales
:: et sans demander les droits Administrateur !

color 0C
echo ==========================================================
echo        MadOS 3.0 - Lancement QEMU Portable
echo ==========================================================
echo.

:: Execution du script PowerShell sans droits Admin
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0MadOS_Qemu_Portable.ps1"

pause

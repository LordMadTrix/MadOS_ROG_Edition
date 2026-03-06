@echo off
:: ==============================================================================
:: MadOS ROG Edition - Lanceur Cle USB (Auto-Admin)
:: usb\create_mados_usb.bat
:: ==============================================================================
:: Double-cliquez sur ce fichier. Windows demande l'admin automatiquement.
:: ==============================================================================

:: ---- Auto-elevation Admin ----
>nul 2>&1 net session
if %errorlevel% NEQ 0 (
    echo Demande d'elevation administrateur...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo   =============================================
echo     MadOS ROG Edition - USB Maker Launcher
echo   =============================================
echo.
echo   Lancement de create_mados_usb.ps1 en admin...
echo.

cd /d "%~dp0"

if not exist "create_mados_usb.ps1" (
    echo   [ERREUR] create_mados_usb.ps1 introuvable !
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0create_mados_usb.ps1"

pause

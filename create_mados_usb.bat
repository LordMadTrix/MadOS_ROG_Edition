@echo off
:: ==============================================================================
:: MadOS ROG Edition — Lanceur Clé USB (Auto-Admin)
:: create_mados_usb.bat
:: ==============================================================================
:: Double-cliquez sur ce fichier. Windows demande l'admin automatiquement.
:: Il lance ensuite create_mados_usb.ps1
:: ==============================================================================

:: ---- Auto-élévation Admin ----
>nul 2>&1 net session
if %errorlevel% NEQ 0 (
    echo Demande d'elevation administrateur...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ---- On est admin, on lance le script PowerShell ----
cls
echo.
echo   =============================================
echo     MadOS ROG Edition - USB Maker Launcher
echo   =============================================
echo.
echo   Lancement de create_mados_usb.ps1 en admin...
echo.

:: Changer de répertoire vers le dossier du .bat (même dossier que le .ps1)
cd /d "%~dp0"

:: Vérifier que le .ps1 existe
if not exist "create_mados_usb.ps1" (
    echo   [ERREUR] create_mados_usb.ps1 introuvable !
    echo   Assurez-vous que ce .bat est dans le meme dossier que create_mados_usb.ps1
    pause
    exit /b 1
)

:: Lancer le PowerShell avec bypass de la politique d'exécution
powershell -ExecutionPolicy Bypass -File "%~dp0create_mados_usb.ps1"

pause

@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

:: --- AUTO-ELEVATION ADMIN ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Demande des privileges Administrateur...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

title MadOS 3.0 - LANCEUR ROG SUPER-TESTER v3.1 [VMWARE]
mode con: cols=90 lines=30
color 0c

:: --- LOGO ROG ASCII ---
echo.
echo    ########   #######   ######    
echo    ##     ## ##     ## ##    ##   
echo    ##     ## ##     ## ##         
echo    ########  ##     ## ##   ####  
echo    ##   ##   ##     ## ##    ##   
echo    ##    ##  ##     ## ##    ##   
echo    ##     ##  #######   ######    
echo  ---------------------------------------------------------
echo     MadOS ROG Edition - VMware Automation Engine 3.1
echo  ---------------------------------------------------------
echo.

:: 1. Vérification des privilèges Administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERREUR] Merci de lancer ce script en tant qu'ADMINISTRATEUR.
    echo.
    pause
    exit /b
)

:: 2. Nettoyage agressif des processus et verrous
echo [!] Fermeture des processus VMware existants...
taskkill /f /im vmware.exe >nul 2>&1
taskkill /f /im vmplayer.exe >nul 2>&1
taskkill /f /im vmware-vmx.exe >nul 2>&1

echo [!] Nettoyage des verrous (.lck) et fichiers temporaires...
for /d /r "%~dp0" %%d in (*.lck) do (
    echo --- Libération du verrou : %%d
    rd /s /q "%%d" >nul 2>&1
)
if exist "BIT*.tmp" (
    echo --- Suppression des anciens fragments ISO detectes...
    del /q "BIT*.tmp" 2>nul
)

:: 3. Vérification Presence VMware
if not exist "C:\Program Files (x86)\VMware" (
    echo [CRITIQUE] VMware n'est pas installe dans le dossier par defaut !
    pause
    exit /b
)

:: 4. Lancement de l'orchestrateur MadOS 3.0
echo [🚀] Lancement du moteur de deploiement PowerShell...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0MadOS_VMware_SuperTest.ps1"

echo.
echo =========================================================
echo    PROCESSUS DE TEST ENGINE : TERMINE / DECONNECTE
echo =========================================================
echo Appuyez sur une touche pour quitter.
pause >nul

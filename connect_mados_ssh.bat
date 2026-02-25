@echo off
setlocal enabledelayedexpansion
title Connexion Rapide SSH - Mados VM (Auto/Manuel)
color 0f

echo =======================================================
echo.
echo      Recherche et Connexion SSH vers la VM MadOS
echo.
echo =======================================================
echo.

set "SSH_USER=mados"
set "SSH_PORT=22"
set "IP_FOUND="

:: Option 1: Recherche par nom d'hote
echo [1/2] Recherche du nom d'hote "mados-rog"...
for /f "tokens=2 delims=[]" %%i in ('ping -n 1 -w 1000 mados-rog 2^>nul') do (
    set "IP_FOUND=%%i"
)

if defined IP_FOUND (
    echo [SUCCES] VM MadOS trouvee a l'adresse IP : !IP_FOUND! (par ping hostname)
    goto prompt_user
)

echo [INFO] Impossible de resoudre le nom d'hote sur le reseau local.
echo.

:: Option 2: Recherche par balayage ARP (Support Windows FR et EN)
echo [2/2] Tentative de balayage du cache ARP local...
for /f "tokens=1" %%A in ('arp -a ^| findstr /i "dynamic dynamique"') do (
    set "TEST_IP=%%A"
    set "TEST_IP=!TEST_IP: =!"
    
    echo Test de l'IP : !TEST_IP!...
    ping -n 1 -w 100 !TEST_IP! >nul
    if !errorlevel! equ 0 (
        :: Test SSH rapide avec Powershell
        powershell -Command "try { $t = New-Object System.Net.Sockets.TcpClient; $c = $t.ConnectAsync('!TEST_IP!', 22); if ($c.Wait(300)) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
        if !errorlevel! equ 0 (
            set "IP_FOUND=!TEST_IP!"
            echo [SUCCES] VM MadOS trouvee a l'adresse IP : !IP_FOUND! (via ARP / SSH Actif)
            goto prompt_user
        )
    )
)

:prompt_user
if not defined IP_FOUND (
    color 0e
    echo.
    echo =======================================================
    echo [ATTENTION] Impossible de trouver la machine automatiquement.
    echo =======================================================
    set /p IP_FOUND="Veuillez entrer l'adresse IP de la VM Linux manuellement : "
    if "!IP_FOUND!"=="" (
        echo Annulation...
        exit /b 1
    )
    color 0f
)

echo.
echo Utilisateur actuel : %SSH_USER%
set /p CUSTOM_USER="Entrez un autre nom d'utilisateur de la VM (ou Entree pour garder '%SSH_USER%') : "
if not "!CUSTOM_USER!"=="" set "SSH_USER=!CUSTOM_USER!"

:connect
echo.
echo =======================================================
echo Connexion en cours vers %SSH_USER%@!IP_FOUND! sur le port %SSH_PORT%...
echo =======================================================
echo.
ssh -p %SSH_PORT% %SSH_USER%@!IP_FOUND!

echo.
echo Connexion terminee.
pause

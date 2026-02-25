@echo off
setlocal enabledelayedexpansion
title Connexion Rapide SSH - Mados VM (Auto-Search)
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

:: Option 1: Recherche par nom d'hôte utilisant le Ping local
echo [1/2] Recherche du nom d'hote "mados-rog"...
for /f "tokens=2 delims=[]" %%i in ('ping -n 1 -4 mados-rog 2^>nul') do (
    set "IP_FOUND=%%i"
)

if defined IP_FOUND (
    echo [SUCCES] VM MadOS trouvee a l'adresse IP : !IP_FOUND! (par nom d'hote)
    goto connect
)

echo [INFO] Impossible de resoudre le nom d'hote. 
echo.

:: Option 2: Recherche par balayage ARP (utile si on connaît l'OUI / début de l'adresse MAC)
:: Note : ceci suppose que vous avez fait un ping vers quelques adresses IP
:: ou que la VM a recemment communique sur le reseau local (Hyper-V / VMware Bridge).
echo [2/2] Tentative de balayage du cache ARP local...
:: Vous pouvez changer l'identifiant MAC (ex. 00-15-5d pour Hyper-V ou 00-0c-29 pour VMware)
:: Ici on cherche toutes les adresses IP dynamiques recentes listées, en prenant la première qui répond en SSH.

for /f "tokens=1,2" %%A in ('arp -a ^| findstr "dynamique"') do (
    set "TEST_IP=%%A"
    :: Enlevez les espaces
    set "TEST_IP=!TEST_IP: =!"
    
    echo Test de l'IP : !TEST_IP!...
    :: Un ping très court pour vérifier la base
    ping -n 1 -w 200 !TEST_IP! >nul
    if !errorlevel! equ 0 (
        :: Test SSH rapide avec timeout PowerShell (1s)
        powershell -Command "$t = New-Object System.Net.Sockets.TcpClient; $c = $t.ConnectAsync('!TEST_IP!', 22); if ($c.Wait(500)) { exit 0 } else { exit 1 }" >nul 2>&1
        if !errorlevel! equ 0 (
            set "IP_FOUND=!TEST_IP!"
            echo [SUCCES] VM MadOS trouvee a l'adresse IP : !IP_FOUND! (via ARP / SSH Actif)
            goto connect
        )
    )
)

if not defined IP_FOUND (
    color 0c
    clear
    echo =======================================================
    echo [ERREUR] Impossible de trouver la machine virtuelle MadOS sur le reseau local.
    echo.
    echo Pistes de resolution :
    echo - Verifiez que la VM est demarree (Hyper-V, VMware ou QEMU).
    echo - Verifiez que le service SSH est actif sur la VM ^(sudo systemctl start ssh^).
    echo - Assurez-vous que la VM a une IP visible ^(Mode Pont ou NAT configure^).
    echo =======================================================
    pause
    exit /b 1
)

:connect
echo.
echo =======================================================
echo Connexion en cours vers %SSH_USER%@!IP_FOUND! sur le port %SSH_PORT%...
echo =======================================================
echo.
ssh -p %SSH_PORT% %SSH_USER%@!IP_FOUND!
pause

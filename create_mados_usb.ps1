# ==============================================================================
# MadOS ROG Edition — Préparateur de Clé USB Offline
# create_mados_usb.ps1
# ==============================================================================
# Usage  : Clic droit -> "Exécuter avec PowerShell" (en Administrateur)
# Résultat : Clé USB "MADOS" prête à lancer l'installateur sans Internet
# ==============================================================================

$Host.UI.RawUI.WindowTitle = "MadOS USB Maker v3.1"

# --- Couleurs et Header ---
Clear-Host
Write-Host ""
Write-Host "  ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗" -ForegroundColor Red
Write-Host "  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝" -ForegroundColor Red
Write-Host "  ██╔████╔██║███████║██║  ██║██║   ██║███████╗" -ForegroundColor Red
Write-Host "  ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║" -ForegroundColor White
Write-Host "  ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║" -ForegroundColor White
Write-Host "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝" -ForegroundColor White
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "  ║        CRÉATEUR DE CLÉ USB MADOS          ║" -ForegroundColor Red
Write-Host "  ║        by LordMadTrix  — v3.1             ║" -ForegroundColor Red
Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

# --- Vérifications Admin ---
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$currentUser
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "  [ERREUR] Ce script doit être lancé en Administrateur !" -ForegroundColor Red
    Write-Host "  Clic droit sur le script -> Exécuter avec PowerShell (Admin)" -ForegroundColor Yellow
    Read-Host "`n  Appuyez sur Entrée pour quitter"
    exit 1
}

# --- Dossier source (là où se trouve ce script) ---
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "  [INFO] Dossier source : $SourceDir" -ForegroundColor Cyan

# --- Vérifie que les fichiers sources sont présents ---
if (-not (Test-Path "$SourceDir\install_local.sh")) {
    Write-Host "  [ERREUR] install_local.sh introuvable dans $SourceDir" -ForegroundColor Red
    Write-Host "  Assurez-vous de lancer ce script depuis le dossier MadOS." -ForegroundColor Yellow
    Read-Host "`n  Appuyez sur Entrée pour quitter"
    exit 1
}
if (-not (Test-Path "$SourceDir\modules")) {
    Write-Host "  [ERREUR] Dossier modules/ introuvable dans $SourceDir" -ForegroundColor Red
    Read-Host "`n  Appuyez sur Entrée pour quitter"
    exit 1
}

# --- Lister les disques amovibles ---
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  [1/3] Détection des clés USB connectées..." -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

$removableDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }

if ($removableDrives.Count -eq 0) {
    Write-Host "  [ERREUR] Aucune clé USB détectée !" -ForegroundColor Red
    Write-Host "  Branchez une clé USB et relancez le script." -ForegroundColor Yellow
    Read-Host "`n  Appuyez sur Entrée pour quitter"
    exit 1
}

Write-Host "  Clés USB disponibles :" -ForegroundColor White
$i = 1
$driveList = @()
foreach ($drive in $removableDrives) {
    $sizeGB = [math]::Round($drive.Size / 1GB, 1)
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 1)
    Write-Host "    [$i] $($drive.DeviceID)  —  $($drive.VolumeName)  ($sizeGB GB total, $freeGB GB libres)" -ForegroundColor Cyan
    $driveList += $drive.DeviceID
    $i++
}
Write-Host ""

$selection = Read-Host "  Entrez le numéro de la clé USB cible (ou Q pour annuler)"
if ($selection -eq "Q" -or $selection -eq "q") { exit 0 }
$selIndex = [int]$selection - 1
if ($selIndex -lt 0 -or $selIndex -ge $driveList.Count) {
    Write-Host "  [ERREUR] Sélection invalide." -ForegroundColor Red
    Read-Host "  Appuyez sur Entrée pour quitter"
    exit 1
}

$TargetDrive = $driveList[$selIndex]
Write-Host ""
Write-Host "  ⚠️  ATTENTION : Toutes les données sur $TargetDrive seront EFFACÉES !" -ForegroundColor Red
$confirm = Read-Host "  Tapez MADOS pour confirmer le formatage"
if ($confirm -ne "MADOS") {
    Write-Host "  Annulation. Rien n'a été modifié." -ForegroundColor Yellow
    exit 0
}

# --- Formatage FAT32 avec label MADOS ---
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  [2/3] Formatage de $TargetDrive en FAT32 (label: MADOS)..." -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# Obtenir le numéro de volume via WMI
$diskLetter = $TargetDrive.TrimEnd(":")
try {
    $formatResult = Format-Volume -DriveLetter $diskLetter -FileSystem FAT32 -NewFileSystemLabel "MADOS" -Force -Confirm:$false
    Write-Host "  ✓ Formatage terminé." -ForegroundColor Green
}
catch {
    Write-Host "  [ERREUR] Échec du formatage : $_" -ForegroundColor Red
    Write-Host "  Essayez de formater manuellement en FAT32 avec le label MADOS." -ForegroundColor Yellow
    Read-Host "  Appuyez sur Entrée pour quitter"
    exit 1
}

Start-Sleep -Seconds 2

# --- Copie des fichiers ---
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  [3/4] Copie des scripts MadOS sur la clé USB..." -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$UsbRoot = "$TargetDrive\"

# --- Copie et conversion du logo pour l'icône USB ---
$logoPath = "$SourceDir\logo.png"
$icoPath = "$UsbRoot\autorun.ico"
if (Test-Path $logoPath) {
    Write-Host "  → logo.png (conversion en autorun.ico)" -ForegroundColor Cyan
    # Conversion PNG en ICO
    try {
        Add-Type -AssemblyName System.Drawing
        $image = [System.Drawing.Image]::FromFile($logoPath)
        # Pour créer un ICO multi-tailles, il faudrait redimensionner l'image
        # Pour un ICO simple, on peut extraire l'icône directement.
        # Note: FromHandle($image.GetHicon()) peut ne pas toujours produire un ICO idéal.
        # Une approche plus robuste serait de créer un Bitmap de la taille voulue (ex: 256x256)
        # puis de le dessiner sur un Graphics, et enfin de le convertir en icône.
        # Pour la simplicité, on utilise FromHandle ici.
        $icon = [System.Drawing.Icon]::FromHandle($image.GetHicon())
        $fileStream = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
        $icon.Save($fileStream)
        $fileStream.Close()
        $icon.Dispose()
        $image.Dispose()
        Write-Host "  ✓ autorun.ico créé." -ForegroundColor Green
    }
    catch {
        Write-Host "  [AVERTISSEMENT] Échec de la conversion de logo.png en autorun.ico : $_" -ForegroundColor Yellow
        Write-Host "  L'icône personnalisée ne sera pas affichée." -ForegroundColor Yellow
    }
}
else {
    Write-Host "  [INFO] logo.png non trouvé. L'icône USB par défaut sera utilisée." -ForegroundColor DarkYellow
}

# Crée le fichier autorun.inf pour l'icône et le label
Write-Host "  → autorun.inf" -ForegroundColor Cyan
$autorunContent = @"
[autorun]
label=MADOS
icon=autorun.ico
"@
$autorunContent | Out-File -FilePath "$UsbRoot\autorun.inf" -Encoding Default -Force # Default encoding for .inf

# Copie install_local.sh
Write-Host "  → install_local.sh" -ForegroundColor Cyan
Copy-Item "$SourceDir\install_local.sh" "$UsbRoot\install_local.sh" -Force

# Copie start.sh (lanceur racine)
if (Test-Path "$SourceDir\start.sh") {
    Write-Host "  → start.sh" -ForegroundColor Cyan
    Copy-Item "$SourceDir\start.sh" "$UsbRoot\start.sh" -Force
}

# Copie le dossier modules/ entier
Write-Host "  → modules/ ($((Get-ChildItem "$SourceDir\modules" -Filter "*.sh").Count) scripts)" -ForegroundColor Cyan
$UsbModules = "$UsbRoot\modules"
if (-not (Test-Path $UsbModules)) { New-Item -ItemType Directory -Path $UsbModules | Out-Null }
Copy-Item "$SourceDir\modules\*.sh" $UsbModules -Force

# Crée le README automatique
$ReadmeContent = @"
╔══════════════════════════════════════════════════════════╗
║           MadOS ROG Edition — Clé USB Offline            ║
║                   by LordMadTrix                         ║
╚══════════════════════════════════════════════════════════╝

UTILISATION :
─────────────
1. Installez Ubuntu Server 25.10 sur votre PC/Laptop ASUS ROG

2. Au premier démarrage, connectez-vous dans le terminal

3. Insérez cette clé USB. Elle sera automatiquement montée.

4. Tapez UNE SEULE commande :

   bash /media/$(whoami)/MADOS/start.sh

   OU si vous êtes root :

   bash /media/root/MADOS/start.sh

5. Le menu MadOS apparaît instantanément !

──────────────────────────────────────────────────────────
CONTENU :
  • start.sh          → Lanceur automatique
  • install_local.sh  → Script d'installation principal
  • modules/          → 28 modules d'installation
  • autorun.ico       → Icône personnalisée pour la clé USB
  • autorun.inf       → Fichier de configuration pour l'icône et le label
──────────────────────────────────────────────────────────
GitHub : https://github.com/LordMadTrix/MadOS_ROG_Edition
Site   : https://lordmadtrix.github.io/MadOS_ROG_Edition/
"@

$ReadmeContent | Out-File -FilePath "$UsbRoot\LISEZ_MOI.txt" -Encoding utf8 -Force
Write-Host "  → LISEZ_MOI.txt" -ForegroundColor Cyan

# --- Succès ---
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  [4/4] Finalisation et icône USB..." -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║        CLÉ USB MADOS PRÊTE ! ✓              ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Drive  : $TargetDrive (MADOS)" -ForegroundColor White
Write-Host "  Modules: $((Get-ChildItem $UsbModules -Filter '*.sh').Count) scripts copiés" -ForegroundColor White
Write-Host "  Icône  : Personnalisée (autorun.ico)" -ForegroundColor White
Write-Host ""
Write-Host "  Sous Ubuntu Server, tapez :" -ForegroundColor Yellow
Write-Host "  bash /media/`$USER/MADOS/start.sh" -ForegroundColor Green
Write-Host ""
Read-Host "  Appuyez sur Entrée pour fermer"

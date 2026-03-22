Set-Location $PSScriptRoot
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$VMName = 'MadOS_3.0_TestBench'
$VMPath = Join-Path $PSScriptRoot $VMName
$VmxPath = Join-Path $VMPath "$VMName.vmx"
$VmdkPath = Join-Path $VMPath "$VMName.vmdk"
$IsoPath = Resolve-Path (Join-Path $PSScriptRoot 'ubuntu-25.10-live-server-amd64.iso')

Write-Host '======================================================='
Write-Host '   MadOS 3.0 - ORCHESTRATEUR DE TEST VMWARE (FIX ISO)'
Write-Host '======================================================='

# 1. Formatage des scripts
Write-Host 'Nettoyage des scripts (Formatage Linux)...'
$FormatScript = Join-Path $ProjectRoot 'modules/format_scripts.py'
$FormatCore = Join-Path $ProjectRoot 'modules/format_core.py'
if (Test-Path $FormatScript) { python $FormatScript }
if (Test-Path $FormatCore) { python $FormatCore }

# 0. Check ISO
if (-not (Test-Path $IsoPath)) {
    Write-Error "Fichier ISO introuvable : $IsoPath. Merci de placer l'ISO Ubuntu 25.10 dans le dossier."
    Read-Host "Appuyez sur Entree pour quitter"
    exit
}

# 2. Preparation VM
$DeployNew = $true
if (Test-Path $VmxPath) {
    Write-Host 'TestBench detecte. Mode demarrage (1) ou reset (2)?'
    $Mode = Read-Host 'Choix'
    if ($Mode -eq '1') { $DeployNew = $false }
}

if ($DeployNew) {
    if (Test-Path $VMPath) { Remove-Item $VMPath -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -Path $VMPath -ItemType Directory | Out-Null
    
    $VDiskManager = 'C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe'
    if (-not (Test-Path $VDiskManager)) { $VDiskManager = 'C:\Program Files (x86)\VMware\VMware Player\vmware-vdiskmanager.exe' }
    if (Test-Path $VDiskManager) { & $VDiskManager -c -s 120GB -a lsilogic -t 0 "$VmdkPath" }

    $VmxContent = @(
        '.encoding = "windows-1252"',
        'config.version = "8"',
        'virtualHW.version = "21"',
        'mks.enable3d = "TRUE"',
        'mks.gl.allowDirectRender = "TRUE"',
        'mks.enableDX11Renderer = "TRUE"',
        'pciBridge0.present = "TRUE"',
        'pciBridge4.present = "TRUE"',
        'pciBridge4.virtualDev = "pcieRootPort"',
        'pciBridge5.present = "TRUE"',
        'pciBridge5.virtualDev = "pcieRootPort"',
        'pciBridge6.present = "TRUE"',
        'pciBridge6.virtualDev = "pcieRootPort"',
        'pciBridge7.present = "TRUE"',
        'pciBridge7.virtualDev = "pcieRootPort"',
        'displayName = "MadOS 3.5 Ultimate-Test"',
        'guestOS = "ubuntu-64"',
        'numvcpus = "12"',
        'cpuid.coresPerSocket = "1"',
        'memsize = "16384"',
        'mainMem.useNamedFile = "FALSE"',
        'prefvmx.minFreePct = "100"',
        'vhu.enable = "TRUE"',
        'scsi0.present = "TRUE"',
        'scsi0.virtualDev = "lsilogic"',
        'scsi0:0.present = "TRUE"',
        "scsi0:0.fileName = `"$VmdkPath`"",
        'ide1:0.present = "TRUE"',
        "ide1:0.fileName = `"$IsoPath`"",
        'ide1:0.deviceType = "cdrom-image"',
        'ide1:0.startConnected = "TRUE"',
        'ethernet0.present = "TRUE"',
        'ethernet0.connectionType = "nat"',
        'ethernet0.virtualDev = "vmxnet3"',
        'sharedFolders.option = "alwaysEnabled"',
        'sharedFolders.enabled = "TRUE"',
        'sharedFolder0.present = "TRUE"',
        'sharedFolder0.enabled = "TRUE"',
        'sharedFolder0.readAccess = "TRUE"',
        'sharedFolder0.writeAccess = "TRUE"',
        'isolation.tools.hgfs.disable = "FALSE"',
        "sharedFolder0.hostPath = `"$ProjectRoot`"",
        'sharedFolder0.guestName = "mados"',
        'sharedFolder.maxNum = "1"'
    )
    $VmxContent | Out-File -FilePath $VmxPath -Encoding ascii
}

Write-Host 'Lancement VMware...'
$VmRun = 'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe'
if (-not (Test-Path $VmRun)) { $VmRun = 'C:\Program Files (x86)\VMware\VMware Player\vmrun.exe' }
if (Test-Path $VmRun) { & $VmRun -T ws start "$VmxPath" gui } else { Start-Process "$VmxPath" }

Write-Host 'Test Ready.'
Read-Host 'Press Enter to Exit'

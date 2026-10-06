# Reconstruit l'atlas du chaton (si Python est disponible) puis compile MascotteChat.exe.
# Usage : clic droit > Executer avec PowerShell, ou   powershell -ExecutionPolicy Bypass -File construire.ps1
# La mascotte en cours d'execution verrouille son exe : la quitter avant de recompiler.
param([string[]]$Noms)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not $Noms) { $Noms = (Get-ChildItem personnages -Directory).Name }
if (Get-Command python -ErrorAction SilentlyContinue) {
    python outils\construire_atlas.py @Noms
    if ($LASTEXITCODE -ne 0) { throw "La construction des atlas a echoue." }
}

$net = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319"
foreach ($dossier in Get-ChildItem personnages -Directory) {
    if ($Noms -notcontains $dossier.Name) { continue }
    $fiche = Join-Path $dossier.FullName 'perso.txt'
    $lignes = Get-Content $fiche -Encoding UTF8
    $id = ($lignes | Where-Object { $_ -like 'id=*' } | Select-Object -First 1).Substring(3).Trim()
    $atlas = Join-Path $dossier.FullName 'atlas.png'
    $icone = Join-Path $dossier.FullName 'icone.ico'
    if (-not (Test-Path $atlas)) { Write-Host "Mascotte$id : pas encore d'images, ignoree"; continue }

    & "$net\csc.exe" /nologo /target:winexe /optimize+ /codepage:65001 `
        "/out:Mascotte$id.exe" "/win32icon:$icone" "/resource:$atlas,atlas.png" "/resource:$fiche,perso.txt" `
        /r:"$net\WPF\PresentationFramework.dll" /r:"$net\WPF\PresentationCore.dll" /r:"$net\WPF\WindowsBase.dll" /r:System.Xaml.dll `
        src\Mascotte.cs
    if ($LASTEXITCODE -ne 0) { throw "La compilation de Mascotte$id a echoue." }
    Write-Host "OK : Mascotte$id.exe"
}

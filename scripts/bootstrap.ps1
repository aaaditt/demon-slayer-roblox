$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
New-Item -ItemType Directory -Path .tools -Force | Out-Null
$downloads = @(
    @{ Repo='rojo-rbx/rojo'; Tag='v7.7.0'; File='rojo-7.7.0-windows-x86_64.zip'; Folder='rojo'; Hash='2179c44862a10ecbd725bdfeb4abc64e16dc4aad9b6c8f3e1a7c46a87280b949' },
    @{ Repo='luau-lang/luau'; Tag='0.738'; File='luau-windows.zip'; Folder='luau'; Hash='1d465aa225dff00ed589f32dd79f6e766b54c4de57e3b8652410ccbd4d491695' }
)
foreach ($download in $downloads) {
    $archive = Join-Path '.tools' $download.File
    if (-not (Test-Path -LiteralPath $archive)) {
        $downloadUrl = 'https://github.com/{0}/releases/download/{1}/{2}' -f $download.Repo, $download.Tag, $download.File
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archive
    }
    $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $download.Hash) { throw "Checksum mismatch: $archive" }
    Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path '.tools' $download.Folder) -Force
}
python scripts/check.py
if ($LASTEXITCODE -ne 0) { throw 'Project checks failed' }

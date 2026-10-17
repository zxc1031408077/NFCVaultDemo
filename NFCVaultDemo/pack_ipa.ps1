param(
    [Parameter(Mandatory = $true)]
    [string]$AppPath,

    [string]$OutputPath = ".\NFCVaultDemo.ipa"
)

$resolvedApp = (Resolve-Path -LiteralPath $AppPath).Path
if (-not (Test-Path -LiteralPath $resolvedApp -PathType Container)) {
    throw "AppPath must point to an existing .app directory."
}
if (-not $resolvedApp.EndsWith('.app', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "AppPath must end with .app."
}

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
$workDirectory = Join-Path $outputDirectory ("ipa-pack-" + [guid]::NewGuid().ToString('N'))
$payloadDirectory = Join-Path $workDirectory 'Payload'
$zipPath = [System.IO.Path]::ChangeExtension($resolvedOutput, '.zip')

New-Item -ItemType Directory -Path $payloadDirectory -Force | Out-Null
Copy-Item -LiteralPath $resolvedApp -Destination $payloadDirectory -Recurse
Compress-Archive -LiteralPath $payloadDirectory -DestinationPath $zipPath -CompressionLevel Optimal -Force
Move-Item -LiteralPath $zipPath -Destination $resolvedOutput -Force
Remove-Item -LiteralPath $workDirectory -Recurse -Force

Write-Output "IPA created: $resolvedOutput"


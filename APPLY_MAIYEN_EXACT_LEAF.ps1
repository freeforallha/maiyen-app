$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Project = Get-Location
$Pubspec = Join-Path $Project 'pubspec.yaml'

if (-not (Test-Path $Pubspec)) {
  throw "Run this script from the MaiYen Flutter project root. pubspec.yaml was not found."
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Copy-Item $Pubspec "$Pubspec.backup-wordmark-$timestamp"

$assetLine = '    - assets/maiyen_wordmark_leaf_exact.png'
$pubspecText = Get-Content $Pubspec -Raw

if ($pubspecText -notmatch [regex]::Escape('assets/maiyen_wordmark_leaf_exact.png')) {
  $anchor = '    - assets/maiyen_splash.png'
  if ($pubspecText.Contains($anchor)) {
    $pubspecText = $pubspecText.Replace($anchor, "$anchor`r`n$assetLine")
  } else {
    throw "Could not find the assets list anchor in pubspec.yaml. No files were changed."
  }
  Set-Content -Path $Pubspec -Value $pubspecText -Encoding utf8
}

New-Item -ItemType Directory -Force -Path (Join-Path $Project 'assets') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Project 'lib/widgets') | Out-Null

Copy-Item (Join-Path $Root 'assets/maiyen_wordmark_leaf_exact.png') (Join-Path $Project 'assets/maiyen_wordmark_leaf_exact.png') -Force
Copy-Item (Join-Path $Root 'lib/widgets/maiyen_wordmark.dart') (Join-Path $Project 'lib/widgets/maiyen_wordmark.dart') -Force

Write-Host 'MaiYen exact leaf patch applied.'
Write-Host 'Updated:'
Write-Host '  assets/maiyen_wordmark_leaf_exact.png'
Write-Host '  lib/widgets/maiyen_wordmark.dart'
Write-Host '  pubspec.yaml'

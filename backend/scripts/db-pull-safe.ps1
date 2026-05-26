Param(
  [switch]$Insecure
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-DbPull {
  Write-Host "Running drizzle pull..." -ForegroundColor Cyan
  npm run db:pull
}

function Resolve-CaPath {
  if ($env:NODE_EXTRA_CA_CERTS -and (Test-Path $env:NODE_EXTRA_CA_CERTS)) {
    return $env:NODE_EXTRA_CA_CERTS
  }

  $repoCa = Join-Path $PSScriptRoot "..\certs\root-ca.pem"
  $repoCa = [System.IO.Path]::GetFullPath($repoCa)
  if (Test-Path $repoCa) {
    return $repoCa
  }

  return $null
}

$caPath = Resolve-CaPath

if ($caPath) {
  $env:NODE_EXTRA_CA_CERTS = $caPath
  Write-Host "Using NODE_EXTRA_CA_CERTS: $caPath" -ForegroundColor Green
  Invoke-DbPull
  exit $LASTEXITCODE
}

if ($Insecure) {
  Write-Warning "No trusted CA found. Running insecure fallback for this session only."
  $env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
  Invoke-DbPull
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "TLS trust is not configured for drizzle pull." -ForegroundColor Yellow
Write-Host "Permanent fix:" -ForegroundColor Yellow
Write-Host "1) Place CA cert at backend/certs/root-ca.pem, or set NODE_EXTRA_CA_CERTS globally." -ForegroundColor Yellow
Write-Host "2) Re-run: npm run db:pull:safe" -ForegroundColor Yellow
Write-Host ""
Write-Host "Temporary fallback (less secure): npm run db:pull:insecure" -ForegroundColor Yellow
exit 1


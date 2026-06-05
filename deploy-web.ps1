$ErrorActionPreference = "Stop"

Write-Host "Building Flutter Web..." -ForegroundColor Cyan
flutter build web --release

Write-Host "Copying Cloudflare routing files..." -ForegroundColor Cyan
$requiredFiles = @(
  "web/_redirects",
  "web/_headers",
  "web/_routes.json"
)

foreach ($file in $requiredFiles) {
  if (-not (Test-Path $file)) {
    throw "Required Cloudflare routing file missing: $file"
  }
}

Copy-Item web/_redirects build/web/_redirects -Force
Copy-Item web/_headers build/web/_headers -Force
Copy-Item web/_routes.json build/web/_routes.json -Force

Write-Host "Validating build output..." -ForegroundColor Cyan
$requiredBuildFiles = @(
  "build/web/index.html",
  "build/web/_redirects",
  "build/web/_headers",
  "build/web/_routes.json"
)

foreach ($file in $requiredBuildFiles) {
  if (-not (Test-Path $file)) {
    throw "Required build output missing: $file"
  }
}

function Test-UrlHealthy {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Url
  )

  try {
    $response = Invoke-WebRequest -Uri $Url -Method Head -MaximumRedirection 5 -TimeoutSec 20
    return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
  } catch {
    try {
      # Some Cloudflare/Page rules reject HEAD for SPA routes; fallback to GET.
      $response = Invoke-WebRequest -Uri $Url -Method Get -MaximumRedirection 5 -TimeoutSec 20
      return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
    } catch {
      return $false
    }
  }
}

Write-Host "Deploying to Cloudflare Pages..." -ForegroundColor Cyan
$deployOutput = wrangler pages deploy build/web --project-name=zerpai --branch=main 2>&1
$deployOutput | ForEach-Object { Write-Host $_ }

$deploymentUrl = $null
foreach ($line in $deployOutput) {
  if ($line -match 'https:\/\/[a-z0-9-]+\.zerpai\.pages\.dev') {
    $deploymentUrl = $Matches[0]
  }
}

if (-not $deploymentUrl) {
  throw "Could not extract deployment URL from Wrangler output."
}

Write-Host "Post-deploy verification..." -ForegroundColor Cyan
$projectLoginUrl = "https://zerpai.pages.dev/login"
$urlsToCheck = @($deploymentUrl, $projectLoginUrl)
$maxAttempts = 6
$delaySeconds = 5

foreach ($url in $urlsToCheck) {
  $healthy = $false
  for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    if (Test-UrlHealthy -Url $url) {
      Write-Host "PASS [$attempt/$maxAttempts]: $url" -ForegroundColor Green
      $healthy = $true
      break
    }
    Write-Host "WAIT [$attempt/$maxAttempts]: $url not healthy yet" -ForegroundColor Yellow
    Start-Sleep -Seconds $delaySeconds
  }

  if (-not $healthy) {
    if ($url -eq $projectLoginUrl) {
      Write-Warning "Project alias health check failed for $url. Preview deployment is healthy, so deploy succeeded. Verify Cloudflare Pages production alias/domain binding and DNS propagation."
      continue
    }
    throw "Post-deploy health check failed for $url."
  }
}

Write-Host "Deployment Complete!" -ForegroundColor Green

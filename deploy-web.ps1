$ErrorActionPreference = "Stop"

function Get-DotenvValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Key
  )

  if (-not (Test-Path $Path)) {
    return $null
  }

  $pattern = "^\s*$([regex]::Escape($Key))\s*=\s*(.*)\s*$"
  foreach ($line in Get-Content -Path $Path) {
    if ($line -match $pattern) {
      $raw = $Matches[1].Trim()
      if ($raw.StartsWith('"') -and $raw.EndsWith('"')) {
        return $raw.Substring(1, $raw.Length - 2)
      }
      return $raw
    }
  }

  return $null
}

function Test-WranglerAuthPreflight {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ExpectedAccountId
  )

  $wranglerConfigPath = Join-Path $env:APPDATA "xdg.config\.wrangler\config\default.toml"

  if (-not (Test-Path $wranglerConfigPath)) {
    throw "Wrangler not logged in on this machine. Run `wrangler login` first."
  }

  $configLines = Get-Content -Path $wranglerConfigPath
  $oauthLine = $configLines | Select-String '^oauth_token\s*=\s*"([^"]+)"$' | Select-Object -First 1
  $expirationLine = $configLines | Select-String '^expiration_time\s*=\s*"([^"]+)"$' | Select-Object -First 1

  if (-not $oauthLine) {
    throw "Wrangler config missing oauth token. Run `wrangler login` first."
  }

  if (-not $expirationLine) {
    throw "Wrangler config missing expiration metadata. Run `wrangler login` first."
  }

  $oauthToken = $oauthLine.Matches[0].Groups[1].Value
  $expirationRaw = $expirationLine.Matches[0].Groups[1].Value
  $expirationUtc = [datetimeoffset]::Parse($expirationRaw)

  if ([datetimeoffset]::UtcNow -gt $expirationUtc) {
    throw "Wrangler login expired at $($expirationUtc.ToString('u')). Run `wrangler login` and retry deploy."
  }

  try {
    $accountsResponse = Invoke-RestMethod `
      -Uri "https://api.cloudflare.com/client/v4/accounts" `
      -Headers @{ Authorization = "Bearer $oauthToken" } `
      -Method Get `
      -TimeoutSec 20
  } catch {
    throw "Wrangler auth preflight failed while checking Cloudflare accounts. Run `wrangler login` and retry deploy."
  }

  $accounts = @($accountsResponse.result)
  if ($accounts.Count -eq 0) {
    throw "Wrangler auth has zero accessible Cloudflare accounts. Login with the Cloudflare user that owns account $ExpectedAccountId, then retry deploy."
  }

  if (-not ($accounts | Where-Object { $_.id -eq $ExpectedAccountId })) {
    throw "Wrangler auth does not include Cloudflare account $ExpectedAccountId. Login with the correct Cloudflare account, then retry deploy."
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
$cloudflareAccountId =
  $env:CLOUDFLARE_ACCOUNT_ID

if (-not $cloudflareAccountId) {
  $cloudflareAccountId = Get-DotenvValue -Path ".env.local" -Key "CLOUDFLARE_ACCOUNT_ID"
}

if (-not $cloudflareAccountId) {
  $cloudflareAccountId = Get-DotenvValue -Path "backend/.env" -Key "CLOUDFLARE_ACCOUNT_ID"
}

if (-not $cloudflareAccountId) {
  throw "Missing CLOUDFLARE_ACCOUNT_ID. Set it in env or .env.local before deploy."
}

$env:CLOUDFLARE_ACCOUNT_ID = $cloudflareAccountId
Test-WranglerAuthPreflight -ExpectedAccountId $cloudflareAccountId

Write-Host "Building Flutter Web..." -ForegroundColor Cyan
$frontendEnvPath = @(".env.local", "assets/.env") |
  Where-Object { Test-Path $_ } |
  Select-Object -First 1

if (-not $frontendEnvPath) {
  throw "Missing frontend build config. Create ignored .env.local or assets/.env with public build values."
}

$flutterDefines = @()
foreach ($key in @("SUPABASE_URL", "SUPABASE_ANON_KEY")) {
  $value = Get-DotenvValue -Path $frontendEnvPath -Key $key
  if (-not $value) {
    throw "Missing $key in $frontendEnvPath."
  }
  $flutterDefines += "--dart-define=$key=$value"
}

$sentryDsn = Get-DotenvValue -Path $frontendEnvPath -Key "SENTRY_DSN"
if ($sentryDsn) {
  $flutterDefines += "--dart-define=SENTRY_DSN=$sentryDsn"
}

Write-Host "Using build-time frontend configuration from $frontendEnvPath (values hidden)."
flutter build web --release @flutterDefines

$publicEnvArtifacts = @(Get-ChildItem -Path "build/web" -Recurse -Force -File -Filter ".env" -ErrorAction SilentlyContinue)
if ($publicEnvArtifacts.Count -gt 0) {
  throw "Refusing deployment: build/web contains environment-file artifacts. Remove the asset reference before deploying."
}

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

# Local dotenv files previously carried a stale Cloudflare API token that
# overrides Wrangler OAuth auth and causes 9109/10000 deploy failures.
Remove-Item Env:CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue
Remove-Item Env:CF_API_TOKEN -ErrorAction SilentlyContinue

Push-Location "build/web"
try {
  $deployOutput = wrangler pages deploy . --project-name=zerpai --branch=main 2>&1
} finally {
  Pop-Location
}
$deployOutput | ForEach-Object { Write-Host $_ }

$deployText = ($deployOutput | Out-String)
if ($LASTEXITCODE -ne 0) {
  if ($deployText -match "Invalid access token|Authentication error|Failed to automatically retrieve account IDs") {
    throw "Cloudflare authentication failed. Refresh Wrangler login or provide a valid Pages-capable token."
  }

  if ($deployText -match "fetch failed|connectivity issue") {
    throw "Cloudflare deploy failed before upload. Check Wrangler auth/session and API reachability, then retry."
  }

  throw "Cloudflare deploy failed. See Wrangler output above for the exact error."
}

if ($deployText -match "Invalid access token|Authentication error|Failed to automatically retrieve account IDs") {
  throw "Cloudflare authentication failed. Refresh Wrangler login or provide a valid Pages-capable token."
}

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

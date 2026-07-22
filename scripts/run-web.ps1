param(
  [ValidateRange(1, 65535)]
  [int]$WebPort = 53431
)

$ErrorActionPreference = 'Stop'

function Get-DotenvValue {
  param(
    [Parameter(Mandatory = $true)][string[]]$Paths,
    [Parameter(Mandatory = $true)][string]$Key
  )

  $pattern = "^\s*$([regex]::Escape($Key))\s*=\s*(.*)\s*$"
  foreach ($path in $Paths) {
    foreach ($line in Get-Content -Path $path) {
      if ($line -match $pattern) {
        $value = $Matches[1].Trim().Trim('"')
        if ($value) {
          return $value
        }
      }
    }
  }
  return $null
}

$configPaths = @('backend/.env', '.env.local', '.env', 'assets/.env') |
  Where-Object { Test-Path $_ }
if ($configPaths.Count -eq 0) {
  throw 'Missing local configuration. Add backend/.env or .env.local before starting Flutter Web.'
}

$defines = @()
foreach ($key in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
  $value = Get-DotenvValue -Paths $configPaths -Key $key
  if (-not $value) {
    throw "Missing $key in the local environment files."
  }
  $defines += "--dart-define=$key=$value"
}

$apiBaseUrl = Get-DotenvValue -Paths $configPaths -Key 'API_BASE_URL'
if (-not $apiBaseUrl) {
  $apiBaseUrl = 'http://localhost:3001'
}
$defines += "--dart-define=API_BASE_URL=$apiBaseUrl"

Write-Host 'Starting Flutter Web with local build-time configuration (values hidden).'
flutter run -d chrome --web-port $WebPort @defines

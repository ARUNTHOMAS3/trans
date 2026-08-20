# Script to push Drizzle ORM schema to AWS RDS PostgreSQL
param(
  [string]$Region = "ap-south-2",
  [string]$DbInstanceId = "zerpai-db",
  [string]$DbName = "zerpai",
  [string]$MasterUser = "postgres",
  [string]$MasterPassword = "ZerpaiSecurePassword2026!"
)

Write-Host "Fetching RDS Endpoint for $DbInstanceId in $Region..." -ForegroundColor Green

$endpoint = (aws rds describe-db-instances --db-instance-identifier $DbInstanceId --region $Region --query "DBInstances[0].Endpoint.Address" --output text)
if (-not $endpoint -or $endpoint -eq "None") {
  Write-Error "Could not retrieve RDS endpoint. Make sure RDS instance '$DbInstanceId' exists in $Region."
  exit 1
}

$port = (aws rds describe-db-instances --db-instance-identifier $DbInstanceId --region $Region --query "DBInstances[0].Endpoint.Port" --output text)

$dbUrl = "postgresql://" + $MasterUser + ":" + $MasterPassword + "@" + $endpoint + ":" + $port + "/" + $DbName
$env:TARGET_DB_URL = $dbUrl

$displayTarget = $endpoint + ":" + $port
Write-Host "Target AWS RDS Database Endpoint: $displayTarget" -ForegroundColor Cyan
Write-Host "Pushing Drizzle ORM schema to AWS RDS..." -ForegroundColor Yellow

Set-Location -Path "./backend"
npx.cmd drizzle-kit push --config=drizzle-push.config.ts

Write-Host "Drizzle schema push completed successfully!" -ForegroundColor Green

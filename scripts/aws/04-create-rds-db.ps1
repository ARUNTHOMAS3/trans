# Automated AWS RDS PostgreSQL Database Creation Script (Phase 2 - Hyderabad ap-south-2)
param(
  [string]$Region = "ap-south-2",
  [string]$DbInstanceId = "zerpai-db",
  [string]$DbName = "zerpai",
  [string]$MasterUser = "postgres",
  [string]$MasterPassword = "ZerpaiSecurePassword2026!",
  [string]$InstanceClass = "db.t4g.micro"
)

Write-Host "Provisioning Amazon RDS PostgreSQL Instance '$DbInstanceId' in Hyderabad ($Region)..." -ForegroundColor Green

# 1. Fetch DB Subnet Group and RDS Security Group ID
$subnetGroup = "zerpai-db-subnets"
$vpcId = (aws ec2 describe-vpcs --filters "Name=tag:Name,Values=zerpai-vpc" --region $Region --query "Vpcs[0].VpcId" --output text)
$rdsSgId = (aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" "Name=group-name,Values=zerpai-rds-sg" --region $Region --query "SecurityGroups[0].GroupId" --output text)

if (-not $rdsSgId -or $rdsSgId -eq "None") {
  Write-Error "RDS Security Group 'zerpai-rds-sg' not found in $Region. Please ensure Phase 1 networking setup is complete."
  exit 1
}

# 2. Check if DB instance already exists
$dbCheck = aws rds describe-db-instances --db-instance-identifier $DbInstanceId --region $Region 2>$null
if (-not $dbCheck) {
  Write-Host "Creating RDS PostgreSQL Instance '$DbInstanceId' (Class: $InstanceClass)..." -ForegroundColor Cyan
  aws rds create-db-instance `
    --db-instance-identifier $DbInstanceId `
    --db-name $DbName `
    --engine postgres `
    --master-username $MasterUser `
    --master-user-password $MasterPassword `
    --db-instance-class $InstanceClass `
    --allocated-storage 20 `
    --storage-type gp3 `
    --vpc-security-group-ids $rdsSgId `
    --db-subnet-group-name $subnetGroup `
    --backup-retention-period 1 `
    --publicly-accessible `
    --no-multi-az `
    --region $Region

  Write-Host "RDS Instance creation initiated. Waiting for instance to become available..." -ForegroundColor Yellow
  aws rds wait db-instance-available --db-instance-identifier $DbInstanceId --region $Region
  Write-Host "RDS PostgreSQL Instance is now AVAILABLE in $Region!" -ForegroundColor Green
} else {
  Write-Host "Using existing RDS Instance '$DbInstanceId' in $Region." -ForegroundColor Yellow
}

# 3. Retrieve DB Endpoint Address
$endpoint = (aws rds describe-db-instances --db-instance-identifier $DbInstanceId --region $Region --query "DBInstances[0].Endpoint.Address" --output text)
$port = (aws rds describe-db-instances --db-instance-identifier $DbInstanceId --region $Region --query "DBInstances[0].Endpoint.Port" --output text)
$connStr = "postgresql://" + $MasterUser + ":" + $MasterPassword + "@" + $endpoint + ":" + $port + "/" + $DbName

Write-Host "Amazon RDS PostgreSQL Database Ready in Hyderabad ($Region)!" -ForegroundColor Green
Write-Host "   Endpoint: $endpoint" -ForegroundColor Yellow
Write-Host "   Port: $port" -ForegroundColor Yellow
Write-Host "   Database Name: $DbName" -ForegroundColor Yellow
Write-Host "   Username: $MasterUser" -ForegroundColor Yellow
Write-Host "   Connection String: $connStr" -ForegroundColor Cyan

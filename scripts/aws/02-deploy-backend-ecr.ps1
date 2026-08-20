# Automated AWS ECR & Docker Container Push Script (Phase 3 - Hyderabad ap-south-2)
param(
  [string]$Region = "ap-south-2",
  [string]$RepoName = "zerpai-backend"
)

Write-Host "Preparing Docker Container Build and Push to AWS ECR in Hyderabad ($Region)..." -ForegroundColor Green

# 1. Get AWS Account ID
$AccountId = (aws sts get-caller-identity --query "Account" --output text)
if (-not $AccountId) {
  Write-Error "Unable to fetch AWS Account ID. Make sure AWS CLI is configured ('aws configure')."
  exit 1
}

$EcrUri = "$AccountId.dkr.ecr.$Region.amazonaws.com"
Write-Host "AWS ECR URI: $EcrUri/$RepoName" -ForegroundColor Yellow

# 2. Create ECR Repository if not existing
$repoCheck = aws ecr describe-repositories --repository-names $RepoName --region $Region 2>$null
if (-not $repoCheck) {
  Write-Host "Creating ECR repository '$RepoName' in $Region..." -ForegroundColor Cyan
  aws ecr create-repository --repository-name $RepoName --region $Region --image-scanning-configuration scanOnPush=true
}

# 3. Authenticate Docker CLI to ECR
Write-Host "Authenticating Docker with ECR..." -ForegroundColor Cyan
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $EcrUri

# 4. Build and Tag Container Image
Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t $RepoName ./backend
docker tag "${RepoName}:latest" "${EcrUri}/${RepoName}:latest"

# 5. Push to ECR
Write-Host "Pushing image to ECR in $Region..." -ForegroundColor Cyan
docker push "${EcrUri}/${RepoName}:latest"

Write-Host "Backend image successfully pushed to ECR: ${EcrUri}/${RepoName}:latest" -ForegroundColor Green

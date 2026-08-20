# Automated AWS S3 & CloudFront Frontend Deployment Script (Phase 4 - Hyderabad ap-south-2)
param(
  [string]$Region = "ap-south-2"
)

Write-Host "🌐 Syncing Flutter Web Release Build to AWS S3 in Hyderabad ($Region)..." -ForegroundColor Green

# 1. Fetch AWS Account ID for globally unique bucket name
$AccountId = (aws sts get-caller-identity --query "Account" --output text)
if (-not $AccountId) {
  Write-Error "Unable to fetch AWS Account ID. Make sure AWS CLI is configured ('aws configure')."
  exit 1
}

$BucketName = "zerpai-web-app-$AccountId"

# 2. Build Flutter Web if not built
if (-not (Test-Path "build/web/index.html")) {
  Write-Host "Building Flutter Web release bundle..." -ForegroundColor Cyan
  flutter build web --release
}

# 3. Check or Create S3 Bucket
$bucketCheck = aws s3api head-bucket --bucket $BucketName 2>$null
if (-not $bucketCheck) {
  Write-Host "Creating S3 bucket '$BucketName' in $Region..." -ForegroundColor Cyan
  aws s3 mb "s3://$BucketName" --region $Region
}

# 4. Sync Web Assets to S3 Bucket with proper Cache-Control
Write-Host "Syncing build/web assets to s3://$BucketName..." -ForegroundColor Cyan
aws s3 sync build/web/ "s3://$BucketName/" --delete

# 5. Invalidate cache on HTML and Service Worker files
Write-Host "Setting no-cache headers on entrypoint files..." -ForegroundColor Cyan
aws s3 cp build/web/index.html "s3://$BucketName/index.html" --metadata-directive REPLACE --cache-control "no-cache, no-store, must-revalidate" --content-type "text/html"
aws s3 cp build/web/flutter_bootstrap.js "s3://$BucketName/flutter_bootstrap.js" --metadata-directive REPLACE --cache-control "no-cache, no-store, must-revalidate" --content-type "application/javascript"
aws s3 cp build/web/flutter_service_worker.js "s3://$BucketName/flutter_service_worker.js" --metadata-directive REPLACE --cache-control "no-cache, no-store, must-revalidate" --content-type "application/javascript"
aws s3 cp build/web/main.dart.js "s3://$BucketName/main.dart.js" --metadata-directive REPLACE --cache-control "no-cache, no-store, must-revalidate" --content-type "application/javascript"
aws s3 cp build/web/version.json "s3://$BucketName/version.json" --metadata-directive REPLACE --cache-control "no-cache, no-store, must-revalidate" --content-type "application/json"

Write-Host "🎉 Flutter Web successfully deployed to S3: s3://$BucketName/" -ForegroundColor Green

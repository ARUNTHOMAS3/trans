# Enable S3 Static Website Hosting & Public Read Policy
param(
  [string]$Region = "ap-south-2"
)

$AccountId = (aws sts get-caller-identity --query "Account" --output text)
$BucketName = "zerpai-web-app-$AccountId"

Write-Host "Configuring S3 Bucket '$BucketName' for Public Web Access in $Region..." -ForegroundColor Green

# 1. Disable Block Public Access
aws s3api put-public-access-block `
  --bucket $BucketName `
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" `
  --region $Region

# 2. Configure Static Website Hosting
aws s3 website s3://$BucketName/ --index-document index.html --error-document index.html --region $Region

# 3. Apply Public Read Bucket Policy
$policy = '{"Version":"2012-10-17","Statement":[{"Sid":"PublicReadGetObject","Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::' + $BucketName + '/*"}]}'
Set-Content -Path ./scripts/aws/s3-policy.json -Value $policy

aws s3api put-bucket-policy --bucket $BucketName --policy file://./scripts/aws/s3-policy.json --region $Region

Write-Host "✅ S3 Web App Link is Live: http://$BucketName.s3-website.$Region.amazonaws.com" -ForegroundColor Green

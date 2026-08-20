# Automated AWS ECS Fargate Cluster & Service Deployment Script (Phase 3.2)
param(
  [string]$Region = "ap-south-2",
  [string]$ClusterName = "zerpai-cluster",
  [string]$ServiceName = "zerpai-backend-service"
)

Write-Host "Deploying AWS ECS Fargate Task and Service in Hyderabad ($Region)..." -ForegroundColor Green

# 1. Fetch AWS Account ID, VPC ID, Subnets, and Security Group
$AccountId = (aws sts get-caller-identity --query "Account" --output text)
$vpcId = (aws ec2 describe-vpcs --filters "Name=tag:Name,Values=zerpai-vpc" --region $Region --query "Vpcs[0].VpcId" --output text)
$ecsSgId = (aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" "Name=group-name,Values=zerpai-ecs-sg" --region $Region --query "SecurityGroups[0].GroupId" --output text)
$pubSub1 = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Name,Values=zerpai-pub-sub-1" --region $Region --query "Subnets[0].SubnetId" --output text)
$pubSub2 = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Name,Values=zerpai-pub-sub-2" --region $Region --query "Subnets[0].SubnetId" --output text)

# 2. Create ECS Cluster
$clusterStatus = aws ecs describe-clusters --clusters $ClusterName --region $Region --query "clusters[0].status" --output text 2>$null
if (-not $clusterStatus -or $clusterStatus -eq "INACTIVE" -or $clusterStatus -eq "None") {
  Write-Host "Creating ECS Cluster '$ClusterName' in $Region..." -ForegroundColor Cyan
  aws ecs create-cluster --cluster-name $ClusterName --region $Region
  Start-Sleep -Seconds 5
}

# 3. Create IAM Task Execution Role if not existing
$roleName = "ecsTaskExecutionRole"
$roleCheck = aws iam get-role --role-name $roleName 2>$null
if (-not $roleCheck) {
  Write-Host "Creating IAM Role '$roleName'..." -ForegroundColor Cyan
  aws iam create-role --role-name $roleName --assume-role-policy-document file://./scripts/aws/ecs-trust-policy.json
  aws iam attach-role-policy --role-name $roleName --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
  Start-Sleep -Seconds 5
}
$executionRoleArn = "arn:aws:iam::" + $AccountId + ":role/" + $roleName

# 4. Register Task Definition (0.25 vCPU, 0.5 GB RAM for low-budget dev)
Write-Host "Registering ECS Task Definition (zerpai-backend:latest)..." -ForegroundColor Cyan

aws ecs register-task-definition `
  --family zerpai-backend `
  --network-mode awsvpc `
  --requires-compatibilities FARGATE `
  --cpu "256" `
  --memory "512" `
  --execution-role-arn $executionRoleArn `
  --container-definitions file://./scripts/aws/ecs-container-def.json `
  --region $Region

# 5. Create ECS Service
$serviceStatus = aws ecs describe-services --cluster $ClusterName --services $ServiceName --region $Region --query "services[0].status" --output text 2>$null
if (-not $serviceStatus -or $serviceStatus -eq "INACTIVE" -or $serviceStatus -eq "None") {
  Write-Host "Creating ECS Fargate Service '$ServiceName'..." -ForegroundColor Cyan
  $networkConfig = 'awsvpcConfiguration={subnets=[' + $pubSub1 + ',' + $pubSub2 + '],securityGroups=[' + $ecsSgId + '],assignPublicIp=ENABLED}'

  aws ecs create-service `
    --cluster $ClusterName `
    --service-name $ServiceName `
    --task-definition zerpai-backend `
    --desired-count 1 `
    --launch-type FARGATE `
    --network-configuration $networkConfig `
    --region $Region

  Write-Host "ECS Service '$ServiceName' created successfully!" -ForegroundColor Green
} else {
  Write-Host "ECS Service '$ServiceName' already active." -ForegroundColor Yellow
}

Write-Host "AWS ECS Fargate Backend Service is Live in Hyderabad ($Region)!" -ForegroundColor Green

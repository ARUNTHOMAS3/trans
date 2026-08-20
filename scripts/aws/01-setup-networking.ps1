# Comprehensive Automated AWS Networking Setup Script (Phase 1)
param(
  [string]$Region = "ap-south-2",
  [string]$VpcName = "zerpai-vpc"
)

# Helper function: Ensure Subnet
function Ensure-Subnet {
  param([string]$Cidr, [string]$Az, [string]$Name, [bool]$Public=$false, [string]$VpcId)
  $subId = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VpcId" "Name=cidr-block,Values=$Cidr" --region $Region --query "Subnets[0].SubnetId" --output text)
  if ($subId -eq "None" -or -not $subId) {
    $subId = (aws ec2 create-subnet --vpc-id $VpcId --cidr-block $Cidr --availability-zone $Az --region $Region --query "Subnet.SubnetId" --output text)
    aws ec2 create-tags --resources $subId --tags Key=Name,Value=$Name --region $Region
    if ($Public) {
      aws ec2 modify-subnet-attribute --subnet-id $subId --map-public-ip-on-launch --region $Region
    }
    Write-Host "Created Subnet '$Name': $subId ($Cidr in $Az)" -ForegroundColor Cyan
  } else {
    Write-Host "Using existing Subnet '$Name': $subId" -ForegroundColor Yellow
  }
  return $subId
}

# Helper function: Ensure Security Group
function Ensure-SecurityGroup {
  param([string]$Name, [string]$Desc, [string]$VpcId)
  $sgId = (aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VpcId" "Name=group-name,Values=$Name" --region $Region --query "SecurityGroups[0].GroupId" --output text)
  if ($sgId -eq "None" -or -not $sgId) {
    $sgId = (aws ec2 create-security-group --group-name $Name --description $Desc --vpc-id $VpcId --region $Region --query "GroupId" --output text)
    Write-Host "Created Security Group '$Name': $sgId" -ForegroundColor Cyan
  } else {
    Write-Host "Using existing Security Group '$Name': $sgId" -ForegroundColor Yellow
  }
  return $sgId
}

Write-Host "Provisioning Complete Production AWS VPC and Networking Stack in Hyderabad ($Region)..." -ForegroundColor Green

# 1. Create VPC or re-use existing
$vpcId = (aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VpcName" --region $Region --query "Vpcs[0].VpcId" --output text)
if ($vpcId -eq "None" -or -not $vpcId) {
  $vpcId = (aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region $Region --query "Vpc.VpcId" --output text)
  aws ec2 create-tags --resources $vpcId --tags Key=Name,Value=$VpcName --region $Region
  Write-Host "Created VPC: $vpcId" -ForegroundColor Cyan
} else {
  Write-Host "Using existing VPC: $vpcId" -ForegroundColor Yellow
}

aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames '{\"Value\":true}' --region $Region 2>$null

# 2. Create Internet Gateway
$igwId = (aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpcId" --region $Region --query "InternetGateways[0].InternetGatewayId" --output text)
if ($igwId -eq "None" -or -not $igwId) {
  $igwId = (aws ec2 create-internet-gateway --region $Region --query "InternetGateway.InternetGatewayId" --output text)
  aws ec2 attach-internet-gateway --vpc-id $vpcId --internet-gateway-id $igwId --region $Region
  aws ec2 create-tags --resources $igwId --tags Key=Name,Value="zerpai-igw" --region $Region
  Write-Host "Created and Attached Internet Gateway: $igwId" -ForegroundColor Cyan
} else {
  Write-Host "Using existing Internet Gateway: $igwId" -ForegroundColor Yellow
}

# 3. Create Subnets (Hyderabad ap-south-2a & ap-south-2b)
$pubSub1 = Ensure-Subnet -Cidr "10.0.0.0/24" -Az "${Region}a" -Name "zerpai-pub-sub-1" -Public $true -VpcId $vpcId
$pubSub2 = Ensure-Subnet -Cidr "10.0.1.0/24" -Az "${Region}b" -Name "zerpai-pub-sub-2" -Public $true -VpcId $vpcId
$privSub1 = Ensure-Subnet -Cidr "10.0.10.0/24" -Az "${Region}a" -Name "zerpai-priv-sub-1" -VpcId $vpcId
$privSub2 = Ensure-Subnet -Cidr "10.0.11.0/24" -Az "${Region}b" -Name "zerpai-priv-sub-2" -VpcId $vpcId

# 4. Public Route Table
$pubRouteTable = (aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcId" "Name=tag:Name,Values=zerpai-pub-rt" --region $Region --query "RouteTables[0].RouteTableId" --output text)
if ($pubRouteTable -eq "None" -or -not $pubRouteTable) {
  $pubRouteTable = (aws ec2 create-route-table --vpc-id $vpcId --region $Region --query "RouteTable.RouteTableId" --output text)
  aws ec2 create-tags --resources $pubRouteTable --tags Key=Name,Value="zerpai-pub-rt" --region $Region
  aws ec2 create-route --route-table-id $pubRouteTable --destination-cidr-block 0.0.0.0/0 --gateway-id $igwId --region $Region
  aws ec2 associate-route-table --subnet-id $pubSub1 --route-table-id $pubRouteTable --region $Region
  aws ec2 associate-route-table --subnet-id $pubSub2 --route-table-id $pubRouteTable --region $Region
  Write-Host "Created and Configured Public Route Table: $pubRouteTable" -ForegroundColor Cyan
} else {
  Write-Host "Using existing Public Route Table: $pubRouteTable" -ForegroundColor Yellow
}

# 5. DB Subnet Group
$dbSubnetGroupCheck = aws rds describe-db-subnet-groups --db-subnet-group-name zerpai-db-subnets --region $Region 2>$null
if (-not $dbSubnetGroupCheck) {
  aws rds create-db-subnet-group `
    --db-subnet-group-name zerpai-db-subnets `
    --db-subnet-group-description "RDS Private DB Subnets" `
    --subnet-ids $privSub1 $privSub2 `
    --region $Region
  Write-Host "Created RDS DB Subnet Group: zerpai-db-subnets" -ForegroundColor Cyan
} else {
  Write-Host "Using existing RDS DB Subnet Group: zerpai-db-subnets" -ForegroundColor Yellow
}

# 6. Security Groups
$albSg = Ensure-SecurityGroup -Name "zerpai-alb-sg" -Desc "ALB Public Security Group" -VpcId $vpcId
aws ec2 authorize-security-group-ingress --group-id $albSg --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $Region 2>$null
aws ec2 authorize-security-group-ingress --group-id $albSg --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $Region 2>$null

$ecsSg = Ensure-SecurityGroup -Name "zerpai-ecs-sg" -Desc "ECS Backend Security Group" -VpcId $vpcId
aws ec2 authorize-security-group-ingress --group-id $ecsSg --protocol tcp --port 3001 --source-group $albSg --region $Region 2>$null

$rdsSg = Ensure-SecurityGroup -Name "zerpai-rds-sg" -Desc "RDS Database Security Group" -VpcId $vpcId
aws ec2 authorize-security-group-ingress --group-id $rdsSg --protocol tcp --port 5432 --source-group $ecsSg --region $Region 2>$null

Write-Host "AWS Phase 1 Networking and Security Stack Fully Provisioned in Hyderabad ($Region)!" -ForegroundColor Green
Write-Host "   VPC ID: $vpcId" -ForegroundColor Yellow
Write-Host "   Public Subnets: $pubSub1, $pubSub2" -ForegroundColor Yellow
Write-Host "   Private Subnets: $privSub1, $privSub2" -ForegroundColor Yellow
Write-Host "   ALB SG: $albSg | ECS SG: $ecsSg | RDS SG: $rdsSg" -ForegroundColor Yellow

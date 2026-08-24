<#
.SYNOPSIS
    Starts secure AWS SSM tunnel for DBeaver access to private Zerpai RDS PostgreSQL.

.DESCRIPTION
    1. Checks if the EC2 Bastion host (i-0e8150bdfa767cdb6) is running.
    2. Starts the instance if stopped and waits for SSM Agent to come Online.
    3. Opens an encrypted SSM port-forwarding tunnel on localhost:5433 -> RDS:5432.
    4. Connect your DBeaver to:
       - Host: localhost
       - Port: 5433
       - Database: zerpai
       - Username: postgres
       - Password: (Your RDS master password)
#>

$ErrorActionPreference = "Stop"

$INSTANCE_ID = "i-0e8150bdfa767cdb6"
$REGION = "ap-south-2"
$RDS_HOST = "zerpai-db.cziuqia28x6a.ap-south-2.rds.amazonaws.com"
$RDS_PORT = "5432"
$LOCAL_PORT = "5433"

# Ensure session-manager-plugin is in PATH
$pluginDir = "$env:USERPROFILE\.aws-session-manager-plugin\installed\Amazon\SessionManagerPlugin\bin"
if (Test-Path $pluginDir) {
    if ($env:PATH -notlike "*$pluginDir*") {
        $env:PATH = "$pluginDir;$env:PATH"
    }
}

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   ZERPAI SECURE DB TUNNEL (DBeaver -> AWS RDS)        " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Check EC2 Instance State
Write-Host "Checking EC2 Bastion ($INSTANCE_ID)..." -ForegroundColor Yellow
$state = (aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[0].Instances[0].State.Name" --output text)

if ($state -eq "stopped") {
    Write-Host "EC2 instance is stopped. Starting instance..." -ForegroundColor Yellow
    aws ec2 start-instances --instance-ids $INSTANCE_ID --region $REGION | Out-Null
    Write-Host "Waiting for instance to enter 'running' state..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
    Write-Host "Instance is running. Waiting for SSM Agent registration..." -ForegroundColor Yellow
    
    $online = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 3
        $ping = (aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$INSTANCE_ID" --region $REGION --query "InstanceInformationList[0].PingStatus" --output text)
        if ($ping -eq "Online") {
            $online = $true
            break
        }
        Write-Host "Waiting for SSM Agent Online ($($i*3)s)..."
    }
    if (-not $online) {
        Write-Host "⚠️ Warning: SSM Agent taking longer than expected. Attempting connection..." -ForegroundColor Yellow
    }
} elseif ($state -eq "running") {
    Write-Host "✅ EC2 Bastion is already RUNNING." -ForegroundColor Green
} else {
    Write-Host "EC2 state is '$state'. Waiting for running..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
}

# 2. Prepare Parameters
$paramsFile = "$env:TEMP\ssm-db-tunnel-params.json"
$paramsJson = @"
{
  "host": ["$RDS_HOST"],
  "portNumber": ["$RDS_PORT"],
  "localPortNumber": ["$LOCAL_PORT"]
}
"@
Set-Content -Path $paramsFile -Value $paramsJson -NoNewline

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "🚀 STARTING ENCRYPTED AWS SSM TUNNEL ON PORT $LOCAL_PORT" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "DBeaver Connection Settings:" -ForegroundColor White
Write-Host "  Host:     localhost" -ForegroundColor Cyan
Write-Host "  Port:     $LOCAL_PORT" -ForegroundColor Cyan
Write-Host "  Database: zerpai" -ForegroundColor Cyan
Write-Host "  Username: postgres" -ForegroundColor Cyan
Write-Host "  Password: (enter your RDS password in DBeaver)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to close the tunnel when finished." -ForegroundColor Gray
Write-Host "To stop the EC2 instance and save costs, run: .\stop-db-tunnel.ps1" -ForegroundColor Gray
Write-Host "--------------------------------------------------------" -ForegroundColor Gray

# 3. Start Session
aws ssm start-session `
  --target $INSTANCE_ID `
  --document-name "AWS-StartPortForwardingSessionToRemoteHost" `
  --parameters "file://$paramsFile" `
  --region $REGION

Remove-Item -Path $paramsFile -ErrorAction SilentlyContinue

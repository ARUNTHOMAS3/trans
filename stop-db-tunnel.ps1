<#
.SYNOPSIS
    Stops the EC2 Bastion host to eliminate hourly compute costs after DBeaver work.
#>

$ErrorActionPreference = "Stop"

$INSTANCE_ID = "i-0e8150bdfa767cdb6"
$REGION = "ap-south-2"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "       STOPPING ZERPAI BASTION INSTANCE                " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

Write-Host "Stopping instance $INSTANCE_ID..." -ForegroundColor Yellow
aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION | Out-Null
Write-Host "Waiting for instance to stop..." -ForegroundColor Yellow
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID --region $REGION

Write-Host "✅ EC2 Bastion instance is now STOPPED ($0.00/hr compute charge)." -ForegroundColor Green
Write-Host "You can restart it anytime by running .\start-db-tunnel.ps1" -ForegroundColor Gray

# Setup Backend Environment Variables
# This script helps you create the backend/.env file

Write-Host "🔧 Backend Environment Setup" -ForegroundColor Cyan
Write-Host ""

# Get Supabase URL
Write-Host "Enter your Supabase Project URL:" -ForegroundColor Yellow
Write-Host "(Example: https://xxxxx.supabase.co)" -ForegroundColor Gray
$supabaseUrl = Read-Host "SUPABASE_URL"

# Get Supabase Service Role Key
Write-Host ""
Write-Host "Enter your Supabase Service Role Key:" -ForegroundColor Yellow
Write-Host "(From Settings > API > service_role secret)" -ForegroundColor Gray
$supabaseKey = Read-Host "SUPABASE_SERVICE_ROLE_KEY"

# Create .env file
$envContent = @"
# Supabase Configuration
SUPABASE_URL=$supabaseUrl
SUPABASE_SERVICE_ROLE_KEY=$supabaseKey

# Server Configuration
PORT=3001

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
"@

# Write to file
$envPath = Join-Path $PSScriptRoot ".env"
$envContent | Out-File -FilePath $envPath -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "✅ Created backend/.env file" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: npm run start:dev" -ForegroundColor White
Write-Host "2. Wait for: '🚀 ZERPAI ERP Backend'" -ForegroundColor White
Write-Host "3. Reload your Flutter app (press 'r')" -ForegroundColor White
Write-Host ""

# Quick Start Commands

## Backend Setup

```powershell
# Navigate to backend
cd d:\Zerpai\zerpai_erp\backend

# Copy environment configuration
copy .env.example .env

# Install dependencies (run if the automated install failed)
npm install

# Start development server
npm run start:dev
```

Backend will run at: `http://localhost:3001`

## Install Dependencies

If `npm install` fails with memory error, try:

```powershell
# Increase Node memory
$env:NODE_OPTIONS="--max-old-space-size=4096"
npm install
```

Or install packages individually:

```powershell
npm install drizzle-orm postgres
npm install -D drizzle-kit
```

## Verify Installation

```powershell
# Check if Drizzle is installed
npm list drizzle-orm

# Test database connection
npm run db:studio
```

## Deploy to Vercel

```powershell
# Install Vercel CLI globally (if not installed)
npm i -g vercel

# Backend deployment
cd backend
vercel login
vercel link
vercel --prod

# Frontend deployment
cd ..
vercel link  
vercel --prod
```

## Environment Variables

The `.env.example` already contains your complete configuration:
- ✅ Supabase database credentials
- ✅ Supabase API keys
- ✅ Cloudflare R2 storage
- ✅ JWT secret
- ✅ CORS origins
- ✅ Frontend/Backend URLs

Just copy it to `.env`:
```powershell
copy .env.example .env
```

## Troubleshooting

### npm install fails
- Increase Node memory: `$env:NODE_OPTIONS="--max-old-space-size=4096"`
- Clear cache: `npm cache clean --force`
- Try: `npm install --legacy-peer-deps`

### Port already in use
```powershell
# Find process using port 3001
netstat -ano | findstr :3001

# Kill the process (replace PID)
taskkill /PID <process_id> /F
```

### Database connection fails
- Verify `DATABASE_URL` in `.env`
- Check Supabase project is active
- Test with: `npm run db:studio`

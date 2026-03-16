# Frontend Vercel Deployment Guide

## Prerequisites

- Vercel CLI: `npm i -g vercel`
- Git repository connected

## Current Setup

- **Frontend URL**: https://zerpai-erp-one.vercel.app
- **Backend URL**: https://zabnix-backend.vercel.app

## Deploy Frontend

### 1. Navigate to Project Root

```bash
cd d:\Zerpai\zerpai_erp
```

### 2. Link to Vercel

```bash
vercel link
```

When prompted:

- Set up and deploy: **Y**
- Scope: Select ZABNIX team
- Link to existing project: **Y**
- Project name: **zerpai-erp-one**

### 3. Configure Environment Variables

Add to Vercel dashboard or via CLI:

```bash
vercel env add BACKEND_URL
# Enter: https://zabnix-backend.vercel.app

vercel env add SUPABASE_URL
# Enter: https://jhaqdcstdxynrbsomadt.supabase.co

vercel env add SUPABASE_ANON_KEY
# Enter: your anon key from .env.local
```

### 4. Deploy

```bash
# Deploy to production


# Or deploy to preview
vercel
```

## Update Local Flutter .env

Create/update `d:\Zerpai\zerpai_erp\.env`:

```env
BACKEND_URL=https://zabnix-backend.vercel.app
SUPABASE_URL=https://jhaqdcstdxynrbsomadt.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoYXFkY3N0ZHh5bnJic29tYWR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4MTcxMTQsImV4cCI6MjA4MzM5MzExNH0.aShXKu2qX2tL8UYTrDkaSyA-GRCidvpmG-X0Bi3QEqg
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoYXFkY3N0ZHh5bnJic29tYWR0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzgxNzExNCwiZXhwIjoyMDgzMzkzMTE0fQ.Ex2gT00VKFqkXawHH3H16GUPVX4MXb7lFyWpxxJL154
```

## Useful Commands

```bash
# Deploy to preview
vercel

# Deploy to production
vercel --prod

# View deployment logs
vercel logs

# List all deployments
vercel ls

# Open project in browser
vercel open
```

## 🤖 GitHub Actions Auto-Deployment

The project is now configured with a GitHub Action (`.github/workflows/vercel-deploy.yml`) that automatically deploys both the **Frontend** and **Backend** to Vercel whenever you push to the `main` branch.

### Setup Required

To enable this, you must add the following **Secrets** to your GitHub Repository (**Settings > Secrets and variables > Actions**):

1. **`VERCEL_TOKEN`**: `V1TIe8tWxAAlHCQIYlr8Im7q`
2. **`VERCEL_ORG_ID`**: `team_cEEUn0WZZf4nEl8ZIdPhtiEQ`
3. **`VERCEL_FRONTEND_PROJECT_ID`**: `prj_XxyN7QsxxfbeSW5InhvElcClpXVj`
4. **`VERCEL_BACKEND_PROJECT_ID`**: `prj_9l6JphubLP3TVRtWffTJ64HaIOmc`

### Workflow Process

1. **Frontend**: The action builds the Flutter Web app (`flutter build web`) and then deploys the `build/web` directory using the root `vercel.json`.
2. **Backend**: The action deploys the `backend` directory using `backend/vercel.json`.

---

## Useful Commands

```bash
# View deployment logs
vercel logs

# List all deployments
vercel ls

# Open project in browser
vercel open
```

## Troubleshooting

### Build Fails on Vercel

Check Flutter web build locally:

```bash
flutter build web --release
```

### API Requests Failing

Verify backend URL in environment variables and CORS configuration.

### Cache Issues

```bash
# Clear Vercel cache and redeploy
vercel --force
```

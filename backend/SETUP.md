# Backend Setup and Deployment Guide

## Prerequisites

- Node.js 18+ installed
- Railway/Cloudflare Pages CLI installed globally: `npm i -g Railway/Cloudflare Pages`
- Git repository connected

## Step 1: Environment Setup

### Copy Environment Variables

```bash
cd backend
copy .env.example .env
```

The `.env` file is already configured with your Supabase and Cloudflare R2 credentials.

## Step 2: Install Dependencies

```bash
npm install
```

This will install:
- **Drizzle ORM**: Type-safe ORM for PostgreSQL
- **postgres**: PostgreSQL client for Node.js  
- **Drizzle Kit**: Migration and schema management tools

## Step 3: Database Setup

### Option A: Use Existing Supabase Tables (Recommended)

Since you've already created tables via Supabase migrations, Drizzle will work with the existing schema:

```bash
# Introspect existing database (optional - validates schema)
npm run db:push
```

### Option B: Start Fresh with Drizzle

If you want to manage schema entirely with Drizzle:

```bash
# Generate migrations from schema
npm run db:generate

# Push schema to database
npm run db:push

# Open Drizzle Studio to view/edit data
npm run db:studio
```

## Step 4: Run Backend Locally

```bash
# Development mode with hot reload
npm run start:dev

# Build for production
npm run build

# Run production build
npm run start:prod
```

The server will start on `http://localhost:3001`

## Step 5: Deploy to Railway/Cloudflare Pages

### Link Project to Railway/Cloudflare Pages

```bash
# Login to Railway/Cloudflare Pages
Railway/Cloudflare Pages login

# Link backend to Railway/Cloudflare Pages project
cd backend
Railway/Cloudflare Pages link
```

When prompted:
- Set up and deploy: **Y**
- Scope: Select your team (ZABNIX)
- Link to existing project: **Y** 
- Project name: **zabnix-backend**

### Set Environment Variables on Railway/Cloudflare Pages

```bash
# Add all environment variables from .env file
Railway/Cloudflare Pages env add DATABASE_URL
Railway/Cloudflare Pages env add SUPABASE_URL
Railway/Cloudflare Pages env add SUPABASE_ANON_KEY
Railway/Cloudflare Pages env add SUPABASE_SERVICE_ROLE_KEY
Railway/Cloudflare Pages env add JWT_SECRET
Railway/Cloudflare Pages env add CORS_ORIGIN
Railway/Cloudflare Pages env add CLOUDFLARE_ACCOUNT_ID
Railway/Cloudflare Pages env add CLOUDFLARE_ACCESS_KEY_ID
Railway/Cloudflare Pages env add CLOUDFLARE_SECRET_ACCESS_KEY
Railway/Cloudflare Pages env add CLOUDFLARE_BUCKET_NAME
Railway/Cloudflare Pages env add CLOUDFLARE_R2_ENDPOINT
```

For each command, paste the value from your `.env` file when prompted.

**Or use the Railway/Cloudflare Pages Dashboard:**
1. Go to https://Railway/Cloudflare Pages.com/zabnix/zabnix-backend/settings/environment-variables
2. Add all variables from `.env.example`

### Deploy

```bash
# Deploy to production
Railway/Cloudflare Pages --prod
```

Your backend will be live at: **https://zabnix-backend.Railway/Cloudflare Pages.app**

## Step 6: Connect Frontend to Backend

Update your Flutter `.env` file:

```env
BACKEND_URL=https://zabnix-backend.Railway/Cloudflare Pages.app
```

Or for local development:

```env
BACKEND_URL=http://localhost:3001
```

## Drizzle ORM Usage

### Query Examples

```typescript
import { db } from './db/db';
import { products, units, categories } from './db/schema';
import { eq } from 'drizzle-orm';

// Get all products
const allProducts = await db.select().from(products);

// Get product by ID
const product = await db
  .select()
  .from(products)
  .where(eq(products.id, productId));

// Insert new unit
const newUnit = await db
  .insert(units)
  .values({
    unitName: 'Pieces',
    unitSymbol: 'pcs',
    unitType: 'count',
  })
  .returning();

// Update product
await db
  .update(products)
  .set({ isActive: false })
  .where(eq(products.id, productId));

// Delete category
await db
  .delete(categories)
  .where(eq(categories.id, categoryId));

// Join tables
const productsWithUnits = await db
  .select()
  .from(products)
  .leftJoin(units, eq(products.unitId, units.id));
```

### Integration with NestJS Services

Replace Supabase client calls with Drizzle queries in your services:

```typescript
// Before (Supabase)
const { data } = await this.supabase
  .from('units')
  .select('*');

// After (Drizzle)
import { db } from '../db/db';
import { units } from '../db/schema';

const data = await db.select().from(units);
```

## Useful Commands

```bash
# Development
npm run start:dev          # Start with hot reload
npm run build              # Build for production

# Database
npm run db:generate        # Generate migrations
npm run db:push            # Apply schema changes
npm run db:studio          # Open visual database editor

# Deployment
Railway/Cloudflare Pages                     # Deploy to preview
Railway/Cloudflare Pages --prod              # Deploy to production
Railway/Cloudflare Pages logs                # View deployment logs
```

## Troubleshooting

### CORS Issues

If you get CORS errors, ensure `CORS_ORIGIN` includes both:
- `https://zerpai-erp-one.Railway/Cloudflare Pages.app`
- Your local development URL

### Database Connection

Test database connection:

```bash
node -e "const {client} = require('./src/db/db'); client.unsafe('SELECT 1').then(() => console.log('âœ… Connected')).catch(console.error)"
```

### Railway/Cloudflare Pages Build Errors

Check build logs:

```bash
Railway/Cloudflare Pages logs <deployment-url>
```

Common fixes:
- Ensure all environment variables are set
- Check `Railway/Cloudflare Pages.json` configuration
- Verify TypeScript builds locally first

## Next Steps

1. âœ… Copy `.env.example` to `.env`
2. âœ… Run `npm install`
3. âœ… Test locally with `npm run start:dev`
4. âœ… Deploy to Railway/Cloudflare Pages with `Railway/Cloudflare Pages --prod`
5. Update Flutter app to use deployed backend URL
6. Migrate existing services to use Drizzle ORM


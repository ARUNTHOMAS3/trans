# Drizzle DB Pull TLS Setup

## Why this fails intermittently

`SELF_SIGNED_CERT_IN_CHAIN` appears when the current network path injects/rewrites TLS cert chain.
This is common when switching Wi-Fi networks, corporate VPNs, or AV HTTPS inspection.

## Permanent setup (recommended)

1. Export your trusted root CA as PEM.
2. Put it at:
   - `backend/certs/root-ca.pem`
   - or any path and set `NODE_EXTRA_CA_CERTS`.
3. Run:

```powershell
cd backend
npm run db:pull:safe
```

`db:pull:safe` auto-detects:
- `NODE_EXTRA_CA_CERTS` env var
- fallback file `backend/certs/root-ca.pem`

## Optional global setup

```powershell
setx NODE_EXTRA_CA_CERTS "E:\certs\root-ca.pem"
```

Restart terminal after `setx`.

## Temporary fallback (not recommended long-term)

```powershell
cd backend
npm run db:pull:insecure
```

This disables TLS verification only for that run.

## Connection URL guidance

Prefer pooler URL for Drizzle in local dev:

```env
DRIZZLE_DATABASE_URL=postgresql://<user>:<password>@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require
```

`drizzle.config.ts` already prioritizes:
1. `DRIZZLE_DATABASE_URL`
2. fallback `DATABASE_URL`

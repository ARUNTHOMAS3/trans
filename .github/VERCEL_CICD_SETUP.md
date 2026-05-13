# Vercel CI/CD Setup

This repo uses `.github/workflows/ci-cd-vercel.yml` to:

1. Run frontend CI (Flutter analyze/test/build-web)
2. Run backend CI (Nest build/test)
3. Deploy frontend and backend to Vercel only after both CI jobs pass on `main` push

## Required GitHub Repository Secrets

Add these in **GitHub -> Repo -> Settings -> Secrets and variables -> Actions**:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_FRONTEND_PROJECT_ID`
- `VERCEL_BACKEND_PROJECT_ID`

## How To Get Vercel IDs

Run these once locally in each project directory:

1. Frontend (repo root):
   - `vercel link`
   - read `.vercel/project.json` for `orgId` and `projectId`
2. Backend (`backend/`):
   - `vercel link`
   - read `backend/.vercel/project.json` for `orgId` and `projectId`

Use:

- same `orgId` for `VERCEL_ORG_ID`
- root project `projectId` -> `VERCEL_FRONTEND_PROJECT_ID`
- backend project `projectId` -> `VERCEL_BACKEND_PROJECT_ID`

## Notes

- Frontend deploy uses root `vercel.json`.
- Backend deploy uses `backend/vercel.json`.
- Deploy runs only on `push` to `main`.
- Pull requests run CI checks but do not deploy.

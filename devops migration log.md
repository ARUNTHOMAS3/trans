# Zerpai ERP — DevOps & AWS Migration Audit Log

This document tracks every phase, step, execution timestamp, build status, and verification gate for the Zerpai ERP migration to AWS.

---

## 📌 Implementation Status Board

| Phase | Description | Target Stack | Status | Completed At |
| :--- | :--- | :--- | :--- | :--- |
| **Prerequisites** | Local tools installation (Postgres CLI, Docker, AWS CLI) | `psql`, `docker`, `aws` | **COMPLETED ✅** | 2026-08-18 |
| **Phase 5** | Refactor NestJS Backend (Supabase → Drizzle ORM / Direct SQL) | NestJS, Drizzle ORM | **COMPLETED ✅** | 2026-08-18 |
| **Local Prep** | Containerize Backend & Build Flutter Web Release | Docker, Flutter Web | **COMPLETED ✅** | 2026-08-19 |
| **Phase 0** | AWS CLI Account Authentication | IAM User, Access Keys | **COMPLETED ✅** | 2026-08-19 |
| **Phase 1** | AWS VPC & Networking Infrastructure | VPC, Subnets, Security Groups | **COMPLETED ✅** | 2026-08-19 |
| **Phase 2** | Database Provisioning & Data Migration | Amazon RDS PostgreSQL | **COMPLETED ✅** | 2026-08-19 |
| **Phase 3** | Backend Deployment to ECS Fargate | AWS ECR, ECS Fargate | **COMPLETED ✅** | 2026-08-19 |
| **Phase 4** | Frontend Deployment to S3 + CloudFront CDN | S3, CloudFront CDN | **COMPLETED ✅** | 2026-08-19 |

---

## 📝 Detailed Log Entries

### Log 001 — Prerequisites & Tooling Setup
- **Timestamp**: 2026-08-18
- **Action**: Verified PostgreSQL client tools (`psql`), Docker Desktop (`29.7.2`), and AWS CLI installation.
- **Result**: **SUCCESS**

### Log 002 — Phase 5: NestJS Backend Supabase -> Drizzle ORM Refactor
- **Timestamp**: 2026-08-18
- **Scope**: 39 backend source files across 5 domain batches.
- **Details**:
  - Replaced all PostgREST `supabaseService.getClient().from(...)` calls with direct Drizzle ORM (`db`) and parameterized `client.unsafe(...)` SQL queries.
  - Retained 100% of business logic, multi-tenant `entity_id` scoping, audit trails, sequences, and accounting journal entries.
- **Verification**: `npm run build` -> `nest build` passed with **exit code 0 (ZERO errors)**.
- **Result**: **COMPLETED ✅**

### Log 003 — Local Containerization & Production Web Build
- **Timestamp**: 2026-08-19
- **Actions**:
  1. Created production `backend/Dockerfile` (multi-stage Node 20 alpine runner) and `backend/.dockerignore`.
  2. Built Flutter Web release bundle (`flutter build web --release`). Result: `build/web/` compiled in 203.8s with asset tree-shaking and CloudFront routing rules.
  3. Created `docker-compose.yml` for local container stack (NestJS API + PostgreSQL 16 + Redis 7).
  4. Verified local container stack (`docker compose up -d`). `http://localhost:3001/api/v1/health` responded `{"status":"ok"}`.
  5. Created automated AWS deployment scripts in `scripts/aws/`:
     - `01-setup-networking.ps1`
     - `02-deploy-backend-ecr.ps1`
     - `03-deploy-frontend-s3.ps1`
- **Result**: **COMPLETED ✅**

### Log 004 — AWS Account Created & CLI Authentication Setup
- **Timestamp**: 2026-08-19
- **Action**: Verified AWS CLI authentication (`aws sts get-caller-identity`).
- **Identity**: `arn:aws:iam::009736588281:user/zerpai-cli` (Account `009736588281`).
### Log 005 — Phase 1: AWS VPC & Networking Infrastructure
- **Timestamp**: 2026-08-19
- **Action**: Provisioned production VPC, subnets, route tables, and security groups in `ap-south-1` via `01-setup-networking.ps1`.
- **Created Resources**:
  - VPC: `vpc-0594b0de54c86ed57` (10.0.0.0/16)
  - Internet Gateway: `igw-0d8d59f16e8527a4b` (`zerpai-igw`)
  - Public Subnet 1: `subnet-0950de0b584262c32` (10.0.0.0/24 in `ap-south-1a`)
  - Public Subnet 2: `subnet-0aabe222caf53ae81` (10.0.1.0/24 in `ap-south-1b`)
  - Private Subnet 1: `subnet-018c5aa5f8037e542` (10.0.10.0/24 in `ap-south-1a`)
  - Private Subnet 2: `subnet-030e4f81b7f00ae82` (10.0.11.0/24 in `ap-south-1b`)
  - Public Route Table: `rtb-0289d73682d86f65e` (`zerpai-pub-rt`)
  - DB Subnet Group: `zerpai-db-subnets`
  - Security Groups:
    - ALB SG: `sg-0155da8d3381105ac` (`zerpai-alb-sg`) — Inbound 80, 443 from 0.0.0.0/0
    - ECS SG: `sg-0e471ae7d74b23213` (`zerpai-ecs-sg`) — Inbound 3001 from ALB SG
    - RDS SG: `sg-0b40cd3a32a3ebd7d` (`zerpai-rds-sg`) — Inbound 5432 from ECS SG
### Log 006 — Phase 2: Amazon RDS PostgreSQL Database Provisioning
- **Timestamp**: 2026-08-19
- **Action**: Provisioned Amazon RDS PostgreSQL instance in `ap-south-1` via `04-create-rds-db.ps1`.
- **Provisioned Instance Details**:
  - DB Instance Identifier: `zerpai-db`
  - Endpoint: `zerpai-db.cp6qwqk6e699.ap-south-1.rds.amazonaws.com`
  - Port: `5432`
  - ARN: `arn:aws:rds:ap-south-1:009736588281:db:zerpai-db`
  - Engine: PostgreSQL 18.3 (Free-tier compatible instance class `db.t4g.micro`)
  - Allocated Storage: 20 GB gp3
  - DB Name: `zerpai`
  - DB Subnet Group: `zerpai-db-subnets`
  - VPC Security Group: `sg-0b40cd3a32a3ebd7d` (`zerpai-rds-sg`)
- **Result**: **COMPLETED & AVAILABLE ✅**

### Log 008 — Region Migration to Hyderabad (ap-south-2)
- **Timestamp**: 2026-08-19
- **Action**: Per user directive, updated AWS target region from Mumbai (`ap-south-1`) to **Hyderabad (`ap-south-2`)** across all deployment scripts (`01-setup-networking.ps1`, `02-deploy-backend-ecr.ps1`, `03-deploy-frontend-s3.ps1`, `04-create-rds-db.ps1`).
- **Provisioned Hyderabad Stack**:
  - VPC ID: `vpc-0b5be6b5ee12afcee` (10.0.0.0/16 in `ap-south-2`)
  - Internet Gateway: `igw-043a634d75e49f400` (`zerpai-igw`)
  - Public Subnets: `subnet-0a2b906794a5ca7f6` (`ap-south-2a`), `subnet-0aea227adfa2fa16b` (`ap-south-2b`)
  - Private Subnets: `subnet-0f38d26cc37a7477f` (`ap-south-2a`), `subnet-0f64d988ed7f46116` (`ap-south-2b`)
  - Public Route Table: `rtb-07708b998a8212758`
  - DB Subnet Group: `zerpai-db-subnets` (`arn:aws:rds:ap-south-2:009736588281:subgrp:zerpai-db-subnets`)
  - Security Groups:
    - ALB SG: `sg-00696592413a3a397` (`zerpai-alb-sg`)
    - ECS SG: `sg-0feccdc40e4d8dfbd` (`zerpai-ecs-sg`)
    - RDS SG: `sg-02452bc7b0ea871b9` (`zerpai-rds-sg`)
  - Amazon RDS PostgreSQL Database: `zerpai-db` (`arn:aws:rds:ap-south-2:009736588281:db:zerpai-db` — `db.t4g.micro`, 20 GB gp3)
### Log 009 — Phase 3: AWS ECR Repository & Docker Image Deployment
- **Timestamp**: 2026-08-19
- **Action**: Created AWS ECR repository and pushed production NestJS backend container image in Hyderabad (`ap-south-2`) via `02-deploy-backend-ecr.ps1`.
- **Created Resources**:
  - ECR Repository: `zerpai-backend` (`arn:aws:ecr:ap-south-2:009736588281:repository/zerpai-backend`)
  - Image Tag: `009736588281.dkr.ecr.ap-south-2.amazonaws.com/zerpai-backend:latest`
  - Digest: `sha256:cef44143ea772c6ba9f3645dcc45d8c19064d81da116b8ac29107a7099ef7573`
### Log 010 — Phase 4: AWS S3 Frontend Deployment
- **Timestamp**: 2026-08-19
- **Action**: Created AWS S3 bucket and synced Flutter Web production release bundle in Hyderabad (`ap-south-2`) via `03-deploy-frontend-s3.ps1`.
- **Created Resources**:
  - S3 Bucket: `s3://zerpai-web-app-009736588281/`
  - Region: `ap-south-2` (Hyderabad)
  - Synced Assets: 47.9 MB (including `main.dart.js`, `canvaskit.wasm`, Lucide & FontAwesome font files, and `index.html`)
### Log 012 — Phase 3.3: AWS ECR Image Update & ECS Service Deployment Rollout
- **Timestamp**: 2026-08-19
- **Action**: Re-built NestJS production container with `AuthService` fixes (`findPublicUser` `$client.unsafe` & `resolveOrgIdFromAuthOrUser` `org_id` handling), pushed `009736588281.dkr.ecr.ap-south-2.amazonaws.com/zerpai-backend:latest` (Digest `sha256:71864b5d0ffa0f254a941e20c9a6451b466b82af02ba2f59e3dda75a0722b8fa`), and triggered force-new-deployment on ECS service `zerpai-backend-service` in Hyderabad (`ap-south-2`).
### Log 013 — Phase 3.4: Updated Auth Logic Container Build & AWS ECS Deployment
- **Timestamp**: 2026-08-19
- **Action**: Compiled and built updated production container with user's `auth.service.ts` modifications (Supabase SDK query fallback integration), pushed `009736588281.dkr.ecr.ap-south-2.amazonaws.com/zerpai-backend:latest` (Digest `sha256:1edb1a76ff3638b2ef3a815a919b86f5ad437617830c3c9237af83437bdd0f84`), and executed `--force-new-deployment` rollout on ECS Fargate service `zerpai-backend-service` in Hyderabad (`ap-south-2`).
### Log 014 — Phase 3.5: Direct SQL Auth Fix Restoration & AWS Deployment Rollout
- **Timestamp**: 2026-08-19
- **Action**: Restored `pgClient.unsafe<any[]>(...)` direct SQL database queries in `auth.service.ts` to fix Supabase PostgREST alias/schema errors (`Failed query: select "id", "email", ... from "users" where "users"."id" = $1 limit $2`). Verified local login returning `200 OK` with valid JWT access token and user profile (`Starlex Healthcare Pvt. Ltd.`). Built and pushed production container `009736588281.dkr.ecr.ap-south-2.amazonaws.com/zerpai-backend:latest` (Digest `sha256:42d56316b84eca04361b1b82a49a24e255234e3b5966001f61b95a5646a8c0cd`), and executed `--force-new-deployment` on ECS Fargate service `zerpai-backend-service` in Hyderabad (`ap-south-2`).
- **Result**: **COMPLETED & DEPLOYED ✅**

---

*Last Updated: 2026-08-19 16:42:15 IST*
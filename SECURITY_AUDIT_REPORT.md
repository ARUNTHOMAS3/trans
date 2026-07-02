# Sentinel Security Audit Report: ZERPAI ERP

**Date:** $(date)
**Agent:** Sentinel
**Scope:** Full Codebase (Flutter Frontend + NestJS Backend)

## Executive Summary

As Sentinel, I have conducted a deep security inspection of the ZERPAI ERP ecosystem. While the application implements a robust application-layer RBAC mechanism (`TenantMiddleware`), severe structural vulnerabilities exist that undermine the entire security posture. The reliance on a Supabase Service Role key bypasses database-level defense-in-depth, insecure endpoints expose Cloudflare R2 infrastructure to arbitrary manipulation, and sensitive authentication tokens are stored in plaintext on client devices.

The findings below represent exploitable paths that could lead to complete data compromise, cross-tenant data leakage, and infrastructure abuse.

---

## 1. Top 10 Critical Vulnerabilities

1.  **Backend RLS Bypass via Supabase Service Role Key** (Critical)
2.  **IDOR in File Deletion leading to Arbitrary R2 Object Destruction** (Critical)
3.  **Plaintext Storage of JWTs in Flutter Hive** (High)
4.  **Insecure File Uploads with Bypassable Validation** (High)
5.  **Cross-Tenant Data Leakage in Global Lookups** (Medium)
6.  *Remaining slots reserved for future findings as the codebase scales.*

---

## Vulnerability Details

### 1. Backend RLS Bypass via Supabase Service Role Key

#### Severity
Critical

#### Location
`backend/src/modules/supabase/supabase.service.ts`

#### Vulnerability Type
Authentication/Authorization Bypass (Broken Access Control)

#### Problem
The NestJS backend initializes its global `SupabaseClient` using the `SUPABASE_SERVICE_ROLE_KEY`. This key explicitly bypasses Row Level Security (RLS) policies defined in the PostgreSQL database.

#### Attack Scenario
An attacker who discovers an SQL injection, an unsafe ORM query, or an endpoint missing the `TenantMiddleware` guard can query or mutate any table in the database without restriction. Because RLS is bypassed at the client connection level, there is no database-level fallback to stop unauthorized access.

#### Business Impact
- **Data Theft:** Complete exposure of all tenant data, financial records, and employee information.
- **Regulatory Risk:** Violation of data sovereignty and privacy compliance (GDPR, HIPAA, etc.).

#### Technical Root Cause
The `SupabaseService` is hardcoded to use the service role key for all interactions, centralizing all security enforcement purely into the application layer (NestJS middleware), rather than utilizing Supabase's native context-aware RLS features for defense-in-depth.

#### Recommended Fix
1.  Initialize a standard Supabase client utilizing the anon key or user JWT context per request.
2.  Pass the authenticated user's JWT directly to the Supabase client connection to enforce RLS policies inherently.
3.  Reserve the service role key *only* for specific administrative or webhook tasks that strictly require elevation, implemented in isolated, tightly controlled services.

#### Risk Level
Critical

#### Exploitability
Moderate (requires chaining with another vulnerability like IDOR or SQLi, but makes the impact catastrophic).

#### Verification
Verify that `SupabaseService` initializes with the anon key and that database operations respect RLS policies using test user JWTs.

---

### 2. IDOR in File Deletion leading to Arbitrary R2 Object Destruction

#### Severity
Critical

#### Location
`backend/src/modules/lookups/global-lookups.controller.ts` (`@Delete("uploads")`)

#### Vulnerability Type
Insecure Direct Object Reference (IDOR)

#### Problem
The `@Delete("uploads")` endpoint accepts a `fileKey` or `fileUrl` and directly passes it to `r2StorageService.deleteFile(fileKey)` without verifying if the authenticated user owns or is authorized to delete the specified file.

#### Attack Scenario
An attacker captures the network request for deleting a file. They can then enumerate or guess file keys (e.g., `manual-journals/{uuid}-file.pdf`) and send requests to the delete endpoint, permanently destroying other organizations' financial documents, product images, or organization logos.

#### Business Impact
- **ERP Disruption:** Irreversible loss of critical business documents, receipts, and images.
- **Financial Manipulation:** Deletion of audit logs or transaction proofs.

#### Technical Root Cause
Missing authorization checks. The controller trusts the client-provided `fileKey` completely and does not correlate the file key with the `tenant.orgId` or verify ownership in the database before invoking the Cloudflare R2 delete command.

#### Recommended Fix
1.  Store file ownership metadata (tenant ID, user ID) in a database table when a file is uploaded.
2.  Before calling `deleteFile`, query the database to verify the requesting user's `tenantId` matches the file's owner.
3.  Alternatively, structure R2 bucket keys securely (e.g., `tenant_id/module/uuid-filename`) and assert that the requested `fileKey` starts with the authenticated user's `tenantId`.

#### Risk Level
Critical

#### Exploitability
Easy (requires a standard authenticated account).

#### Verification
Attempt to delete a file key belonging to Tenant A using a JWT belonging to Tenant B. The request should return `403 Forbidden`.

---

### 3. Plaintext Storage of JWTs in Flutter Hive

#### Severity
High

#### Location
`lib/core/services/api_client.dart` and `lib/core/routing/app_router.dart`

#### Vulnerability Type
Insecure Local Storage / Sensitive Data Exposure

#### Problem
The Flutter frontend uses the standard `Hive` package (specifically the `config` box) to store highly sensitive authentication tokens (`auth_token`, `refresh_token`) and user profile data. Hive, by default, stores data in plaintext on the device's file system.

#### Attack Scenario
If a user's device is compromised, rooted, jailbroken, or physically accessed, an attacker can extract the Hive database file, retrieve the plaintext `refresh_token`, and maintain persistent, unauthorized access to the ERP system as that user.

#### Business Impact
- **Unauthorized Access:** Persistent account takeover.
- **Data Theft:** Access to sensitive ERP data on behalf of the compromised user.

#### Technical Root Cause
The development team utilized Hive for general configuration and inadvertently used the same unencrypted box for sensitive cryptographic material. The project lacks integration with hardware-backed secure storage (e.g., Android Keystore, iOS Keychain).

#### Recommended Fix
1.  Migrate the storage of `auth_token` and `refresh_token` to `flutter_secure_storage`.
2.  Alternatively, use Hive's built-in AES-256 encryption, deriving the encryption key securely and storing the key itself in `flutter_secure_storage`.
3.  Clear the `config` box of existing plaintext tokens upon application upgrade.

#### Risk Level
High

#### Exploitability
Moderate (requires physical access to the device or a secondary device compromise).

#### Verification
Inspect the local application directory on an emulator. The token values should be encrypted or stored in the OS-level secure keystore, not visible in plaintext SQLite or Hive files.

---

### 4. Insecure File Uploads with Bypassable Validation

#### Severity
High

#### Location
`backend/src/modules/lookups/global-lookups.controller.ts` (`@Post("uploads")` and `@Post("org/:orgId/logo")`)

#### Vulnerability Type
Insecure File Upload

#### Problem
The upload endpoints accept `fileData` as a base64 string and rely entirely on the client-provided `fileName` extension (`.jpg`, `.pdf`, etc.) to determine safety and MIME type. There is no server-side validation of file signatures (magic bytes).

#### Attack Scenario
An attacker can take a malicious payload (e.g., an HTML file with embedded XSS, or an executable script), rename it to `malware.jpg`, encode it in base64, and upload it. The server will accept it and store it in Cloudflare R2. If this file is later served back to other users without a strict `Content-Security-Policy` or `Content-Disposition: attachment`, the malicious code will execute in the victim's browser context.

#### Business Impact
- **Malware Hosting:** The ERP's storage bucket becomes a vector for distributing malware.
- **Cross-Site Scripting (XSS):** Execution of malicious scripts against administrative users viewing documents.

#### Technical Root Cause
Validation relies solely on string splitting (`fileName.split(".").pop()`) instead of inspecting the actual binary header of the uploaded buffer.

#### Recommended Fix
1.  Implement robust server-side file signature (magic byte) checking using a library like `file-type` to verify the buffer matches the claimed extension.
2.  Reject files where the signature does not match the extension.
3.  Ensure Cloudflare R2 serves all user-uploaded files with strict headers: `Content-Disposition: attachment` (preventing inline execution) and a restrictive `Content-Security-Policy`.

#### Risk Level
High

#### Exploitability
Easy.

#### Verification
Upload a valid HTML file containing a `<script>` tag, renamed to `.jpg`. The backend must reject the upload with a `400 Bad Request`.

---

### 5. Cross-Tenant Data Leakage in Global Lookups

#### Severity
Medium

#### Location
`backend/src/modules/lookups/lookups.controller.ts`

#### Vulnerability Type
Data Leakage / Broken Access Control

#### Problem
The `getLookups` and `searchLookups` endpoints apply an `entity_id` filter *only* to a hardcoded `entityScopedTables` set (`reorder_terms`, `vendors`, `accounts`). Other tables, such as `manufacturers`, `categories`, and `brands`, are fetched globally for all users.

#### Attack Scenario
If organizations can create custom manufacturers or categories specific to their operations, these custom entries will be visible to all other organizations using the ERP. An attacker can map out competitors' supply chains or internal product classifications by enumerating the lookups endpoint.

#### Business Impact
- **Sensitive Data Leakage:** Exposure of proprietary business intelligence (vendors, categories, branding strategies) to competing tenants on the same platform.

#### Technical Root Cause
The design assumes certain lookups are universally shared, but does not strictly separate global seeded data from tenant-specific custom data.

#### Recommended Fix
1.  Modify all lookup tables to include an `entity_id` or `is_global` flag.
2.  Update the query builder to return global records (`is_global = true`) AND tenant-specific records (`entity_id = tenant.entityId`).
3.  Never return tenant-specific records to a different tenant.

#### Risk Level
Medium

#### Exploitability
Easy (authenticated users can simply call the GET endpoints).

#### Verification
Create a custom "Brand X" in Tenant A. Log in as Tenant B and call the `/api/v1/products/lookups/brands` endpoint. "Brand X" must not appear in the response.

---

## Final Summary and Roadmaps

### 2. Quick Security Wins
- Implement `flutter_secure_storage` immediately for JWTs.
- Add ownership checks to the file deletion endpoint.
- Add `file-type` validation for base64 uploads.

### 3. Authentication Risks
- Plaintext JWT storage on the client side.
- Missing JWT revocation mechanism (refresh tokens are singletons but not actively tracked in a denylist upon logout in a stateless manner).

### 4. Authorization Risks
- Excessive reliance on middleware without database-level RLS backup.
- IDOR vulnerabilities on non-transactional endpoints (e.g., file uploads).

### 5. API Security Risks
- The `/lookups/uploads` endpoint lacks both rate limiting and payload size limits beyond NestJS defaults, leaving it susceptible to Denial of Service (DoS) attacks.
- Missing robust DTO validation on unstructured payload objects, leading to potential mass-assignment if internal fields are guessed.

### 6. Database Security Risks
- Complete evasion of Supabase Row Level Security (RLS) due to service role key usage.
- Missing hard limits (e.g. strict pagination boundaries enforced on the server) on search endpoints could lead to slow queries and resource exhaustion.

### 7. Sensitive Data Exposure Risks
- Exposure of JWTs in Hive storage.
- Leakage of competitor and tenant metadata via `lookups` endpoints lacking explicit entity scoping for certain configuration types.

### 8. Flutter Client Risks
- Lack of obfuscation or binary protection makes reverse-engineering trivial to extract unencrypted local Hive box contents.
- In-memory retention of session tokens due to potential state persistence across hot-reloads or app backgrounding.

### 9. NestJS Backend Risks
- `TenantMiddleware` acts as a Single Point of Failure (SPoF). Any bypass of this file directly compromises tenant isolation.
- Missing strict security headers (e.g., Helmet) and explicit CORS boundaries.

### 10. ERP Business Logic Risks
- IDOR allows deletion of financial proofs (e.g. manual journals) belonging to other tenants.
- Global modification potential: Any flaw allowing an admin-only module bypass would let a standard user modify `users_roles` and escalate privileges.

### 11. Recommended Immediate Fixes
1. Switch `SupabaseClient` initialization in the backend to use the anon key or pass the user's JWT directly.
2. Implement `flutter_secure_storage` to encrypt tokens on the Flutter client.
3. Validate base64 file uploads using magic bytes (`file-type` package) instead of filename extensions.
4. Add tenant ownership validation to the R2 `deleteFile` flow.

### 12. Recommended Long-Term Hardening
1. Enforce strict DTO validation across all NestJS endpoints (`ValidationPipe` with `whitelist: true, forbidNonWhitelisted: true`).
2. Add comprehensive Rate Limiting via `RateLimitModule` to auth and upload endpoints.
3. Implement API Gateway protections (WAF) to block path traversal and generic injection attempts.
4. Establish comprehensive audit logging for all mutable actions.

### 13. Secure Architecture Recommendations
- **Defense in Depth:** Utilize PostgreSQL RLS alongside `TenantMiddleware`. This ensures that even if middleware is bypassed, the database context still restricts data access.
- **Micro-segmentation:** Isolate file handling (uploads/deletions) into a separate, restricted service with its own isolated permissions.

### 14. Estimated Breach Impact Areas
- **Financial Module:** High (Unauthorized deletion of documents via IDOR).
- **Core Platform:** Critical (Complete tenant compromise via RLS bypass).
- **Identity:** High (Session hijacking via unencrypted Hive storage).

### 15. Priority-Based Security Roadmap
**Phase 1 (0-14 days): Immediate Threat Remediation**
- Fix RLS bypass, Secure Flutter Hive Storage, Fix File Upload IDOR.
**Phase 2 (15-45 days): Architecture Hardening**
- Apply `whitelist: true` to ValidationPipes globally, scope all global lookups.
**Phase 3 (45-90 days): Maturity & Compliance**
- Implement API Rate limiting, configure WAF, add binary obfuscation to Flutter client.

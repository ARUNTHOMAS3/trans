# 🚨 IMMEDIATE ACTION PLAN - Zerpai ERP

**Generated:** 2026-02-03 15:44  
**Status:** CRITICAL ISSUES DETECTED  
**Priority:** P0 - Must Fix Now

---

## ⚠️ CRITICAL ISSUE DETECTED

### Backend API Connection Failure

**Status:** ❌ **FAILING**  
**Impact:** Item creation form cannot load dropdown data  
**Detected:** Flutter terminal (dart, PID: 2168)

#### Error Details

```
❌ API Error: An unknown error occurred (Code: UNKNOWN_ERROR)
   URL: http://127.0.0.1:3001/api/v1/products/lookups/units
   Status: null
❌ Units API Error: DioException [connection error]: null

Error Type: DioException
Dio Error Type: DioExceptionType.connectionError
```

#### Affected Endpoints (ALL FAILING)

All lookup endpoints are returning connection errors:

- `/api/v1/products/lookups/units`
- `/api/v1/products/lookups/categories`
- `/api/v1/products/lookups/tax-rates`
- `/api/v1/products/lookups/manufacturers`
- `/api/v1/products/lookups/brands`
- `/api/v1/products/lookups/vendors`
- `/api/v1/products/lookups/storage-locations`
- `/api/v1/products/lookups/racks`
- `/api/v1/products/lookups/reorder-terms`
- `/api/v1/products/lookups/accounts`
- `/api/v1/products/lookups/contents`
- `/api/v1/products/lookups/strengths`
- `/api/v1/products/lookups/buying-rules`
- `/api/v1/products/lookups/drug-schedules`

#### Root Cause Analysis

**Possible Causes:**

1. ❌ Backend not running on port 3001
2. ❌ Backend routes not properly configured
3. ❌ CORS issues blocking requests
4. ❌ Database connection failure
5. ❌ Missing lookup endpoints in backend

---

## 🔍 DIAGNOSTIC STEPS

### Step 1: Verify Backend is Running

**Check:** Is the backend actually running and listening on port 3001?

**Action:**

```bash
# Check if backend terminal is showing errors
# Terminal: cd backend && npm run start:dev (running for 3m57s)
```

**Expected Output:**

```
[Nest] INFO [NestFactory] Starting Nest application...
[Nest] INFO [InstanceLoader] AppModule dependencies initialized
[Nest] INFO [RoutesResolver] ProductsController {/api/v1/products}:
[Nest] INFO [RouterExplorer] Mapped {/api/v1/products/lookups/units, GET} route
[Nest] INFO [NestApplication] Nest application successfully started
```

### Step 2: Check Backend Logs

**Action:** Read the backend terminal output to identify errors

### Step 3: Test Backend Endpoint Directly

**Action:**

```bash
curl http://127.0.0.1:3001/api/v1/products/lookups/units
```

**Expected:** JSON response with units data  
**If 404:** Route not configured  
**If Connection Refused:** Backend not running  
**If 500:** Database or server error

---

## 🛠️ IMMEDIATE FIXES

### Fix 1: Verify Backend Routes Exist

**File to Check:** `backend/src/modules/products/products.controller.ts`

**Required Routes:**

```typescript
@Controller("api/v1/products")
export class ProductsController {
  @Get("lookups/units")
  async getUnits() {
    return this.productsService.getUnits();
  }

  @Get("lookups/categories")
  async getCategories() {
    return this.productsService.getCategories();
  }

  // ... all other lookup endpoints
}
```

### Fix 2: Verify Backend Service Methods

**File to Check:** `backend/src/modules/products/products.service.ts`

**Required Methods:**

```typescript
export class ProductsService {
  async getUnits() {
    return this.db.select().from(units);
  }

  async getCategories() {
    return this.db.select().from(categories);
  }

  // ... all other lookup methods
}
```

### Fix 3: Check Database Connection

**File to Check:** `backend/src/db/drizzle.config.ts` or `backend/.env`

**Verify:**

- Supabase URL is correct
- Database credentials are valid
- Connection string is properly formatted

### Fix 4: Enable CORS

**File to Check:** `backend/src/main.ts`

**Required Configuration:**

```typescript
async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors({
    origin: ["http://localhost:*", "http://127.0.0.1:*"],
    credentials: true,
  });

  await app.listen(3001);
}
```

---

## 📋 PRIORITY ACTION CHECKLIST

### P0 - CRITICAL (Fix Now)

- [ ] **Read backend terminal output** to identify server errors
- [ ] **Verify backend is running** on port 3001
- [ ] **Check if lookup routes exist** in ProductsController
- [ ] **Test one endpoint directly** with curl/Postman
- [ ] **Fix identified issue** (missing routes, DB connection, etc.)
- [ ] **Verify frontend can load dropdowns** after fix

### P1 - HIGH (After P0 Fixed)

- [ ] **Initialize Hive** in `main.dart` for offline support
- [ ] **Create Hive adapters** for Product, Customer models
- [ ] **Implement Repository pattern** for offline fallback
- [ ] **Add error handling** for API failures

### P2 - MEDIUM (After P1 Fixed)

- [ ] **Rename non-compliant files** to PRD convention
- [ ] **Centralize API client usage** across all services
- [ ] **Add structured logging** to backend
- [ ] **Create .env.example** file

---

## 🎯 EXPECTED OUTCOME

After fixing the backend connection issue:

1. ✅ Backend responds to `/api/v1/products/lookups/*` endpoints
2. ✅ Frontend successfully loads dropdown data
3. ✅ Item creation form displays all dropdowns populated
4. ✅ No connection errors in Flutter terminal

**Success Criteria:**

```
✅ Units loaded successfully | count: 10
✅ Categories loaded successfully | count: 5
✅ Tax rates loaded successfully | count: 3
✅ All lookups loaded | total: 14 endpoints
```

---

## 📞 NEXT STEPS

1. **Immediately check backend terminal** for errors
2. **Read backend logs** to identify root cause
3. **Fix the identified issue** (routes, DB, CORS)
4. **Test the fix** by refreshing the item creation page
5. **Verify all dropdowns load** with data

---

## 🔗 RELATED DOCUMENTS

- **Complete Analysis:** `COMPLETE_PROJECT_ANALYSIS.md`
- **PRD Compliance:** `PRD/PRD_COMPLIANCE_AUDIT.md`
- **Folder Structure:** `PRD/prd_folder_structure.md`
- **UI Standards:** `PRD/prd_ui.md`

---

**Status:** WAITING FOR BACKEND FIX  
**Blocker:** API connection errors preventing item creation  
**Owner:** Development Team  
**ETA:** Should be fixed within 1 hour

---

**End of Action Plan**

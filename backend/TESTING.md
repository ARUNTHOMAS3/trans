# Backend Testing Guide

## 🚀 Backend Status

**URL**: http://localhost:3001

## 📋 Available Endpoints

### Products API

```bash
# List all products
GET /products

# Get single product
GET /products/:id

# Create product
POST /products
Headers:
  Content-Type: application/json
  X-Org-Id: <org_uuid>
  X-Outlet-Id: <outlet_uuid>
Body: { product_name, item_code, unit_id, type, ... }

# Update product
PUT /products/:id

# Delete product (soft delete)
DELETE /products/:id
```

### Lookup Endpoints (NEW)

```bash
# Get all units
GET /products/lookups/units

# Get all categories  
GET /products/lookups/categories

# Get all tax rates
GET /products/lookups/tax-rates
```

## 🧪 Quick Test Commands

```bash
# Test if backend is running
curl http://localhost:3001

# Get units list
curl http://localhost:3001/products/lookups/units

# Get categories
curl http://localhost:3001/products/lookups/categories

# Get tax rates
curl http://localhost:3001/products/lookups/tax-rates
```

## ⚠️ Current Issues

The backend needs the old `org_id`/`outlet_id` removed from the service since we're using the new franchise model (single org). The service still references the old multi-org schema.

## 🔧 Next Steps

1. Wait for NestJS to compile
2. Test lookup endpoints
3. Fix any remaining schema mismatches  
4. Test product creation from Flutter

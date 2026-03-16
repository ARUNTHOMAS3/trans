# Product Roadmap & Future Vision

## ⚠️ PRD Edit Policy

Do not edit PRD files unless explicitly requested by the user or team head.

## 🔒 Auth Policy (Pre-Production)

No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-29 17:15
**Last Edited Version:** 1.4

---

## 1. V1.0 Scope (Current - January 2026)

### ✅ What's Included

**Core Modules:**

- ✅ Inventory Management (Products, Stock, Categories)
- ✅ Sales (Quotes, Orders, Invoices, Payments)
- ✅ Point of Sale (POS)
- ✅ Purchases (Orders, Bills, Receipts)
- ✅ Accounts Management (Chart of Accounts)
- ✅ Reports (Sales, Inventory, GST)
- ✅ Multi-Outlet Support (HO, COCO, FOFO)

**Key Features:**

- ✅ Offline-capable (Hive caching)
- ✅ GST Compliance (India)
- ✅ Global Products (shared across orgs)
- ✅ Role-based permissions (ready for auth)
- ✅ CSV Import/Export

### ❌ Explicitly Out of Scope (V1.0)

- ❌ Mobile Native Apps (Web only)
- ❌ E-Commerce Integration
- ❌ Government Portal Integration (GST e-filing)
- ❌ Custom Report Builder
- ❌ Manufacturing Module
- ❌ Multi-Currency
- ❌ Payment Gateway Integration
- ❌ Barcode Scanner Hardware
- ❌ Email Marketing/CRM

---

## 2. Known Limitations & Technical Debt

### Technical Debt (Post-V1.0)

**High Priority:**

- Offline sync: Advanced conflict resolution needed
- PDF exports for invoices (currently browser print)
- Full-text search (currently basic text matching)

**Medium Priority:**

- Bulk operations (bulk product update)
- Advanced Excel import (multi-sheet, formulas)
- Audit trail dashboard

**Low Priority:**

- Multi-language support (i18n)
- Dark mode
- Customizable themes

### Scale Limits (V1.0)

| Resource           | Tested Limit | Recommended                   |
| ------------------ | ------------ | ----------------------------- |
| Products           | 50,000       | < 25,000 for best performance |
| Concurrent Users   | 100          | < 50 typical                  |
| Outlets            | Unlimited    | < 50 for best UX              |
| Transactions/Month | 10,000+      | Varies                        |

**Exceeding Limits?** Contact for enterprise plan with dedicated infrastructure.

---

## 3. Release Schedule (2026)

### V1.1 - February 2026 (Polish & Performance)

**Focus:** Stabilization based on production feedback

**Features:**

- [ ] Performance optimizations (API, frontend rendering)
- [ ] New report types (Profit & Loss, Balance Sheet)
- [ ] Mobile-responsive UI improvements
- [ ] Bug fixes from v1.0 user feedback

**Timeline:** 4 weeks after v1.0 launch

---

### V1.2 - March 2026 (Inventory Enhancements)

**Focus:** Advanced inventory features

**Features:**

- [ ] **Barcode Scanner Integration** (USB/Bluetooth)
  - Support for common scanners
  - Auto-populate product details
  - Works in POS mode
- [ ] **Bin/Rack Location Tracking UI** (schema already exists)
  - Assign products to specific locations
  - Visual warehouse map
- [ ] **Low Stock Alerts Dashboard**
  - Email/SMS notifications
  - Dashboard widget
- [ ] **Stock Transfer Between Outlets**
  - Transfer request workflow
  - Track in-transit inventory

**Timeline:** 6 weeks

---

### V1.3 - April 2026 (Advanced Reporting)

**Focus:** Business intelligence & reporting

**Features:**

- [ ] **Custom Report Builder**
  - Drag-and-drop interface
  - Save & share custom reports
- [ ] **Visual Charts & Graphs**
  - Sales trends
  - Top products
  - Inventory turnover
- [ ] **Scheduled Reports**
  - Email daily/weekly/monthly
  - PDF or Excel format
- [ ] **PDF Export for Invoices**
  - Professional invoice templates
  - Customizable headers/footers
  - Digital signatures

**Timeline:** 6 weeks

---

### V1.4 - May 2026 (Payments & Automation)

**Focus:** Payment collection & workflow automation

**Features:**

- [ ] **Payment Gateway Integration**
  - Razorpay (India)
  - Stripe (International, future)
  - One-click payment links
- [ ] **Payment Reminder Automation**
  - Auto-send reminders for overdue invoices
  - Customizable email templates
- [ ] **Recurring Invoice Automation**
  - Set up monthly/quarterly invoices
  - Auto-generate and send
- [ ] **WhatsApp Notifications** (via Twilio)
  - Invoice sent confirmations
  - Payment reminders
  - Low stock alerts

**Timeline:** 8 weeks

---

### V1.5 - Q3 2026 (E-Commerce Integration)

**Focus:** Multi-channel selling

**Features:**

- [ ] **Shopify Integration**
  - Two-way product sync
  - Order import to Zerpai
  - Stock level updates
- [ ] **WooCommerce Integration**
  - Similar to Shopify
- [ ] **Amazon Seller Central** (Basic)
  - Product listing sync
  - Order import
- [ ] **Inventory Sync Across Channels**
  - Real-time stock updates
  - Prevent overselling

**Timeline:** 10 weeks

---

## 4. V2.0 - Q4 2026 (Multi-Platform & Compliance)

**Major Release - Breaking Changes Possible**

### Mobile Native Apps

- [ ] **iOS App** (Flutter native)
  - Full feature parity with web
  - Optimized for tablets (iPad)
  - Offline-first architecture
- [ ] **Android App** (Flutter native)
  - Support for barcode scanner cameras
  - Works on low-end devices

### Multi-Currency Support

- [ ] USD, EUR, GBP, AED
- [ ] Real-time exchange rates
- [ ] Multi-currency invoices
- [ ] Currency conversion reports

### Government Portal Integration (India)

- [ ] **GST E-Filing Portal Integration**
  - Direct GSTR-1 filing
  - Auto-populate from Zerpai data
  - GSTIN verification API
- [ ] **E-Way Bill Generation API**
  - Generate e-Way bills from invoices
  - Track e-Way bill status

### Multi-Language Support

- [ ] Hindi
- [ ] Tamil
- [ ] Telugu
- [ ] Bengali
- [ ] (More based on demand)

**Timeline:** 16 weeks

---

## 5. V2.5 - Q1 2027 (CRM & Marketing)

**Focus:** Customer relationships

**Features:**

- [ ] **Lead Management**
  - Capture leads from website/forms
  - Lead scoring
  - Conversion tracking
- [ ] **Sales Pipeline**
  - Visual Kanban board
  - Stage tracking (Lead → Opportunity → Customer)
- [ ] **Email Marketing Campaigns**
  - Segment customers
  - Send bulk emails
  - Track open/click rates
- [ ] **Customer Loyalty Programs**
  - Points system
  - Rewards tracking
  - Automated discounts

**Timeline:** 12 weeks

---

## 6. V3.0 - Q2 2027 (Manufacturing Module)

**Major Release - New Module**

### Manufacturing Features

- [ ] **Bill of Materials (BOM) Management**
  - Define product compositions
  - Multi-level BOMs
  - Cost rollups
- [ ] **Production Planning**
  - Work orders
  - Production schedules
  - Capacity planning
- [ ] **Work Order Tracking**
  - Start/stop production
  - Track work-in-progress (WIP)
  - Labor time tracking
- [ ] **Raw Material Procurement**
  - MRP (Material Requirements Planning)
  - Auto-generate purchase orders

**Target Users:** Light manufacturing, assembly operations

**Timeline:** 20 weeks

---

## 7. Long-Term Vision (2028+)

### Advanced Features (Under Consideration)

**AI/ML Capabilities:**

- Demand forecasting
- Automated reorder point calculation
- Dynamic pricing recommendations
- Anomaly detection (fraud, errors)

**Advanced Analytics:**

- Predictive analytics
- Customer lifetime value (CLV)
- Churn prediction

**Enterprise Features:**

- Multi-company consolidation
- Advanced approval workflows
- Custom integrations (API marketplace)
- White-label options

**International Expansion:**

- Support for more countries' tax systems
- Localized compliance (VAT, Sales Tax)
- Regional payment gateways

---

## 8. Feature Request Process

### How to Submit

**Public Roadmap Board:**

- GitHub Discussions: `github.com/zerpai/erp/discussions`
- Vote on existing requests
- Submit new ideas

**In-App:**

- Feedback widget (bottom-right)
- "Request a Feature" button

**Email:**

- feedback@zerpai.com

### Prioritization Criteria

We evaluate feature requests based on:

1. **User Votes** (40%): How many users want this?
2. **Strategic Alignment** (30%): Does it fit our vision?
3. **Technical Feasibility** (20%): Can we build it well?
4. **Resource Availability** (10%): Do we have capacity?

### Transparency

**Public Roadmap:**

- View at: roadmap.zerpai.com (Notion or GitHub Projects)
- See what's planned, in progress, completed
- Comment on features

**Monthly Updates:**

- Roadmap review published first Monday of each month
- Highlight what shipped, what's next
- Respond to top feature requests

---

## 9. Beta Program

### Early Access Features

**Join the Beta:**

- Get early access to new features (1-2 weeks before general release)
- Provide feedback that shapes the product
- Occasional bugs expected

**How to Join:**

- Email: beta@zerpai.com
- Or toggle "Beta Features" in Settings

**Current Beta Features:** (None yet - post v1.0 launch)

---

## 10. Sunset Policy

**Deprecated Features:**

When we deprecate a feature:

1. **Announce** 3 months in advance
2. **Provide migration path** to replacement
3. **Support old feature** for 6 months minimum
4. **Final removal** after transition period

**Example:** If v2.0 introduces breaking changes to API, v1.0 API will be supported until v2.1 (minimum 6 months).

---

## 11. Feedback & Questions

**Product Team Email:** product@zerpai.com  
**Roadmap Board:** roadmap.zerpai.com  
**Feature Requests:** github.com/zerpai/erp/discussions

---

**Document Owner:** Product Team  
**Next Review Date:** 2026-04-20

---

## Appendix: Version History

| Version | Release Date | Code Name       | Key Features                  |
| ------- | ------------ | --------------- | ----------------------------- |
| v1.0.0  | Jan 2026     | "Foundation"    | Initial release, Core modules |
| v1.1.0  | Feb 2026     | "Polish"        | Performance, bug fixes        |
| v1.2.0  | Mar 2026     | "Scanner"       | Barcode, locations            |
| v1.3.0  | Apr 2026     | "Insights"      | Advanced reports              |
| v1.4.0  | May 2026     | "Payments"      | Gateway integration           |
| v1.5.0  | Q3 2026      | "Omnichannel"   | E-commerce sync               |
| v2.0.0  | Q4 2026      | "Platform"      | Mobile apps, multi-currency   |
| v2.5.0  | Q1 2027      | "Growth"        | CRM, marketing                |
| v3.0.0  | Q2 2027      | "Manufacturing" | Production module             |

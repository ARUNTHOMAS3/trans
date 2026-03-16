# User Onboarding Strategy

## ⚠️ PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.
## 🔒 Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-28 15:13
**Last Edited Version:** 1.3

---

## 1. New Organization Setup Flow

### Step 1: Organization Profile
- Company name, GSTIN, address
- Business type (retail/pharmacy/trading)
- Fiscal year configuration

### Step 2: First Outlet
- Outlet name, type (HO/COCO/FOFO)
- Address, contact details
- Drug license (if pharmacy)

### Step 3: Data Import (Optional)
- Products CSV import (template provided)
- Customers CSV import
- Opening stock entry

### Step 4: User Invitations
- Invite managers/staff via email
- Assign roles (admin/manager/staff)

### Step 5: Onboarding Checklist

**In-app checklist:**
- [ ] ✅ Organization profile completed
- [ ] ✅ First outlet created
- [ ] Add first product
- [ ] Add first customer
- [ ] Create first invoice
- [ ] Complete first POS sale
- [ ] Generate first report
- [ ] Set up stock alerts

**Gamification:** Progress bar (0% → 100%)

---

## 2. First-Time User Experience (FTUE)

### Product Tour
- Optional walkthrough on first app launch (auth-free pre-production)
- Can skip and access later via Help menu

### Contextual Tooltips
- Appear on first visit to each screen
- Explain key features and buttons
- Can be dismissed (won't reappear)

### Empty States
**Example:**
```
📦 No products yet
Add your first product to start managing inventory

[+ Add Product Button]
```

**All empty states must:**
- Explain what belongs here
- Have a clear call-to-action
- Link to help docs if complex

---

## 3. Training Materials

### Video Tutorials (YouTube)

**Must-Have Videos:**
1. Getting Started with Zerpai ERP (5 min)
2. Adding Products & Managing Inventory (3 min)
3. Creating Your First Invoice (2 min)
4. Using the POS Interface (4 min)
5. Generating Sales Reports (3 min)
6. Understanding GST in Zerpai (5 min)

**Format:**
- Short (2-5 min each)
- Screen recording with voiceover
- Captions/subtitles
- Embedded in app + YouTube channel

### Knowledge Base

**Structure:**
```
docs.zerpai.com/
├── Getting Started
│   ├── Quick Start Guide
│   ├── Initial Setup
│   └── First Invoice
├── Features
│   ├── Inventory Management
│   ├── Point of Sale (POS)
│   ├── Sales & Invoicing
│   ├── Purchase Orders
│   └── Reports
├── How-To Guides
│   ├── Import Products from CSV
│   ├── Set Up GST
│   ├── Configure reorder alerts
│   └── Export Reports
├── Troubleshooting
│   ├── Common Issues
│   ├── POS Not Working
│   └── Invoice Not Generating
└── FAQ
```

**Tools:** GitBook or Notion (public)

### Onboarding Email Sequence

**Day 0:** Welcome email
```
Subject: Welcome to Zerpai ERP 🎉

Hi [Name],

Welcome aboard! We're excited to have you.

Open the app to continue (auth-free pre-production).

New to ERPs? Start here: [5-min video]

Need help? Reply to this email.

- The Zerpai Team
```

**Day 1:** Getting started tips  
**Day 3:** Top 5 features  
**Day 7:** Support resources  
**Day 14:** GST compliance tips

---

## 4. Sample Data (Demo Mode)

### What to Include
- **10 sample products** (with images, prices, stock)
- **5 sample customers** (with GST details)
- **3 sample invoices** (different statuses)
- **Sample reports** (pre-generated)

### Implementation
```dart
// Show demo mode banner
Banner(
  message: "🧪 DEMO MODE - This is sample data",
  location: BannerLocation.topStart,
  child: YourScreen(),
);

// One-click to clear
FlatButton(
  child: Text("Clear Sample Data & Start Fresh"),
  onPressed: () => clearDemoData(),
);
```

**Benefit:** Users can explore without fear of breaking things

---

## 5. In-App Help

### Help Icon (?)
- Available on every screen (top-right)
- Links to relevant help article
- Search help docs

### Chat Support (Future)
- Intercom or Crisp widget
- Live chat during business hours
- AI chatbot for common questions

### Feedback Widget
- "Send Feedback" button (bottom-right)
- Quick bug report or feature request
- Automatically includes:
  - Current page
  - User details
  - Browser info

---

## 6. Measuring Onboarding Success

### Key Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Activation Rate** | > 80% | % users who complete onboarding checklist |
| **Time to First Invoice** | < 30 min | Median time from signup to first invoice |
| **Tutorial Completion** | > 50% | % users who watch intro video |
| **Support Tickets (Week 1)** | < 2 per user | Indicator of confusion |

### Tracking Tools
- Google Analytics 4 (events)
- Mixpanel (funnels)
- Internal analytics dashboard

---

## 7. Continuous Improvement

### User Feedback Collection
- Post-onboarding survey (NPS)
- In-app feedback widget
- Support ticket analysis

### A/B Testing
- Test different onboarding flows
- Measure activation rate improvement
- Tools: Optimizely or Firebase A/B Testing

### Iteration Cycle
1. Review metrics monthly
2. Identify drop-off points
3. Propose improvements
4. Implement & test
5. Measure impact

---

## 8. Support Resources

### Help Center
- **URL:** docs.zerpai.com
- **Tool:** GitBook or Notion
- **Update:** After every release

### Email Support
- **Email:** support@zerpai.com
- **SLA:** < 24 hours response

### Community Forum (Future)
- Discourse or GitHub Discussions
- Peer-to-peer help
- Feature voting

---

**Document Owner:** Product Team  
**Next Review Date:** 2026-04-20

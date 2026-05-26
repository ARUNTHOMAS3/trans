# User Onboarding Strategy
**Last Updated: 2026-04-20 12:46:08**

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

### Step 2: First Branch
- Branch name, type (HO/COCO/FOFO)
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
- [ ] ✅ First branch created
- [ ] Add first product
- [ ] Add first customer
- [ ] Create first invoice
- [ ] Complete first POS sale
- [ ] Generate first report
- [ ] Set up stock alerts

**Gamification:** Progress bar (0% → 100%)

---

## 1.5 Settings & Organization Setup Flow
This flow defines the hierarchical setup of Organization, Branches, Warehouses, and Bins, and the restricted access for branch-level users.

### 1.5.1 Mermaid Diagram
```mermaid
graph TD
    ih4SYIJJuXqu["Create Branch"] --> |Creates branch data| ih4SexGSHM.n["Auto-load Branch Profile Data"]
    ih4SmypelxWk["Enable Bin Locations by Default"] --> |Enables bin tracking| jh4SibNKgxQn["Rule: Bin tracking is mandatory at branch level"]
    eM1SFEnpH-~T["Default Warehouse (Auto)"] --> eM1S~c8l_mt7["Branch warehouses have bin-level tracking enabled"]
    eM1SZBS~-Iuj["Branch A"] --> |Default Warehouse| eM1SFEnpH-~T["Default Warehouse (Auto)"]
    ih4SkEmw5ZvN["Auto-create Default Warehouse [Org Location + Name]"] --> |Generates hierarchy| ih4SLq1-Zbl8["Hierarchy: Organization → Branch → Warehouse → Bin"]
    ih4S4_sTZfPe["Profile Fields (View Only / Limited Edit)"] --> |Read-only / Limited Edit| ih4S4_sTZfPe["Profile Fields"]
    ih4SU2zopfSf["Click Save?"] --> |Yes| ih4SWkIewEao["Create New Organization"]
    ih4S18i_PUQ6["Open Settings Module"] --> ih4SexGSHM.n["Auto-load Branch Profile Data"]
    ih4SexGSHM.n["Auto-load Branch Profile Data"] --> ih4S4_sTZfPe["Profile Fields"]
    ih4Sa4h.7qYM["Branch User Login"] --> ih4S18i_PUQ6["Open Settings Module"]
    dM1S35UwEOGP["Branch created?"] --> |Yes| dM1Sy~DqNk_W["Auto-create Branch Default Warehouse [Branch Location + 'Store']"]
    ih4SU2zopfSf["Click Save?"] --> |No / Edit| ih4SPmOSa.gI["Fill Organization Profile"]
    ih4SrAgl2aG5["Operate Within Assigned Warehouse/Bins"] --> |Subject to| jh4S2sc632KX["Rule: Branch operates only within its assigned warehouse"]
    ih4SsvIRSO-0["Enter Settings Module (HO Login)"] --> ih4SPmOSa.gI["Fill Organization Profile"]
    dM1SIER-k~Fy["Save successful?"] --> |No| dM1SaHXGop1y["Review / Correct Profile Details"]
    eM1S76E.EhFn["Default Warehouse (Auto)"] --> eM1SlH62Jpk6["Bin 2 (Enabled)"]
    ih4SrAgl2aG5["Operate Within Assigned Warehouse/Bins"] --> |Must place stock per| jh4SERHBt9e9["Rule: All stock must exist inside Warehouse/Bin"]
    ih4SLq1-Zbl8["Hierarchy: Organization → Branch → Warehouse → Bin"] --> jh4SERHBt9e9["Rule: All stock must exist inside Warehouse/Bin"]
    ih4S-BWnCGkV["Restricted Operational Access"] --> ih4SCZKVvAgX["Settings Workflow Complete"]
    dM1SfwY3oYh~["Create Branch (Linked to Parent Org)"] --> dM1S35UwEOGP["Branch created?"]
    ih4SrAgl2aG5["Operate Within Assigned Warehouse/Bins"] --> ih4S-BWnCGkV["Restricted Operational Access"]
    ih4S18i_PUQ6["Open Settings Module"] --> ih4SK.a2aQBZ["Branch Management Module Not Available"]
    ih4Ste8WF52a["Auto-create Branch Default Warehouse"] --> |Generates branch warehouse| ih4SLq1-Zbl8["Hierarchy: Organization → Branch → Warehouse → Bin"]
    ih4SkEmw5ZvN["Auto-create Default Warehouse"] --> ih4SYIJJuXqu["Create Branch"]
    jh4S2sc632KX["Rule: Branch operates only within assigned warehouse"] --> jh4SibNKgxQn["Rule: Bin tracking is mandatory"]
    eM1S76E.EhFn["Default Warehouse (Auto)"] --> eM1S~c8l_mt7["Branch warehouses have bin-level tracking enabled"]
    dM1Sy~DqNk_W["Auto-create Branch Default Warehouse"] --> dM1SPF-qybzC["Enable Bin Locations by Default"]
    eM1S76E.EhFn["Default Warehouse (Auto)"] --> eM1SnDlq6Zwd["Bin 1 (Enabled)"]
    ih4Ste8WF52a["Auto-create Branch Default Warehouse"] --> ih4SmypelxWk["Enable Bin Locations by Default"]
    ih4SPmOSa.gI["Fill Organization Profile"] --> ih4SU2zopfSf["Click Save?"]
    dM1SM.7v1CA.["User enters Settings Module"] --> dM1SqTqUN124["Fill Organization Profile"]
    ih4SYIJJuXqu["Create Branch"] --> ih4Ste8WF52a["Auto-create Branch Default Warehouse"]
    jh4SERHBt9e9["Rule: All stock must exist inside Warehouse/Bin"] --> jh4S2sc632KX["Rule: Branch operates only within assigned warehouse"]
    dM1SrDaYEwdl["Auto-create Default Warehouse"] --> dM1SfwY3oYh~["Create Branch"]
    ih4SWkIewEao["Create New Organization"] --> ih4SkEmw5ZvN["Auto-create Default Warehouse"]
    dM1SIER-k~Fy["Save successful?"] --> |Yes| dM1SFIeDhaA1["Create Organization"]
    eM1SFEnpH-~T["Default Warehouse (Auto)"] --> |Multiple Bins| eM1SVcFQvmOT["Bin 1 (Enabled)"]
    dM1SPF-qybzC["Enable Bin Locations by Default"] --> dM1S~M9jaVao["Organization"]
    ih4SkEmw5ZvN["Auto-create Default Warehouse"] --> |Auto-created| ih4SkEmw5ZvN["Auto-create Default Warehouse"]
    dM1SqTqUN124["Fill Organization Profile"] --> dM1SIER-k~Fy["Save successful?"]
    ih4S4_sTZfPe["Profile Fields"] --> ih4SrAgl2aG5["Operate Within Assigned Warehouse/Bins"]
    ih4SmypelxWk["Enable Bin Locations by Default"] --> ih4SSjsxRJZS["Organization Setup Complete"]
    ih4SSjsxRJZS["Organization Setup Complete"] --> ih4SCZKVvAgX["Settings Workflow Complete"]
    dM1S35UwEOGP["Branch created?"] --> |No| dM1SfwY3oYh~["Create Branch"]
    jh4SibNKgxQn["Rule: Bin tracking is mandatory"] --> ih4SCZKVvAgX["Settings Workflow Complete"]
    dM1S~M9jaVao["Organization"] --> eM1Ss8DOjlE9["Path: Org -> Branch -> Warehouse -> Bin"]
    eM1S335crnrp["Branch B"] --> |Default Warehouse| eM1S76E.EhFn["Default Warehouse (Auto)"]
    dM1SaHXGop1y["Review / Correct Profile Details"] --> dM1SqTqUN124["Fill Organization Profile"]
    eM1SFEnpH-~T["Default Warehouse (Auto)"] --> eM1SDTzfp.Hx["Bin 2 (Enabled)"]
    dM1S~M9jaVao["Organization"] --> eM1S335crnrp["Branch B"]
    dM1SFIeDhaA1["Create Organization"] --> dM1SrDaYEwdl["Auto-create Default Warehouse"]
    eM1Ss8DOjlE9["Path: Org -> Branch -> Warehouse -> Bin"] --> eM1SdEaP99go["All transactions flow through Warehouse/Bin"]
    dM1SPF-qybzC["Enable Bin Locations by Default"] --> dM1Su63LJeR1["End Flow"]
    ih4SMQAOklYo["Restrictions: No Org mod, No branch edit, No structure change"] --> |Notes| ih4SrAgl2aG5["Operate Within Assigned Warehouse/Bins"]
    dM1S~M9jaVao["Organization"] --> |Multiple Branches| eM1SZBS~-Iuj["Branch A"]
    ih4SexGSHM.n["Auto-load Branch Profile Data"] --> |Uses hierarchy| ih4SLq1-Zbl8["Hierarchy: Organization → Branch → Warehouse → Bin"]
    ih4SMQAOklYo["Restrictions"] --> |Notes| ih4S4_sTZfPe["Profile Fields"]
    ih4Ste8WF52a["Auto-create Branch Default Warehouse"] --> |Auto-created| ih4Ste8WF52a["Auto-create Branch Default Warehouse"]
```

### 1.5.2 Procedural Steps
- **HO Setup:** HO Login -> Fill Organization Profile -> Click Save.
- **Auto-Provisioning:** System auto-creates Default Warehouse for the Organization (Name = Org Location + Org Name).
- **Branch Creation:** Create Branch (HO or Outlet). System auto-creates Branch Default Warehouse (Name = Branch Location + "Store").
- **Inventory Hierarchy:** Organization -> Branch -> Warehouse -> Bin.
- **Rules & Governance:**
    - Bin tracking is mandatory at branch level.
    - Branches operate ONLY within their assigned warehouse/bins.
    - All inventory transactions (receipts, sales, transfers) MUST flow through a Bin.
- **Branch Access:** Branch users have restricted access (View-only profile, cannot modify Org/Branch structure).

---

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
│   ├── Initial Setup
│   └── First Invoice
├── Features
│   ├── Items
│   ├── Inventory
│   ├── Sales
│   ├── Purchases
│   ├── Accountant
│   ├── Accounts
│   ├── Reports
│   ├── Documents
│   └── Audit Logs
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

---

## Strict Structure + Handoff Merge Governance (2026-05-24)

1. Canonical placement mandatory:
- Business code -> `lib/modules/<domain>/...`
- App infra -> `lib/core/...` or `lib/app/...`
- Cross-domain reusable UI -> `lib/shared/widgets/...`
- Cross-domain services -> `lib/shared/services/...`

2. File/folder creation controls:
- Confirm owner domain before creating files/folders.
- No new legacy roots or ambiguous sink files/folders.
- New `shared/` items require real cross-domain reuse justification.

3. Incoming handoff merge protocol:
- Backup first: `backups/refactor-batches/<timestamp>-<scope>/`.
- Map every inbound file/folder to canonical destination before merge.
- Use compatibility shims for moved active paths until import-zero proof.
- No destructive delete in same batch as move/rewire.

4. Mandatory verification gates:
- Frontend touched -> `dart analyze` touched scope.
- Backend touched -> `npm.cmd run build` in `backend/`.
- Route/deeplink-affecting changes -> route smoke checks.

5. Mandatory audit trail:
- Update root `log.md` with moved files, shim status, verifications, risks.
- Keep handoff backups/handoff folders until explicit approval to delete.

6. Auto-reject merge if any true:
- analyze/build failures,
- unresolved ownership ambiguity,
- schema/DTO drift vs `current schema.md`,
- route regression without safe fallback.

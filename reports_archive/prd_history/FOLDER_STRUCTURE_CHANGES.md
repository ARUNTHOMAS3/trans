# Folder Structure - What Changed Based on Your Preferences

## ⚠️ PRD Edit Policy
Do not edit PRD files unless explicitly requested by the user or team head.
## 🔒 Auth Policy (Pre-Production)
No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-28 15:13
**Last Edited Version:** 1.3

---

## 🎯 **Your Answers Summary:**

| Q | Question | Your Answer |
|---|----------|-------------|
| Q1 | Navbar/Sidebar location? | **B** - `lib/core/layout/` |
| Q2 | Form widgets location? | **Move to `lib/core/widgets/`** |
| Q3 | App router location? | **A** - `lib/core/routing/app_router.dart` |
| Q4 | Theme files location? | **A** - `lib/core/theme/` |
| Q5 | API client location? | **A** - `lib/core/api/` |
| Q6 | Module structure? | **Standardize** (detailed structure with controllers/) |
| Q7 | Global utils location? | **A** - `lib/core/utils/` |
| Q8 | Dart extensions? | **Separate** - `lib/core/extensions/` |
| Q9 | Constants location? | **`lib/core/constants/`** |
| Q10 | Backend structure? | **Standard NestJS** |
| Q11 | Assets location? | **`assets/` (outside lib/)** |
| Q12 | Test structure? | **Mirror `lib/` exactly** |

---

## 📁 **Final Structure (Your Customized Version):**

```
lib/
├── core/                    # ⭐ Everything infrastructure + core widgets
│   ├── routing/            # App router (GoRouter)
│   ├── theme/              # Theme, colors, text styles
│   ├── layout/             # ⭐ Sidebar, navbar (moved from shared)
│   ├── widgets/            # ⭐ Form widgets, common widgets (moved from shared)
│   │   ├── forms/         # FormDropdown, FormTextField, etc.
│   │   ├── common/        # LoadingIndicator, ErrorWidget
│   │   └── dialogs/       # ConfirmationDialog, etc.
│   ├── constants/         # API endpoints, app constants
│   ├── utils/             # Formatters, validators
│   ├── extensions/        # String, DateTime extensions (separate folder)
│   ├── api/               # Dio client, interceptors
│   ├── storage/           # Hive, SharedPreferences services
│   ├── logging/           # Logger configuration
│   └── monitoring/        # Health check widget
│
├── shared/                 # ⭐ ONLY providers & models now
│   ├── providers/         # Shared providers (items, vendors)
│   └── models/            # Shared models (Address, Contact)
│
└── modules/               # ⭐ Standard structure enforced
    └── <module>/
        ├── models/
        ├── providers/
        ├── controllers/    # For complex logic
        ├── repositories/   # Interface + Impl
        └── presentation/
            ├── <module>_<submodule>_<page>.dart
            └── widgets/
```

---

## 🔄 **What Moved:**

### **From `lib/shared/widgets/` to `lib/core/`:**

| File | Old Location | New Location |
|------|--------------|--------------|
| zerpai_sidebar.dart | `lib/shared/widgets/layout/` | `lib/core/layout/` |
| zerpai_navbar.dart | `lib/shared/widgets/layout/` | `lib/core/layout/` |
| responsive_layout.dart | `lib/shared/widgets/layout/` | `lib/core/layout/` |
| form_dropdown.dart | `lib/shared/widgets/forms/` | `lib/core/widgets/forms/` |
| form_text_field.dart | `lib/shared/widgets/forms/` | `lib/core/widgets/forms/` |
| form_date_picker.dart | `lib/shared/widgets/forms/` | `lib/core/widgets/forms/` |
| loading_indicator.dart | `lib/shared/widgets/common/` | `lib/core/widgets/common/` |
| error_widget.dart | `lib/shared/widgets/common/` | `lib/core/widgets/common/` |
| empty_state.dart | `lib/shared/widgets/common/` | `lib/core/widgets/common/` |
| confirmation_dialog.dart | `lib/shared/widgets/dialogs/` | `lib/core/widgets/dialogs/` |
| info_dialog.dart | `lib/shared/widgets/dialogs/` | `lib/core/widgets/dialogs/` |

**Rationale:** These are infrastructure components that the app NEEDS to run, not business-specific shared code.

---

## ✅ **What Stayed the Same:**

- Backend structure: Standard NestJS ✅
- Assets location: `assets/` (outside lib/) ✅
- Test structure: Mirrors `lib/` exactly ✅
- File naming: `snake_case` ✅
- Module structure: Standardized with controllers/, repositories/ ✅

---

## 🎯 **Key Philosophy:**

**`lib/core/`** = Infrastructure  
- "Does the app need this to run?"  
- Router, theme, API client, sidebar, navbar, form widgets

**`lib/shared/`** = Business Data  
- "Is this business data shared across features?"  
- Providers (items, vendors), models (Address, Contact)

**`lib/modules/`** = Features  
- "Is this specific to one business feature?"  
- Sales, items, POS, inventory

---

## 📋 **Migration Checklist (Apply to Current Codebase):**

**Phase 1: Move Files (High Priority)**
- [ ] Move `zerpai_sidebar.dart` from `lib/shared/widgets/layout/` to `lib/core/layout/`
- [ ] Move `zerpai_navbar.dart` from `lib/shared/widgets/layout/` to `lib/core/layout/`
- [ ] Move all form widgets from `lib/shared/widgets/forms/` to `lib/core/widgets/forms/`
- [ ] Move common widgets from `lib/shared/widgets/common/` to `lib/core/widgets/common/`
- [ ] Move dialogs from `lib/shared/widgets/dialogs/` to `lib/core/widgets/dialogs/`

**Phase 2: Update Imports**
- [ ] Find and replace all import statements referencing old locations
- [ ] Run `flutter analyze` to catch any missed imports

**Phase 3: Standardize Modules**
- [ ] Add `controllers/` folder to modules that need complex logic
- [ ] Split `repositories.dart` into `*_repository.dart` (interface) and `*_repository_impl.dart`
- [ ] Ensure all modules follow the standard structure

**Phase 4: Verify**
- [ ] Run `flutter analyze` (should be 0 errors)
- [ ] Run `flutter test`
- [ ] Manual smoke test of key features

---

## 🚀 **Ready to Start Tomorrow!**

The folder structure is now finalized and documented in:
- **`PRD/prd_folder_structure.md`** - Complete guide
- **`PRD/PRD.md`** Section 7.2 - Quick reference

All new code MUST follow this structure starting now! ✅

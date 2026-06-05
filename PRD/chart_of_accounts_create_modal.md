# Chart of Accounts "Create Account" Modal Specification

## 1. Account Types that SUPPORT Sub-Accounts

The checkbox is available for most standard accounting categories. If an account type is listed below, the system allows it to be nested under a parent.

### Asset Category:

- Accounts Receivable
- Fixed Asset
- Cash
- Other Current Asset
- Other Asset

### Liability Category:

- Accounts Payable
- Other Current Liability
- Non Current Liability

### Income Category:

- Income
- Other Income

### Expense Category:

- Expense
- Cost Of Goods Sold
- Other Expense

### Equity Category:

- Equity

## 2. Account Types that DO NOT Support Sub-Accounts

The following types do not show the "Make this a sub-account" option:

- Bank
- Stock
- Credit Card
- Deferred Tax Asset / Deferred Tax Liability
- Intangible Asset
- Non Current Asset
- Overseas Tax Payable
- Payment Clearing Account

## 3. UI Behavior

- **Location**: The checkbox is located directly beneath the "Account Name\*" field.
- **Conditional Visibility**: When the user clicks the checkbox, a new required field appears: "Parent Account\*".
- **Parent Selection**: A searchable dropdown appears.
- **Logic**: The system filters the list so you can only select a parent that is the same category as the account you are creating.
- **Tooltips**: A small gray question mark icon (?) next to the label.

## 4. Technical & Accounting Logic

- **Database Mapping**: Populates `parent_id` column in `accounts` table. If NULL, it is a root account.
- **Reporting**: Roll-up logic for financial statements.
- **Naming Convention**: Often displayed as `Parent Account Name: Sub Account Name`.

## 5. Summary Table

| Category    | Type                                  | Sub-account Support? |
| ----------- | ------------------------------------- | -------------------- |
| Assets      | Cash, Fixed Asset, Current Asset      | YES                  |
| Assets      | Bank, Stock, Intangible               | NO                   |
| Liabilities | Accounts Payable, Current/Non-Current | YES                  |
| Liabilities | Credit Card, Tax Payable              | NO                   |
| Income      | All Income types                      | YES                  |
| Expenses    | All Expense types                     | YES                  |
| Equity      | Equity                                | YES                  |

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

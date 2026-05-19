### Dev- Arun

<!-- LOG RULES START -->

### Zerpai Log Maintenance Rules

1. **Initialize/Locate**: If `log.md` exists in the root, read it first. If not, create it.
2. **Dev Attribution**: Always ensure the very first line of the file is `### Dev- Arun`.
3. **Structure**: Maintain a numbered list of features (e.g., `## 7. Feature Name`). Include a high-level description and bullet points for logic.
4. **File Categorization (CRITICAL)**: You MUST split the changed files into two distinct lists: 'Frontend Files' (`lib/...`) and 'Backend Files' (`backend/...`).
5. **Append Only**: Never delete previous entries. Always add new changes at the **bottom** of the file using `cat >> log.md <<'EOF'`.
6. **Timestamps**: Every batch of changes must end with: `Timestamp of Log Update: [Date] - [Time] (IST)`.
7. **Engineer-to-Engineer**: Write with technical depth, explaining 'why' architectural choices were made.
8. **Method**: Use bash heredoc append only: `cat >> e:/zerpai-new/log.md <<'EOF'` ... `EOF`. NEVER use `printf` with full-file rewrite. NEVER use the Edit tool on this file.
<!-- LOG RULES END -->

## 1. Sales Invoice UI & Feature Standardization (May 19, 2026)

### Summary
Aligned the Sales Invoice creation workflow (`sales_invoice_create.dart`) with the established ERP standards. Standardized the date picker widgets, implemented a full-parity file attachments UI, and unified dropdown item hover behaviors to ensure consistency and visual appeal.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/presentation/sales_invoice_create.dart`:
  - **Date Pickers Refactoring**: Replaced manual `showDatePicker` calls for `Invoice Date` and `Due Date` fields with the shared `ZerpaiDatePicker.show(...)` component utilizing unique `GlobalKey` references.
  - **File Attachment parity**: Added `_attachedFiles` state arrays, constraints checks (max 10 files, max 5MB size limit), conditional rendering of attachment badge, and implemented an interactive overlay showing files list with hover-to-delete options.
  - **Hover Visual Refinement**: Changed background hover highlight from standard blue/light-blue states to the unified `AppTheme.infoBlue` (`0xFF3B82F6`) and white text. Affected dropdown widgets include the accounts selection overlay, reporting tags dropdown, and the upload pop-up menu.

Timestamp of Log Update: May 19, 2026 - 12:10 PM (IST)
# PRD: Power-User Keyboard Shortcut System

## 1. Overview
The **Power-User Keyboard Shortcut System** is designed to enhance operational efficiency and data entry speed within the Zerpai ERP application. By providing standardized, mnemonic shortcuts and visual hints (tooltips), the system caters to high-productivity users, aligning with professional software standards like Zoho and SAP.

## 2. Core Components

### 2.1 ShortcutHandler (`lib/shared/widgets/shortcut_handler.dart`)
A centralized wrapper widget that listens for hardware key events. It abstracts the complexity of `FocusNode` management and `CallbackShortcuts`.
- **Primary Bindings**:
  - `Ctrl + S`: Save / Draft.
  - `Ctrl + Enter`: Publish / Save & Post.
  - `Esc`: Cancel / Discard.
  - `/`: Search Focus.

### 2.2 ZerpaiLayout Integration
The application's shell is updated to natively pass shortcut callbacks to `ShortcutHandler`, ensuring consistent behavior across all screens wrapped in `ZerpaiLayout`.

## 3. Implemented Shortcuts & Locations

| Key Combination | Action | Locations Applied | Behavior Details |
| :--- | :--- | :--- | :--- |
| **Ctrl + S** | Save / Save as Draft | Manual Journal, COA Create, Vendor Create | Triggers the primary save/draft persistence logic. |
| **Ctrl + Enter** | Save & Publish | Manual Journal | Triggers full "Posted" status logic for journals. |
| **Esc** | Cancel / Discard | Manual Journal, COA Create, Vendor Create | Closes the form. Triggers **Discard Guard** if unsaved changes exist. |
| **/** | Focus Search | COA Overview, Generic List Screens | Focuses the main search field or opens the Advanced Search dialog. |
| **Alt + N** | New (Tooltip Hint) | Generic Lists, COA Overview | Visual indicator for the 'New' button shortcut. |

## 4. Key Features

### 4.1 Discard Guard
To prevent accidental data loss, the system tracks the `isDirty` state of a form (via text field listeners or `Form.onChanged`).
- **Trigger**: User presses `Esc` or clicks "Cancel".
- **Condition**: If `isDirty == true`, an `AlertDialog` is shown asking for confirmation before discarding.

### 4.2 UI Visibility (Visual Hints)
Tooltips across the application have been updated to display the corresponding shortcut key.
- **Example**: `Save (Ctrl+S)`, `Publish (Ctrl+Enter)`, `New (Alt+N)`.

## 5. Technical Implementation Details

### Form Dirty Tracking
Form dirtiness is tracked using:
1.  `TextEditingController` listeners (for fine-grained tracking).
2.  `Form.onChanged` (for general form state update).
3.  `StateProvider` or local `setState` variables (`bool _isDirty`).

### Shortcut Routing
The `ShortcutHandler` uses `SingleActivator` with `LogicalKeyboardKey` ensuring cross-platform compatibility (handling both `Ctrl` and `Meta`/Command keys seamlessly).

## 6. Future Scope
- **Configurable Shortcuts**: Allow users to customize key bindings.
- **Shortcut Cheat Sheet**: A global popup (e.g., `Shift + ?`) showing all available shortcuts.
- **Expanded Navigation**: Adding shortcuts for sidebar navigation (e.g., `Alt + 1` for Dashboard).

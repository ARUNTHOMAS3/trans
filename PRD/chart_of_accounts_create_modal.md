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

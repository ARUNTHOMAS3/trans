# Accountant — Chart of Accounts Flow

## COA Overview Load Flow

```mermaid
flowchart TD
    PAGE[accountant_chart_of_accounts_overview.dart] --> PROV[ChartOfAccountsProvider\nStateNotifier]
    PROV --> LOAD[init: load accounts + metadata]
    LOAD --> API1[GET /api/v1/accountant]
    LOAD --> API2[GET /api/v1/accountant/metadata\naccount types + groups + currencies]

    API1 --> BUILD[Build account tree\nwith parent_id nesting]
    BUILD --> ROOTS[roots: List~AccountNode~]
    ROOTS --> TREE_UI[Tree widget\ncollapsible by group]

    TREE_UI --> EXPAND[Expand/Collapse\ntoggle expandedIds set]
    TREE_UI --> SELECT[Select account\nupdate selectedAccountId]
    SELECT --> TXN[GET /accountant/:id/transactions]
    SELECT --> BAL[GET /accountant/:id/closing-balance]
    TXN --> PANEL[Side panel\nrecent transactions + balance]
```

## COA State

```mermaid
classDiagram
    class ChartOfAccountsState {
        +List~AccountNode~ roots
        +Set~String~ expandedIds
        +String? selectedAccountId
        +List~AccountTransaction~ recentTransactions
        +List~Currency~ currencies
        +double closingBalance
        +bool isLoading
        +String? error
        +String searchQuery
        +List~AccountMetadata~ accountTypes
    }

    class AccountNode {
        +String id
        +String name
        +String accountType
        +String accountGroup
        +String? parentId
        +double balance
        +List~AccountNode~ children
    }

    ChartOfAccountsState --> AccountNode
```

## Create Account Flow

```mermaid
flowchart TD
    PAGE[accountant_chart_of_accounts_account_create.dart] --> LOAD[Load metadata]
    LOAD --> META[GET /accountant/metadata\naccount types + groups]

    LOAD --> FORM[Create Account form]
    FORM --> F1[Account Name]
    FORM --> F2[Account Type\nAssets / Liabilities / Income / Expense / Equity / Bank]
    FORM --> F3[Account Group\nauto-filtered by type]
    FORM --> F4[GSTIN-relevant toggle]
    FORM --> F5[Sub-account checkbox]
    F5 -->|checked| F5A[Parent account dropdown\nfiltered by same category\nGET /accountant/group/:group]
    FORM --> F6[Description]
    FORM --> F7[Opening Balance\n+ debit/credit toggle]

    FORM --> SAVE[Ctrl+S]
    SAVE --> REPO[AccountantRepository]
    REPO --> API[POST /api/v1/accountant]
    API -->|success| TREE[Refresh tree\nZerpaiToast]
    API -->|fail| ERR[ZerpaiToast error]
```

## Sub-Account Types Reference

```mermaid
graph TD
    SUPPORT[Types Supporting Sub-Accounts]
    NO_SUPPORT[Types NOT Supporting Sub-Accounts]

    SUPPORT --> A1[Assets\nAccounts Receivable, Fixed Asset, Cash]
    SUPPORT --> A2[Liabilities\nAccounts Payable]
    SUPPORT --> A3[Income]
    SUPPORT --> A4[Expense]
    SUPPORT --> A5[Equity]

    NO_SUPPORT --> B1[Bank]
    NO_SUPPORT --> B2[Stock]
    NO_SUPPORT --> B3[Credit Card]
    NO_SUPPORT --> B4[Deferred Tax]
    NO_SUPPORT --> B5[Intangible Asset]
```

## Account Transaction — Ledger View

```mermaid
flowchart TD
    SELECT[User selects account\nin COA tree] --> TXN_LOAD[GET /accountant/:id/transactions\n?dateFrom&dateTo&page]
    TXN_LOAD --> TABLE[Transaction table\ndate, description, debit, credit, balance]
    TABLE --> FILTER[Filter by date range]
    TABLE --> EXPORT[Export to CSV]
    TABLE --> TXN_CLICK[Click transaction]
    TXN_CLICK --> SOURCE[Navigate to source document\ninvoice / journal / purchase]
```

## Database Schema

```mermaid
erDiagram
    accounts {
        uuid id PK
        uuid org_id FK
        string name
        string account_type
        string account_group
        uuid parent_id FK
        decimal opening_balance
        string balance_type
        boolean is_system_account
        timestamp created_at
    }

    account_transactions {
        uuid id PK
        uuid org_id FK
        uuid account_id FK
        decimal debit
        decimal credit
        string description
        string source_type
        uuid source_id
        date transaction_date
    }

    accounts ||--o{ accounts : parent_child
    accounts ||--o{ account_transactions : has
```

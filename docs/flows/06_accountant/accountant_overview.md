# Accountant Module — Overview

## Module Structure

```mermaid
graph TD
    ACC[Accountant Module\nlib/modules/accountant/]

    ACC --> COA[chart_of_accounts/\nChart of Accounts]
    ACC --> MJ[manual_journals/\nManual Journals]
    ACC --> RJ[recurring_journals/\nRecurring Journals]
    ACC --> OB[opening_balances/\nOpening Balances]
    ACC --> TL[transaction_locking/\nTransaction Locking]
    ACC --> SET[settings/\nSettings]

    COA --> COA_P[accountant_chart_of_accounts_provider.dart]
    COA --> COA_M[accountant_chart_of_accounts_account_model.dart\naccount_transaction_model.dart\naccountant_metadata_model.dart]
    COA --> COA_R[accountant_repository.dart]

    MJ --> MJ_M[manual_journal_model.dart]
    MJ --> MJ_P[manual_journal_provider.dart\nmanual_journal_template_provider.dart]
    MJ --> MJ_R[manual_journal_repository.dart]

    RJ --> RJ_M[recurring_journal_model.dart]
    RJ --> RJ_P[recurring_journal_provider.dart]
    RJ --> RJ_R[recurring_journal_repository.dart]
```

## Route Map

```mermaid
graph LR
    BASE[/accountant]

    BASE --> COA[/accounts]
    BASE --> MJ[/manual-journals]
    BASE --> RJ[/recurring-journals]
    BASE --> OB[/opening-balances]
    BASE --> TL[/transaction-locking]
    BASE --> BU[/bulk-update]
    BASE --> SET[/settings]

    COA --> COA_NEW[/create]
    COA --> COA_ID[/:id]

    MJ --> MJ_NEW[/create]
    MJ --> MJ_TMPL[/templates]
    MJ --> MJ_TMPL_NEW[/journal-template-creation]

    RJ --> RJ_NEW[/create]
```

## Backend API Summary

```mermaid
graph LR
    CTRL[AccountantController\n/accountant]

    CTRL --> A1[GET / — list accounts]
    CTRL --> A2[GET /search — fuzzy search]
    CTRL --> A3[GET /group/:group — by account group]
    CTRL --> A4[GET /metadata — account types + groups]
    CTRL --> A5[POST / — create account]
    CTRL --> A6[PUT /:id — update account]
    CTRL --> A7[DELETE /:id — delete account]
    CTRL --> A8[GET /:id/transactions — ledger]
    CTRL --> A9[GET /:id/closing-balance]

    CTRL --> MJ1[GET /manual-journals]
    CTRL --> MJ2[POST /manual-journals]
    CTRL --> MJ3[POST /manual-journals/:id/status]
    CTRL --> MJ4[POST /manual-journals/:id/clone]
    CTRL --> MJ5[POST /manual-journals/:id/reverse]
    CTRL --> MJ6[POST /manual-journals/:id/template]

    CTRL --> TMPL1[GET /journal-templates]
    CTRL --> TMPL2[POST /journal-templates]

    CTRL --> RJ1[GET /recurring-journals]
    CTRL --> RJ2[POST /recurring-journals/:id/generate]

    CTRL --> RPT[GET /reports/profit-and-loss\nGET /reports/general-ledger\nGET /reports/trial-balance\nGET /reports/account-transactions]
```

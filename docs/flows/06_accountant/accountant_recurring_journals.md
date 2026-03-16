# Accountant — Recurring Journals Flow

## Recurring Journal Create Flow

```mermaid
flowchart TD
    PAGE[accountant_recurring_journals_create.dart] --> LOAD[Load accounts]
    LOAD --> API1[GET /api/v1/accountant]

    LOAD --> FORM[Recurring Journal form]
    FORM --> F1[Name]
    FORM --> F2[Journal lines\nsame structure as manual journal]
    FORM --> F3[Frequency\ndaily / weekly / monthly / quarterly / yearly]
    FORM --> F4[Start date]
    FORM --> F5[End date or Never]
    FORM --> F6[Next run date\nauto-calculated]

    FORM --> SAVE[Save]
    SAVE --> REPO[RecurringJournalRepository]
    REPO --> API[POST /api/v1/accountant/recurring-journals]
    API --> DONE[Saved — auto-runs on schedule]
```

## Recurring Journal Auto-Run Flow (Cron)

```mermaid
flowchart TD
    CRON[RecurringJournalsCronService\nruns daily at midnight] --> CHECK[Find all active recurring journals\nwhere next_run_date <= today]

    CHECK --> EACH[For each due journal]
    EACH --> GEN[POST /accountant/recurring-journals/:id/generate]
    GEN --> CREATE[Create manual journal\nstatus: posted]
    CREATE --> TXN[Create account_transactions]
    CREATE --> UPDATE_NEXT[Update next_run_date\nbased on frequency]
    UPDATE_NEXT -->|reached end date| DEACTIVATE[Mark recurring journal as inactive]
    UPDATE_NEXT -->|not ended| CONTINUE[Schedule next run]
```

## Manual Trigger Flow

```mermaid
flowchart TD
    DETAIL[Recurring Journal Detail] --> BTN[Generate Now button]
    BTN --> CONFIRM[Confirm dialog]
    CONFIRM --> API[POST /accountant/recurring-journals/:id/generate]
    API --> JOURNAL[New manual journal created\nstatus: posted]
    JOURNAL --> TOAST[ZerpaiToast: Journal generated]
```

## Recurring Journal Status Machine

```mermaid
stateDiagram-v2
    [*] --> Active : Create
    Active --> Inactive : End date reached / manual stop
    Active --> Active : Auto-generates journals on schedule
    Inactive --> Active : Re-activate with new dates
```

## Database Schema

```mermaid
erDiagram
    accounts_recurring_journals {
        uuid id PK
        uuid org_id FK
        string name
        string frequency
        date start_date
        date end_date
        date next_run_date
        boolean is_active
    }

    accounts_recurring_journal_items {
        uuid id PK
        uuid recurring_journal_id FK
        uuid account_id FK
        decimal debit
        decimal credit
        string description
    }

    accounts_recurring_journals ||--o{ accounts_recurring_journal_items : has
```

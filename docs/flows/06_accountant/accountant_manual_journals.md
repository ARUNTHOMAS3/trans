# Accountant — Manual Journals Flow

## Manual Journal Create Flow

```mermaid
flowchart TD
    PAGE[accountant_manual_journals_create.dart] --> LOAD[Load data]
    LOAD --> L1[GET /accountant\naccount list for dropdowns]
    LOAD --> L2[GET /sequences/journal/next\nauto journal number]
    LOAD --> L3[GET /accountant/journal-templates\nfor template picker]

    LOAD --> FORM[Journal Entry form]
    FORM --> H[Header\nJournal#, date, reference, notes]
    FORM --> ROWS[Journal lines table]
    ROWS --> ROW[Each row:\naccount dropdown + debit + credit + description]
    ROWS --> ADD_ROW[+ Add line]
    ROWS --> DEL_ROW[Remove line]

    ROWS --> BALANCE{Debits == Credits?}
    BALANCE -->|no| UNBAL[Show imbalance warning\nremaining amount indicator]
    BALANCE -->|yes| BALANCED[Balanced indicator]

    FORM --> SAVE[Ctrl+S → Draft]
    FORM --> PUBLISH[Ctrl+Enter → Post]
    FORM --> TEMPLATE_BTN[Save as Template]

    SAVE --> REPO[ManualJournalRepository]
    REPO --> API[POST /api/v1/accountant/manual-journals\nstatus: draft]

    PUBLISH --> REPO
    REPO --> API2[POST /api/v1/accountant/manual-journals\nstatus: posted]
    API2 --> TXN[Auto-create account_transactions\nfor each journal line]

    TEMPLATE_BTN --> REPO
    REPO --> T_API[POST /accountant/manual-journals/:id/template]
```

## Manual Journal Status State Machine

```mermaid
stateDiagram-v2
    [*] --> Draft : Create (Ctrl+S)
    Draft --> Posted : Post (Ctrl+Enter)
    Posted --> Reversed : Reverse journal
    Draft --> [*] : Delete

    note right of Posted
        Creates account_transactions
        Cannot edit after posting
    end note

    note right of Reversed
        Creates equal and opposite\njournal entry automatically
    end note
```

## Journal Operations Flow

```mermaid
flowchart TD
    DETAIL[Manual Journal Detail] --> OPS[Available Operations]

    OPS --> CLONE[Clone\nPOST /manual-journals/:id/clone\ncreates draft copy]
    OPS --> REVERSE[Reverse\nPOST /manual-journals/:id/reverse\ncreates opposite entry]
    OPS --> STATUS[Change Status\nPOST /manual-journals/:id/status]
    OPS --> ATTACH[Add Attachment\nPOST /manual-journals/:id/attachments\nuploads to R2]

    CLONE --> NEW_DRAFT[New draft journal]
    REVERSE --> REV_JOURNAL[New reversed journal\nDebits ↔ Credits swapped]
```

## Journal Templates Flow

```mermaid
flowchart TD
    TMPL_LIST[accountant_manual_journals_templates.dart] --> PROV[manualJournalTemplateProvider]
    PROV --> API[GET /accountant/journal-templates]
    API --> TABLE[Template list\nname, line count, created]

    TABLE --> USE[Use Template button]
    USE --> PRE_FILL[Pre-fill create form\nwith template lines]
    PRE_FILL --> CREATE_PAGE[Manual journal create\nwith account rows populated]

    TABLE --> NEW_TMPL[New Template]
    NEW_TMPL --> TMPL_FORM[/journal-template-creation]
    TMPL_FORM --> TMPL_ROWS[Template lines\naccount + debit/credit side]
    TMPL_FORM --> SAVE[POST /accountant/journal-templates]
```

## Database Schema

```mermaid
erDiagram
    accounts_manual_journals {
        uuid id PK
        uuid org_id FK
        string journal_number
        date journal_date
        string reference
        string status
        string notes
        timestamp created_at
    }

    accounts_manual_journal_items {
        uuid id PK
        uuid journal_id FK
        uuid account_id FK
        decimal debit
        decimal credit
        string description
    }

    accounts_manual_journal_attachments {
        uuid id PK
        uuid journal_id FK
        string file_url
        string file_name
    }

    accounts_journal_templates {
        uuid id PK
        uuid org_id FK
        string name
    }

    accounts_journal_template_items {
        uuid id PK
        uuid template_id FK
        uuid account_id FK
        string entry_type
    }

    accounts_manual_journals ||--o{ accounts_manual_journal_items : has
    accounts_manual_journals ||--o{ accounts_manual_journal_attachments : has
    accounts_journal_templates ||--o{ accounts_journal_template_items : has
```

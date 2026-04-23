# Reports Module — Overview & Flows

## Report Center

```mermaid
graph TD
    CENTER[Reports Center\n/reports] --> FINANCIAL[Financial Reports]
    CENTER --> OPERATIONAL[Operational Reports]

    FINANCIAL --> AT[Account Transactions\n/reports/account-transactions]
    FINANCIAL --> GL[General Ledger\n/reports/general-ledger]
    FINANCIAL --> TB[Trial Balance\n/reports/trial-balance]
    FINANCIAL --> PL[Profit and Loss\n/reports/profit-and-loss]

    OPERATIONAL --> SC[Sales by Customer\n/reports/sales-by-customer]
    OPERATIONAL --> IV[Inventory Valuation\n/reports/inventory-valuation]
    OPERATIONAL --> DS[Daily Sales\n/reports/sales-daily]
```

## Shared Report Shell Flow

```mermaid
flowchart TD
    REPORT[Any Report Page] --> SHELL[ZerpaiReportShell]
    SHELL --> HEADER[Header\nReport title + date range selector]
    SHELL --> FILTERS[Filter bar\ndate, account, customer, branch, etc.]
    SHELL --> ACTIONS[Actions\nexport CSV, export PDF, print]
    SHELL --> TABLE[Data table\npaginated results]

    FILTERS --> CHANGED[Filter changed]
    CHANGED --> CTRL[ReportsController]
    CTRL --> REPO[ReportsRepository]
    REPO --> API[GET /api/v1/accountant/reports/:type\n?dateFrom&dateTo&filters]
    API --> DATA[Report data]
    DATA --> TABLE
```

## Account Transactions Report

```mermaid
flowchart TD
    PAGE[reports_account_transactions.dart] --> FILTERS[Filters]
    FILTERS --> F1[Account selector\naccountant tree dropdown]
    FILTERS --> F2[Date range]
    FILTERS --> F3[Transaction type\ndebit/credit/all]

    FILTERS --> API[GET /accountant/reports/account-transactions\n?accountId&dateFrom&dateTo&type]
    API --> TABLE[Table\ndate, description, debit, credit, running balance]
    TABLE --> TOTAL[Footer\ntotal debits, total credits, net]
```

## General Ledger Report

```mermaid
flowchart TD
    PAGE[reports_general_ledger.dart] --> FILTERS[Filters\ndate range + account group]
    FILTERS --> API[GET /accountant/reports/general-ledger]
    API --> GROUPED[Grouped by account\nopening balance + transactions + closing balance]
```

## Trial Balance Report

```mermaid
flowchart TD
    PAGE[reports_trial_balance.dart] --> DATE[As-of date picker]
    DATE --> API[GET /accountant/reports/trial-balance\n?asOf=date]
    API --> TABLE[Two-column table\nAccount | Debit | Credit]
    TABLE --> TOTALS[Total row\nmust balance]
    TOTALS --> CHECK{Debits == Credits?}
    CHECK -->|yes| BALANCED[Balanced indicator]
    CHECK -->|no| ERROR[Data error alert]
```

## Profit & Loss Report

```mermaid
flowchart TD
    PAGE[reports_profit_and_loss.dart] --> PERIOD[Period selector\nmonth / quarter / FY]
    PERIOD --> API[GET /accountant/reports/profit-and-loss\n?dateFrom&dateTo]
    API --> INCOME[Income section\nrevenue accounts + total]
    API --> EXPENSES[Expense section\nexpense accounts + total]
    INCOME --> GROSS[Gross Profit = Income - COGS]
    EXPENSES --> NET[Net Profit = Gross - Operating Expenses]
```

## Sales by Customer Report

```mermaid
flowchart TD
    PAGE[reports_sales_by_customer.dart] --> FILTERS[Filters\ndate range + customer filter]
    FILTERS --> API[GET /accountant/reports/sales-by-customer\n?dateFrom&dateTo&customerId]
    API --> TABLE[Table\ncustomer, invoices count, total sales, payments received, balance]
    TABLE --> SORT[Sort by: total sales / balance / name]
    TABLE --> DRILL[Click customer → filtered invoices]
```

## Inventory Valuation Report

```mermaid
flowchart TD
    PAGE[reports_inventory_valuation.dart] --> FILTERS[Filters\nbranch + date + valuation method]
    FILTERS --> API[GET /accountant/reports/inventory-valuation\n?branchId&asOf&method]
    API --> TABLE[Table\nproduct, qty on hand, avg cost, total value]
    TABLE --> METHOD[Valuation methods:\nFIFO / LIFO / FEFO / Weighted Average]
    TABLE --> TOTAL[Total inventory value]
```

## Daily Sales Report

```mermaid
flowchart TD
    PAGE[reports_sales_daily.dart] --> FILTERS[Date range + branch]
    FILTERS --> API[GET /accountant/reports/sales-daily]
    API --> TABLE[Table\ndate, invoices, total sales, cash, credit, returns]
    TABLE --> CHART[Daily trend chart]
```

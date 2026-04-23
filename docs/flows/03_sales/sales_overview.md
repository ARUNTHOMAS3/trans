# Sales Module — Overview

## Sub-Module Map

```mermaid
graph TD
    SALES[Sales Module\nlib/modules/sales/]

    SALES --> CX[customers/\nCustomers]
    SALES --> ORD[sales_orders/\nOrders + Invoices + Quotations]
    SALES --> DC[delivery_challans/\nDelivery Challans]
    SALES --> PAY[payments/\nPayments Received]
    SALES --> CN[credit_notes/\nCredit Notes]
    SALES --> EW[eway_bills/\nE-Way Bills]
    SALES --> RI[retainer_invoices/\nRetainer Invoices]

    ORD --> ORD_M[sales_order_model.dart]
    ORD --> ORD_C[sales_order_controller.dart]
    ORD --> ORD_R[sales_orders_repository.dart]
    ORD --> ORD_S[sales_order_api_service.dart]

    CX --> CX_M[sales_customer_model.dart]
    CX --> CX_R[customers_repository.dart]

    PAY --> PAY_M[sales_payment_model.dart]
    PAY --> PAY_R[payments_repository.dart]

    EW --> EW_M[sales_eway_bill_model.dart]
    EW --> EW_R[eway_bills_repository.dart]
```

## Route Map

```mermaid
graph LR
    SALES_BASE[/sales]

    SALES_BASE --> CX[/customers]
    SALES_BASE --> ORD[/orders]
    SALES_BASE --> INV[/invoices]
    SALES_BASE --> QT[/quotations]
    SALES_BASE --> DC[/delivery-challans]
    SALES_BASE --> PAY[/payments-received]
    SALES_BASE --> CN[/credit-notes]
    SALES_BASE --> EW[/e-way-bills]
    SALES_BASE --> RI[/retainer-invoices]

    CX --> CX_LIST[list]
    CX --> CX_NEW[/create]
    CX --> CX_ID[/:id]

    ORD --> ORD_LIST[list]
    ORD --> ORD_NEW[/create]
    INV --> INV_LIST[list]
    INV --> INV_NEW[/create]
```

## Riverpod Providers

```mermaid
graph LR
    REPO[salesOrdersRepository\ncustomersRepository\npaymentsRepository] --> PROV

    PROV --> salesCustomersProvider
    PROV --> salesOrdersProvider
    PROV --> salesInvoicesProvider
    PROV --> salesQuotesProvider
    PROV --> salesPaymentsProvider
    PROV --> salesCreditNotesProvider
    PROV --> salesChallansProvider
    PROV --> salesRetainerInvoicesProvider
    PROV --> salesEWayBillsProvider
```

import os

path = 'lib/modules/sales/payments_received/presentation/pages/sales_payment_create.dart'
try:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('onPaymentCreated: (SalesPayment payment)', 'onPaymentCreated: (dynamic payment)')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
except: pass


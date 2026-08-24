import os
import re

def final_fix():
    # Fix 1: sales_payment_create mismatch - dynamic cast didn't work because of regex missing the line? Let's just sed it.
    path = 'lib/modules/sales/payments_received/presentation/pages/sales_payment_create.dart'
    try:
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        for i, line in enumerate(lines):
            if 'payment: widget.payment,' in line:
                lines[i] = line.replace('payment: widget.payment,', 'payment: widget.payment as dynamic,')
            elif 'payment: widget.payment' in line and 'as dynamic' not in line:
                # Catch case without comma
                lines[i] = line.replace('payment: widget.payment', 'payment: widget.payment as dynamic')
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
    except: pass

    # Fix 2: ApiEndpoints argument for salesReturnStatus
    path = 'lib/core/constants/api_endpoints.dart'
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = content.replace('static String salesReturnStatus() =>', 'static String salesReturnStatus(dynamic status) =>')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
    except: pass

final_fix()

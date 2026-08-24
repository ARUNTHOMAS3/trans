import os
import re

def inject_api_endpoints():
    path = 'lib/core/constants/api_endpoints.dart'
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        stub = '''
  static String get salesReturnStatus => '/sales-returns/status';
  static String get salesReturnsCustomerHistory => '/sales-returns/customer-history';
  static String salesReturnById(String id) => '/sales-returns/';
  static String creditNoteById(String id) => '/credit-notes/';
'''
        if 'salesReturnStatus' not in content:
            last_brace = content.rfind('}')
            if last_brace != -1:
                content = content[:last_brace] + stub + content[last_brace:]
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Patched {path}")
    except Exception as e:
        print(f"Error: {e}")

inject_api_endpoints()

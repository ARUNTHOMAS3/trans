import re

def insert_before_last_brace(file_path, content_to_insert):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # find last }
    last_brace_idx = content.rfind('}')
    if last_brace_idx != -1:
        new_content = content[:last_brace_idx] + content_to_insert + content[last_brace_idx:]
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {file_path}")

# AppRoutes
insert_before_last_brace('lib/core/routing/app_routes.dart', '''
  static const String settingsMsme = 'settings_msme';
  static const String settingsCustomerPortal = 'settings_customer_portal';
  static const String salesReturnsReport = 'sales_returns_report';
''')

# ApiEndpoints
insert_before_last_brace('lib/core/constants/api_endpoints.dart', '''
  String get salesReturnStatus => '/sales-returns/status';
  String get salesReturnsCustomerHistory => '/sales-returns/customer-history';
  String salesReturnById(String id) => '/sales-returns/';
''')

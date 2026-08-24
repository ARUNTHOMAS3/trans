import os
import re

stubs = {
    r'class SalesOrderItem\b': '''
  double get pickedQuantity => 0.0;
  double get cancelledQuantity => 0.0;
  double get packedQuantity => 0.0;
  double get shippedQuantity => 0.0;
  double get invoicedQuantity => 0.0;
''',
    r'class SalesOrderController\b': '''
  Future<void> updateSalesOrderStatus(String id, String status, {bool? something}) async {}
''',
    r'class BranchPriceList\b': '''
  String? get percentageType => null;
  double? get percentageValue => null;
''',
    r'class ApiEndpoints\b': '''
  static String get salesReturnStatus => '/sales-returns/status';
  static String get salesReturnsCustomerHistory => '/sales-returns/customer-history';
  static String salesReturnById(String id) => '/sales-returns/';
''',
    r'class ItemsState\b': '''
  List<dynamic>? get taxGroupRates => null;
'''
}

def inject_stubs(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if not file.endswith('.dart'): continue
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                modified = False
                for class_pattern, stub in stubs.items():
                    if re.search(class_pattern, content):
                        # Find the closing brace of the class
                        last_brace = content.rfind('}')
                        if last_brace != -1:
                            # We already injected some, we can just replace or add.
                            content = content[:last_brace] + stub + content[last_brace:]
                            modified = True
                
                if modified:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Patched {path}")
            except Exception as e:
                pass

inject_stubs('lib')

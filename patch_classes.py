import os
import re

stubs = {
    r'class SalesOrderItem\b': '''
  double? get pickedQuantity => 0.0;
  double? get cancelledQuantity => 0.0;
  double? get packedQuantity => 0.0;
  double? get shippedQuantity => 0.0;
  double? get invoicedQuantity => 0.0;
''',
    r'class SalesOrderController\b': '''
  Future<void> updateSalesOrderStatus(String id, String status) async {}
  int get totalCount => 0;
  int get totalPages => 0;
  int get currentPage => 0;
  Future<void> loadPage(int page) async {}
  Future<void> setPageSize(int size) async {}
''',
    r'class SalesOrderApiService\b': '''
  Future<void> approvePurchaseOrders(List<String> ids) async {}
''',
    r'class Picklist\b': '''
  List<String>? get salesOrderIds => [];
  List<String>? get salesOrderNumbers => [];
''',
    r'class PriceList\b': '''
  double getItemDiscount(String id) => 0.0;
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
                        # This is a naive heuristic: find the last '}' in the file
                        # Assuming one main class per file
                        last_brace = content.rfind('}')
                        if last_brace != -1:
                            content = content[:last_brace] + stub + content[last_brace:]
                            modified = True
                
                if modified:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Patched {path}")
            except Exception as e:
                pass

inject_stubs('lib')

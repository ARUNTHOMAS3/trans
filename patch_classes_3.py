import os
import re

stubs = {
    r'class ApiEndpoints\b': '''
  static String get salesReturnStatus => '/sales-returns/status';
  static String get salesReturnsCustomerHistory => '/sales-returns/customer-history';
  static String salesReturnById(String id) => '/sales-returns/';
  static String creditNoteById(String id) => '/credit-notes/';
''',
    r'class BranchPriceList\b': '''
  final String? percentageType;
  final double? percentageValue;
''',
    r'class Picklist\b': '''
  final List<String>? salesOrderIds;
  final List<String>? salesOrderNumbers;
''',
    r'class SalesOrderItem\b': '''
  final String? productName;
  final String? gstTreatment;
''',
    r'class PriceList\b': '''
  double getItemDiscount(String id) => 0.0;
''',
    r'class SalesOrder\b': '''
  final String? gstTreatment;
''',
    r'class LookupsApiService\b': '''
  Future<void> setDefaultPaymentTermId(String id) async {}
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
                            content = content[:last_brace] + stub + content[last_brace:]
                            modified = True
                
                if modified:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Patched {path}")
            except Exception as e:
                pass

inject_stubs('lib')

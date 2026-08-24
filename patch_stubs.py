import re

def append_to_class(file_path, insertions):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        last_brace = content.rfind('}')
        if last_brace != -1:
            content = content[:last_brace] + '\n' + insertions + '\n' + content[last_brace:]
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Patched {file_path}")
    except Exception as e:
        print(f"Error patching {file_path}: {e}")

append_to_class('lib/modules/sales/sales_orders/models/sales_order_item.dart', '''
  double? get pickedQuantity => 0.0;
  double? get cancelledQuantity => 0.0;
  double? get packedQuantity => 0.0;
  double? get shippedQuantity => 0.0;
  double? get invoicedQuantity => 0.0;
''')

append_to_class('lib/modules/sales/sales_orders/presentation/controllers/sales_order_controller.dart', '''
  Future<void> updateSalesOrderStatus(String id, String status) async {}
  int get totalCount => 0;
  int get totalPages => 0;
  int get currentPage => 0;
  Future<void> loadPage(int page) async {}
  Future<void> setPageSize(int size) async {}
''')

append_to_class('lib/modules/sales/sales_orders/services/sales_order_api_service.dart', '''
  Future<void> approvePurchaseOrders(List<String> ids) async {}
''')

append_to_class('lib/modules/inventory/picklists/models/picklist.dart', '''
  List<String>? get salesOrderIds => [];
  List<String>? get salesOrderNumbers => [];
''')

append_to_class('lib/shared/models/price_list.dart', '''
  double getItemDiscount(String id) => 0.0;
''')

append_to_class('lib/modules/sales/sales_return/repositories/sales_return_repository_impl.dart', '''
  Future<void> salesReturnStatus() async {}
  Future<void> salesReturnById(String id) async {}
''')

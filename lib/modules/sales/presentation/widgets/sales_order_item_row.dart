import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';

class SalesOrderItemRow {
  final TextEditingController quantityCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController discountCtrl;
  String itemId;
  Item? item;

  SalesOrderItemRow({
    required this.quantityCtrl,
    required this.rateCtrl,
    required this.discountCtrl,
    this.itemId = '',
    this.item,
  });

  void dispose() {
    quantityCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
  }
}

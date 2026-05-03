import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';

class SalesOrderItemRow {
  final TextEditingController quantityCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController discountCtrl;
  final TextEditingController fQtyCtrl;
  final TextEditingController mrpCtrl;
  final TextEditingController descriptionCtrl;
  final FocusNode rateFocus;
  String itemId;
  Item? item;
  String discountType; // '%' or 'Value'
  String? taxId;
  String? batchId;
  String? priceListId;
  final LayerLink hsnLink = LayerLink();
  final LayerLink discountLink = LayerLink();
  final LayerLink warehouseLink = LayerLink();
  final LayerLink moreActionsLink = LayerLink();
  final LayerLink reportingTagsLink = LayerLink();
  double profit = 0;
  bool isHeader;

  SalesOrderItemRow({
    required this.quantityCtrl,
    required this.rateCtrl,
    required this.discountCtrl,
    TextEditingController? fQtyCtrl,
    TextEditingController? mrpCtrl,
    TextEditingController? descriptionCtrl,
    this.itemId = '',
    this.item,
    this.discountType = '%',
    this.taxId,
    this.batchId,
    this.priceListId,
    this.profit = 0,
    this.isHeader = false,
  }) : fQtyCtrl = fQtyCtrl ?? TextEditingController(text: '0'),
       mrpCtrl = mrpCtrl ?? TextEditingController(text: '0'),
       descriptionCtrl = descriptionCtrl ?? TextEditingController(),
       rateFocus = FocusNode();

  void dispose() {
    quantityCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
    fQtyCtrl.dispose();
    mrpCtrl.dispose();
    descriptionCtrl.dispose();
    rateFocus.dispose();
  }
}

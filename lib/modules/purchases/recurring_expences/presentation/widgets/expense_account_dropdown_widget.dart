import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'account_tree_dropdown_with_add_widget.dart';

class ExpenseAccountDropdownWidget extends StatelessWidget {
  final String? value;
  final List<AccountNode> nodes;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onAddAccount;
  final String? hint;
  final BorderRadius? borderRadius;

  const ExpenseAccountDropdownWidget({
    super.key,
    required this.value,
    required this.nodes,
    required this.onChanged,
    this.onAddAccount,
    this.hint = 'Select an account',
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AccountTreeDropdownWithAddButton(
      value: value,
      nodes: nodes,
      onChanged: onChanged,
      onAddAccount: onAddAccount,
      hint: hint,
      borderRadius: borderRadius,
      height: 32,
    );
  }
}

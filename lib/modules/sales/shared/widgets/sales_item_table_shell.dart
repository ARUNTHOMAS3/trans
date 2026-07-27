import 'package:flutter/material.dart';

class SalesItemTableSectionBar extends StatelessWidget {
  final Widget title;
  final Widget? trailing;

  const SalesItemTableSectionBar({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          title,
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SalesItemTableHeaderFrame extends StatelessWidget {
  final double leadingWidth;
  final Widget child;

  const SalesItemTableHeaderFrame({
    super.key,
    this.leadingWidth = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        border: Border(
          left: BorderSide(color: Color(0xFFE5E7EB)),
          right: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: child,
    );
  }
}

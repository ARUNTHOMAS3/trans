import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Reusable ERP Data Table Shell.
///
/// Wraps a list of items in a bordered container with a header and divider.
///
/// Usage:
/// ```dart
/// ZDataTableShell(
///   header: ZTableHeader(
///     children: [
///       ZTableCell(flex: 4, child: Text('Name')),
///       ZTableCell(flex: 2, child: Text('Price')),
///     ],
///   ),
///   rows: items.map((item) => ...).toList(),
/// )
/// ```
class ZDataTableShell extends StatelessWidget {
  final Widget header;
  final List<Widget> rows;
  final Widget? body;
  final EdgeInsets? padding;

  const ZDataTableShell({
    super.key,
    required this.header,
    this.rows = const [],
    this.body,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.space8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 1),
          if (body != null) Expanded(child: body!) else ...rows,
        ],
      ),
    );
  }
}

/// Standardized Header for ERP tables.
class ZTableHeader extends StatelessWidget {
  final List<Widget> children;
  final double? horizontalPadding;

  const ZTableHeader({
    super.key,
    required this.children,
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      child: Row(children: children),
    );
  }
}

/// Generic Layout for Data Rows in ERP tables.
///
/// Ensures consistent vertical padding and alignment.
class ZTableRowLayout extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback? onTap;
  final double? horizontalPadding;
  final double? verticalPadding;

  const ZTableRowLayout({
    super.key,
    required this.children,
    this.onTap,
    this.horizontalPadding,
    this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding ?? AppTheme.space20,
          vertical: verticalPadding ?? AppTheme.space16,
        ),
        child: Row(children: children),
      ),
    );
  }
}

/// Cell wrapper for Data Table rows.
///
/// Use [flex] to match column widths between header and rows.
class ZTableCell extends StatelessWidget {
  final Widget child;
  final int flex;

  const ZTableCell({super.key, required this.child, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: child);
  }
}

import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZTableHelpers {
  /// Builds a standard header row exactly like Zoho
  static Widget buildHeaderRow({
    required List<Widget> children,
    double height = 40,
  }) {
    return Container(
      height: height,
      color: AppTheme.tableHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: children,
      ),
    );
  }

  /// Builds a standard data row exactly like Zoho
  static Widget buildDataRow({
    required Widget child,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isLast = false,
    double height = 52,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.selectionActiveBg : Colors.white,
          border: isLast 
              ? null 
              : const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: child,
      ),
    );
  }

  /// Avatar circle helper
  static Widget buildAvatar(String name, {double radius = 14}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF0F4FF),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.8,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  /// Unified status badge
  static Widget buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.successBg : AppTheme.errorBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: isActive ? AppTheme.successDark : AppTheme.errorRedDark,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static const headerTextStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF666666),
  );
}

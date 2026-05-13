import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class DefaultTaxRatesSection extends StatefulWidget {
  final String? intraStateRateId;
  final String? interStateRateId;
  final List<TaxRate> taxRates;
  final List<TaxRate> taxGroups;

  final void Function(String? intra, String? inter) onChanged;

  const DefaultTaxRatesSection({
    super.key,
    required this.intraStateRateId,
    required this.interStateRateId,
    required this.taxRates,
    required this.taxGroups,
    required this.onChanged,
  });

  @override
  State<DefaultTaxRatesSection> createState() => _DefaultTaxRatesSectionState();
}

class _DefaultTaxRatesSectionState extends State<DefaultTaxRatesSection> {
  bool _isEditing = false;

  String? _intraRateId;
  String? _interRateId;

  @override
  void initState() {
    super.initState();
    _intraRateId = widget.intraStateRateId;
    _interRateId = widget.interStateRateId;
    _applyDefaultRateIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DefaultTaxRatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intraStateRateId != widget.intraStateRateId ||
        oldWidget.interStateRateId != widget.interStateRateId) {
      _intraRateId = widget.intraStateRateId;
      _interRateId = widget.interStateRateId;
    }
    if (oldWidget.taxRates != widget.taxRates ||
        oldWidget.taxGroups != widget.taxGroups) {
      _applyDefaultRateIfNeeded();
    }
  }

  void _notifyParent() => widget.onChanged(_intraRateId, _interRateId);

  void _applyDefaultRateIfNeeded() {
    if (_intraRateId != null && _interRateId != null) return;

    String? findDefaultIntraId() {
      if (widget.taxGroups.isEmpty) return null;
      // Find GST12 for intra-state
      for (final rate in widget.taxGroups) {
        if (rate.taxName == 'GST12') return rate.id;
      }
      return null;
    }

    String? findDefaultInterId() {
      if (widget.taxRates.isEmpty) return null;
      // Find IGST12 for interstate
      for (final rate in widget.taxRates) {
        if (rate.taxName == 'IGST12') return rate.id;
      }
      return null;
    }

    final defaultIntraId = findDefaultIntraId();
    final defaultInterId = findDefaultInterId();

    bool updated = false;
    if (_intraRateId == null && defaultIntraId != null) {
      _intraRateId = defaultIntraId;
      updated = true;
    }
    if (_interRateId == null && defaultInterId != null) {
      _interRateId = defaultInterId;
      updated = true;
    }

    if (updated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notifyParent();
      });
    }
  }

  String _getTaxName(String? id, bool isInterstate) {
    if (id == null) return '-';
    final list = isInterstate ? widget.taxRates : widget.taxGroups;
    if (list.isEmpty) return '-';
    try {
      final rate = list.firstWhere((t) => t.id == id);
      final rateStr = rate.taxRate % 1 == 0
          ? rate.taxRate.toInt().toString()
          : rate.taxRate.toString();
      return '${rate.taxName} [$rateStr%]';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Default Tax Rates',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 16,
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 12),

            _buildResponsiveRow(
              label: 'Intra State Tax Rate',
              tooltip:
                  'Intra state tax rate can be used when transactions raised for contacts within your home state.',
              valueId: _intraRateId,
              isInterstate: false,
              onChanged: (v) {
                setState(() => _intraRateId = v);
                _notifyParent();
              },
            ),

            const SizedBox(height: 16),

            _buildResponsiveRow(
              label: 'Inter State Tax Rate',
              tooltip:
                  'Inter state tax rate can be used when transactions raised for contacts outside your home state.',
              valueId: _interRateId,
              isInterstate: true,
              onChanged: (v) {
                setState(() => _interRateId = v);
                _notifyParent();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveRow({
    required String label,
    required String? valueId,
    required ValueChanged<String?> onChanged,
    String? tooltip,
    bool isInterstate = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool narrow = constraints.maxWidth < 500;

        final labelWidget = tooltip != null
            ? ZTooltip(
                message: tooltip,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSubtle,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dashed,
                    decorationColor: AppTheme.borderColor,
                  ),
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSubtle),
              );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: 6),
              _buildValueEditor(valueId, onChanged, isInterstate: isInterstate),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: 130, child: labelWidget),
            const SizedBox(width: 24),
            SizedBox(
              width: 260,
              child: _buildValueEditor(
                valueId,
                onChanged,
                isInterstate: isInterstate,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildValueEditor(
    String? valueId,
    ValueChanged<String?> onChanged, {
    bool isInterstate = false,
  }) {
    if (!_isEditing) {
      return Text(
        _getTaxName(valueId, isInterstate),
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      );
    }

    final list = isInterstate
        ? widget.taxRates.where((t) => t.taxType == 'IGST').toList()
        : widget.taxGroups;

    final headerText = isInterstate ? 'Tax' : 'Tax Group';

    return FormDropdown<String>(
      value: valueId,
      items: list.map((t) => t.id).toList(),
      hint: 'Select tax rate',
      allowClear: false,
      onChanged: onChanged,
      displayStringForValue: (id) => _getTaxName(id, isInterstate),
      listBuilder: (items, itemBuilder) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  headerText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              ...items.map((id) => itemBuilder(id)).toList(),
            ],
          ),
        );
      },
      itemBuilder: (id, isSelected, isHovered) {
        final name = _getTaxName(id, isInterstate);
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryBlueDark
                : isSelected
                ? AppTheme.infoBg
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHovered
                        ? Colors.white
                        : isSelected
                        ? AppTheme.primaryBlueDark
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: isHovered ? Colors.white : AppTheme.primaryBlueDark,
                ),
            ],
          ),
        );
      },
    );
  }
}

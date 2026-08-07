import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

/// Reusable Tax Preferences Popover supporting anchored position, triangle arrow pointer,
/// GST Treatment selection with descriptions, GSTIN text field, and permanent setting checkbox.
class TaxPreferencesPopover extends StatefulWidget {
  final Widget child;
  final String initialGstTreatment;
  final String initialGstin;
  final Function(String treatment, String gstin, bool isPermanent) onUpdate;
  final LayerLink? link;
  final Offset offset;

  const TaxPreferencesPopover({
    super.key,
    required this.child,
    required this.initialGstTreatment,
    this.initialGstin = '',
    required this.onUpdate,
    this.link,
    this.offset = const Offset(-354, 16),
  });

  @override
  State<TaxPreferencesPopover> createState() => _TaxPreferencesPopoverState();
}

class _TaxPreferencesPopoverState extends State<TaxPreferencesPopover> {
  OverlayEntry? _overlayEntry;
  late final LayerLink _internalLink;

  @override
  void initState() {
    super.initState();
    _internalLink = widget.link ?? LayerLink();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeOverlay,
              child: Container(color: Colors.transparent),
            ),
            CompositedTransformFollower(
              link: _internalLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topLeft,
              offset: widget.offset,
              child: Material(
                color: Colors.transparent,
                child: ConfigureTaxPreferencesDialog(
                  initialTreatment: widget.initialGstTreatment,
                  initialGstin: widget.initialGstin,
                  onClose: _closeOverlay,
                  onUpdate: (treatment, gstin, isPermanent) {
                    widget.onUpdate(treatment, gstin, isPermanent);
                    _closeOverlay();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.link != null) {
      return GestureDetector(
        onTap: _showOverlay,
        child: widget.child,
      );
    }
    return CompositedTransformTarget(
      link: _internalLink,
      child: GestureDetector(
        onTap: _showOverlay,
        child: widget.child,
      ),
    );
  }
}

class ConfigureTaxPreferencesDialog extends ConsumerStatefulWidget {
  final String initialTreatment;
  final String initialGstin;
  final VoidCallback onCancel;
  final Function(String treatment, String gstin, bool isPermanent) onUpdate;

  ConfigureTaxPreferencesDialog({
    super.key,
    String? initialTreatment,
    String? initialGst,
    this.initialGstin = '',
    VoidCallback? onCancel,
    VoidCallback? onClose,
    required this.onUpdate,
  })  : initialTreatment = initialTreatment ?? initialGst ?? 'Unregistered Business',
        onCancel = onCancel ?? onClose ?? (() {});

  VoidCallback get onClose => onCancel;

  @override
  ConsumerState<ConfigureTaxPreferencesDialog> createState() =>
      _ConfigureTaxPreferencesDialogState();
}

class _ConfigureTaxPreferencesDialogState
    extends ConsumerState<ConfigureTaxPreferencesDialog> {
  late String _selectedTreatment;
  late TextEditingController _gstinCtrl;
  bool _makePermanent = false;

  final List<Map<String, String>> _treatments = [
    {
      'label': 'Registered Business - Regular',
      'desc': 'Business that is registered under GST',
    },
    {
      'label': 'Registered Business - Composition',
      'desc': 'Business that is registered under the Composition Scheme in GST',
    },
    {
      'label': 'Unregistered Business',
      'desc': 'Business that has not been registered under GST',
    },
    {
      'label': 'Consumer',
      'desc':
          'Individual or business that is not registered and consumes goods/services',
    },
    {'label': 'Overseas', 'desc': 'Business located outside India'},
    {
      'label': 'Special Economic Zone (SEZ)',
      'desc': 'Business located in a SEZ unit or developer',
    },
    {
      'label': 'Deemed Export',
      'desc':
          'Business involved in supply of goods to certain notified purposes',
    },
  ];

  bool get _isRegistered {
    return _selectedTreatment == 'Registered Business - Regular' ||
        _selectedTreatment == 'Registered Business - Composition' ||
        _selectedTreatment == 'Special Economic Zone (SEZ)' ||
        _selectedTreatment == 'Deemed Export';
  }

  @override
  void initState() {
    super.initState();
    final normalized = widget.initialTreatment.trim();
    if (normalized == 'registered_business_regular') {
      _selectedTreatment = 'Registered Business - Regular';
    } else if (normalized == 'registered_business_composition') {
      _selectedTreatment = 'Registered Business - Composition';
    } else if (normalized == 'unregistered_business') {
      _selectedTreatment = 'Unregistered Business';
    } else if (normalized == 'consumer') {
      _selectedTreatment = 'Consumer';
    } else if (normalized == 'overseas') {
      _selectedTreatment = 'Overseas';
    } else if (normalized == 'special_economic_zone' || normalized == 'sez') {
      _selectedTreatment = 'Special Economic Zone (SEZ)';
    } else if (normalized == 'deemed_export') {
      _selectedTreatment = 'Deemed Export';
    } else {
      _selectedTreatment = widget.initialTreatment;
    }
    _gstinCtrl = TextEditingController(text: widget.initialGstin);
  }

  @override
  void dispose() {
    _gstinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CustomPaint(
            size: const Size(14, 8),
            painter: _TrianglePainter(
              color: Colors.white,
              isUp: true,
              hasBorder: true,
            ),
          ),
        ),
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configure Tax Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GST Treatment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<Map<String, String>>(
                      height: 32,
                      value: _treatments.firstWhere(
                        (t) => t['label'] == _selectedTreatment,
                        orElse: () => _treatments[2],
                      ),
                      items: _treatments,
                      showSearch: false,
                      fillColor: Colors.white,
                      displayStringForValue: (v) => v['label']!,
                      itemBuilder: (item, isSelected, isHovered) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: isHovered
                              ? const Color(0xFF3B82F6)
                              : (isSelected
                                    ? const Color(0xFFF3F4F6)
                                    : Colors.transparent),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isHovered
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : const Color(0xFF6B7280),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTreatment = val['label']!;
                          });
                        }
                      },
                    ),
                    if (_isRegistered) ...[
                      const SizedBox(height: 20),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'GSTIN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: CustomTextField(
                          controller: _gstinCtrl,
                          hintText: 'Enter GSTIN',
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Get Taxpayer details',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Make it permanent?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _makePermanent,
                            onChanged: (val) =>
                                setState(() => _makePermanent = val!),
                            activeColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Use these settings for all future transactions of this contact.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          widget.onUpdate(_selectedTreatment, _gstinCtrl.text.trim(), _makePermanent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF19A05E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isUp;
  final bool hasBorder;

  _TrianglePainter({
    required this.color,
    this.isUp = true,
    this.hasBorder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();

    canvas.drawPath(path, paint);

    if (hasBorder) {
      final borderPaint = Paint()
        ..color = const Color(0xFFDDDDDD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final borderPath = Path();
      if (isUp) {
        borderPath.moveTo(0, size.height);
        borderPath.lineTo(size.width / 2, 0);
        borderPath.lineTo(size.width, size.height);
      } else {
        borderPath.moveTo(0, 0);
        borderPath.lineTo(size.width / 2, size.height);
        borderPath.lineTo(size.width, 0);
      }
      canvas.drawPath(borderPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isUp != isUp ||
        oldDelegate.hasBorder != hasBorder;
  }
}

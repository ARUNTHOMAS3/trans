import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/providers/gst_treatments_provider.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class TaxPreferencesPopover extends StatefulWidget {
  final Widget child;
  final String initialGstTreatment;
  final ValueChanged<String> onUpdate;

  const TaxPreferencesPopover({
    super.key,
    required this.child,
    required this.initialGstTreatment,
    required this.onUpdate,
  });

  @override
  State<TaxPreferencesPopover> createState() => _TaxPreferencesPopoverState();
}

class _TaxPreferencesPopoverState extends State<TaxPreferencesPopover> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: Material(
                color: Colors.transparent,
                child: _TaxPreferencesPopoverContent(
                  initialGstTreatment: widget.initialGstTreatment,
                  onClose: _closeOverlay,
                  onUpdate: (val) {
                    widget.onUpdate(val);
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
  void deactivate() {
    _closeOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _showOverlay,
        child: widget.child,
      ),
    );
  }
}

class _TaxPreferencesPopoverContent extends ConsumerStatefulWidget {
  final String initialGstTreatment;
  final VoidCallback onClose;
  final ValueChanged<String> onUpdate;

  const _TaxPreferencesPopoverContent({
    required this.initialGstTreatment,
    required this.onClose,
    required this.onUpdate,
  });

  @override
  ConsumerState<_TaxPreferencesPopoverContent> createState() => _TaxPreferencesPopoverContentState();
}

class _TaxPreferencesPopoverContentState extends ConsumerState<_TaxPreferencesPopoverContent> {
  late String _gstTreatment;
  bool _makePermanent = false;

  @override
  void initState() {
    super.initState();
    _gstTreatment = widget.initialGstTreatment;
  }

  @override
  Widget build(BuildContext context) {
    final gstTreatmentsAsyncValue = ref.watch(gstTreatmentsProvider);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), 
            blurRadius: 10, 
            offset: Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Configure Tax Preferences',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: Color(0xFF374151),
                  ),
                ),
                InkWell(
                  onTap: widget.onClose,
                  child: const Icon(
                    LucideIcons.x,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GST Treatment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                
                gstTreatmentsAsyncValue.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Error: ${err.toString()}', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                  data: (gstTreatments) {
                    // Ensure the initial value is in the list, otherwise clear it or set to first.
                    final items = gstTreatments.map((e) => e['label']?.toString() ?? '').where((e) => e.isNotEmpty).toList();
                    if (_gstTreatment.isNotEmpty && !items.contains(_gstTreatment)) {
                        _gstTreatment = items.isNotEmpty ? items.first : '';
                    }

                    return FormDropdown<String>(
                      value: _gstTreatment.isNotEmpty ? _gstTreatment : null,
                      items: items,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _gstTreatment = val);
                        }
                      },
                      itemBuilder: (item, isSelected, isHovered) {
                        String getSubtitle(String lbl) {
                          switch(lbl) {
                            case 'Registered Business - Regular': return 'Business that is registered under GST';
                            case 'Registered Business - Composition': return 'Business that is registered under the Composition Scheme in GST';
                            case 'Unregistered Business': return 'Business that has not been registered under GST';
                            case 'Overseas': return 'Persons or businesses located outside India';
                            case 'Special Economic Zone': return 'Business that is located in a Special Economic Zone';
                            case 'Deemed Export': return 'Supply of goods to EOU / STP / EHTP / BTP';
                            default: return '';
                          }
                        }
                        final subtitle = getSubtitle(item);
                        final hasSubtitle = subtitle.isNotEmpty;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: isSelected
                              ? const Color(0xFF3B82F6) // Blue for selected per rules
                              : (isHovered ? const Color(0xFFEFF6FF) : Colors.transparent),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Inter',
                                        color: isSelected ? Colors.white : const Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check, size: 14, color: Colors.white),
                                ],
                              ),
                              if (hasSubtitle) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Inter',
                                    color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'Make it permanent?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: Checkbox(
                        value: _makePermanent,
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _makePermanent = val);
                          }
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Use these settings for all future transactions of this vendor.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                          fontFamily: 'Inter',
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    InkWell(
                      onTap: () => widget.onUpdate(_gstTreatment),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Green button exactly like screenshot
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


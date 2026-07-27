import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';

enum RetainerInvoicesSettingsTab {
  preferences,
  approvals,
  fields,
  salesOrderCycle,
  validationRules,
  recordLocking,
  statuses,
  buttons,
  relatedLists,
}

class RetainerInvoicesSettingsPage extends ConsumerStatefulWidget {
  const RetainerInvoicesSettingsPage({
    super.key,
    this.initialTab = RetainerInvoicesSettingsTab.preferences,
  });

  final RetainerInvoicesSettingsTab initialTab;

  @override
  ConsumerState<RetainerInvoicesSettingsPage> createState() =>
      _RetainerInvoicesSettingsPageState();
}

class _RetainerInvoicesSettingsPageState
    extends ConsumerState<RetainerInvoicesSettingsPage> {
  final SettingsPreferencesRepository _preferencesRepository =
      SettingsPreferencesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _customerNotesController =
      TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  late RetainerInvoicesSettingsTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _preferencesRepository.loadSection(
        'pdf_preferences',
        const ['documents', 'retainer_invoices'],
      );
      if (!mounted || data.isEmpty) return;
      setState(() {
        _termsController.text = data['terms']?.toString() ?? '';
        _customerNotesController.text =
            data['customer_notes']?.toString() ?? '';
      });
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(
          context,
          'Failed to load retainer invoice preferences',
        );
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _preferencesRepository.saveSection(
        'pdf_preferences',
        {
          'terms': _termsController.text,
          'customer_notes': _customerNotesController.text,
        },
        const ['documents', 'retainer_invoices'],
      );
      if (mounted)
        ZerpaiToast.success(context, 'Retainer Invoices preferences saved');
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(
          context,
          'Failed to save retainer invoice preferences',
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _termsController.dispose();
    _customerNotesController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Retainer Invoices',
        label: 'Preferences',
        subtitle: 'Retainer Invoices',
        keywords: const <String>['retainer invoices', 'preferences'],
        onSelected: () => _openTab(RetainerInvoicesSettingsTab.preferences),
      ),
      SettingsSearchItem(
        group: 'Retainer Invoices',
        label: 'Approvals',
        subtitle: 'Retainer Invoices',
        keywords: const <String>['approvals'],
        onSelected: () => _openTab(RetainerInvoicesSettingsTab.approvals),
      ),
      SettingsSearchItem(
        group: 'Retainer Invoices',
        label: 'Fields',
        subtitle: 'Retainer Invoices',
        keywords: const <String>['fields'],
        onSelected: () => _openTab(RetainerInvoicesSettingsTab.fields),
      ),
      SettingsSearchItem(
        group: 'Retainer Invoices',
        label: 'Buttons',
        subtitle: 'Retainer Invoices',
        keywords: const <String>['buttons'],
        onSelected: () => _openTab(RetainerInvoicesSettingsTab.buttons),
      ),
      SettingsSearchItem(
        group: 'Retainer Invoices',
        label: 'Related Lists',
        subtitle: 'Retainer Invoices',
        keywords: const <String>['related lists'],
        onSelected: () => _openTab(RetainerInvoicesSettingsTab.relatedLists),
      ),
    ];
  }

  void _openTab(RetainerInvoicesSettingsTab tab) {
    if (_activeTab != tab) {
      setState(() => _activeTab = tab);
    }
    context.go(_withOrgPrefix(AppRoutes.settingsRetainerInvoices));
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: ColoredBox(
        color: const Color(0xFFF7F8FC),
        child: Column(
          children: [
            _RetainerInvoicesSettingsHeader(
              orgName: orgName,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchItems: _buildSearchItems(),
              onBack: () => context.go(_withOrgPrefix(AppRoutes.settings)),
              onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsNavigationSidebar(
                    currentPath: GoRouterState.of(context).uri.path,
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _RetainerInvoicesPageTitle(),
                          _RetainerInvoicesTabsRow(
                            activeTab: _activeTab,
                            onTabSelected: _openTab,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.borderLight,
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _contentScrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _contentScrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  18,
                                  22,
                                  34,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1120,
                                    ),
                                    child: _RetainerInvoicesPreferencesContent(
                                      termsController: _termsController,
                                      customerNotesController:
                                          _customerNotesController,
                                      onSave: _savePreferences,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetainerInvoicesPreferencesContent extends StatelessWidget {
  const _RetainerInvoicesPreferencesContent({
    required this.termsController,
    required this.customerNotesController,
    required this.onSave,
  });

  final TextEditingController termsController;
  final TextEditingController customerNotesController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 875,
          child: TextField(
            controller: termsController,
            maxLines: 9,
            style: AppTheme.bodyText.copyWith(fontSize: 14),
            decoration: _textAreaDecoration(''),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Customer Notes',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 875,
          child: TextField(
            controller: customerNotesController,
            maxLines: 9,
            style: AppTheme.bodyText.copyWith(fontSize: 14),
            decoration: _textAreaDecoration(''),
          ),
        ),
        const SizedBox(height: 34),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        const SizedBox(height: 34),
        SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: AppTheme.bodyText.copyWith(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _textAreaDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTheme.bodyText.copyWith(
      color: const Color(0xFF8E95B2),
      fontSize: 14,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD8DDF0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.primaryBlue),
    ),
  );
}

class _AdvancedLabelColorPalette extends StatefulWidget {
  const _AdvancedLabelColorPalette({
    required this.colors,
    required this.initialColor,
    required this.onClose,
    required this.onColorTap,
  });

  final List<Color> colors;
  final Color initialColor;
  final VoidCallback onClose;
  final ValueChanged<Color> onColorTap;

  @override
  State<_AdvancedLabelColorPalette> createState() =>
      _AdvancedLabelColorPaletteState();
}

class _AdvancedLabelColorPaletteState
    extends State<_AdvancedLabelColorPalette> {
  late final TextEditingController _hexController;
  late HSVColor _currentHsv;
  bool _showCustomColorDropdown = false;
  bool _showExpandedPicker = false;

  @override
  void initState() {
    super.initState();
    _currentHsv = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(
      text: _colorToHex(widget.initialColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color _parsedHexColor() {
    final raw = _hexController.text.trim().replaceAll('#', '');
    if (raw.length != 6) return _currentHsv.toColor();
    final value = int.tryParse('FF$raw', radix: 16);
    if (value == null) return _currentHsv.toColor();
    return Color(value);
  }

  String _colorToHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  void _syncHexFromCurrentColor() {
    final nextValue = _colorToHex(_currentHsv.toColor());
    if (_hexController.text.toLowerCase() == nextValue.toLowerCase()) return;
    _hexController.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
  }

  void _setColor(Color color) {
    setState(() {
      _currentHsv = HSVColor.fromColor(color).withAlpha(1);
      _syncHexFromCurrentColor();
    });
  }

  void _setHue(double hue) {
    setState(() {
      _currentHsv = _currentHsv.withHue(hue.clamp(0, 360).toDouble());
      _syncHexFromCurrentColor();
    });
  }

  void _setSaturationValue(double saturation, double value) {
    setState(() {
      _currentHsv = _currentHsv
          .withSaturation(saturation.clamp(0, 1).toDouble())
          .withValue(value.clamp(0, 1).toDouble());
      _syncHexFromCurrentColor();
    });
  }

  void _handleHexChanged(String value) {
    final raw = value.trim().replaceAll('#', '');
    if (raw.length != 6) return;
    final parsed = int.tryParse('FF$raw', radix: 16);
    if (parsed == null) return;
    setState(() {
      _currentHsv = HSVColor.fromColor(Color(parsed)).withAlpha(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 340,
        height: 560,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -6,
                    left: 48,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFDADFEA)),
                          left: BorderSide(color: Color(0xFFDADFEA)),
                        ),
                      ),
                      transform: Matrix4.rotationZ(-0.785398),
                    ),
                  ),
                  Container(
                    width: 198,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDADFEA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: widget.onClose,
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 11,
                          runSpacing: 16,
                          children: widget.colors
                              .map(
                                (color) => InkWell(
                                  onTap: () {
                                    _setColor(color);
                                    widget.onColorTap(color);
                                  },
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showCustomColorDropdown =
                                  !_showCustomColorDropdown;
                              if (!_showCustomColorDropdown) {
                                _showExpandedPicker = false;
                              }
                            });
                          },
                          child: Text(
                            'Choose Custom Color >',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13.5,
                              color: const Color(0xFF245EF0),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_showCustomColorDropdown)
              Positioned(
                left: 6,
                top: 180,
                child: _CustomColorEntryDropdown(
                  controller: _hexController,
                  previewColor: _currentHsv.toColor(),
                  onChanged: _handleHexChanged,
                  onArrowTap: () {
                    setState(() {
                      _showExpandedPicker = !_showExpandedPicker;
                    });
                  },
                  onOk: () => widget.onColorTap(_parsedHexColor()),
                  onCancel: () {
                    setState(() {
                      _showCustomColorDropdown = false;
                      _showExpandedPicker = false;
                    });
                  },
                ),
              ),
            if (_showCustomColorDropdown && _showExpandedPicker)
              Positioned(
                left: 66,
                top: 228,
                child: _ExpandedCustomColorPicker(
                  controller: _hexController,
                  previewColor: _currentHsv.toColor(),
                  hsvColor: _currentHsv,
                  onHexChanged: _handleHexChanged,
                  onHueChanged: _setHue,
                  onSaturationValueChanged: _setSaturationValue,
                  onApply: () => widget.onColorTap(_currentHsv.toColor()),
                  onCancel: () {
                    setState(() {
                      _showExpandedPicker = false;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomColorEntryDropdown extends StatelessWidget {
  const _CustomColorEntryDropdown({
    required this.controller,
    required this.previewColor,
    required this.onChanged,
    required this.onArrowTap,
    required this.onOk,
    required this.onCancel,
  });

  final TextEditingController controller;
  final Color previewColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onArrowTap;
  final VoidCallback onOk;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -5,
            left: 108,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFDADFEA)),
                  left: BorderSide(color: Color(0xFFDADFEA)),
                ),
              ),
              transform: Matrix4.rotationZ(-0.785398),
            ),
          ),
          Container(
            width: 180,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDADFEA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD7DCEF)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: onChanged,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                          ),
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF56617D),
                          ),
                        ),
                      ),
                      Container(width: 28, color: previewColor),
                      InkWell(
                        onTap: onArrowTap,
                        child: Container(
                          width: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFFD7DCEF)),
                            ),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: onOk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4B5563),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD5DAE6)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12.5,
                            color: const Color(0xFF4B5563),
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

class _ExpandedCustomColorPicker extends StatelessWidget {
  const _ExpandedCustomColorPicker({
    required this.controller,
    required this.previewColor,
    required this.hsvColor,
    required this.onHexChanged,
    required this.onHueChanged,
    required this.onSaturationValueChanged,
    required this.onApply,
    required this.onCancel,
  });

  final TextEditingController controller;
  final Color previewColor;
  final HSVColor hsvColor;
  final ValueChanged<String> onHexChanged;
  final ValueChanged<double> onHueChanged;
  final void Function(double saturation, double value) onSaturationValueChanged;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  void _handleSquareInteraction(Offset localPosition, Size size) {
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    onSaturationValueChanged(saturation, value);
  }

  void _handleHueInteraction(Offset localPosition, Size size) {
    final hue = ((localPosition.dx / size.width).clamp(0.0, 1.0)) * 360;
    onHueChanged(hue);
  }

  @override
  Widget build(BuildContext context) {
    final hueOnlyColor = HSVColor.fromAHSV(1, hsvColor.hue, 1, 1).toColor();
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            left: 100,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFDADFEA)),
                  left: BorderSide(color: Color(0xFFDADFEA)),
                ),
              ),
              transform: Matrix4.rotationZ(-0.785398),
            ),
          ),
          Container(
            width: 254,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDADFEA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    const squareHeight = 148.0;
                    const squareWidth = 234.0;
                    final markerLeft = (hsvColor.saturation * squareWidth)
                        .clamp(0.0, squareWidth)
                        .toDouble();
                    final markerTop = ((1 - hsvColor.value) * squareHeight)
                        .clamp(0.0, squareHeight)
                        .toDouble();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (details) => _handleSquareInteraction(
                        details.localPosition,
                        const Size(squareWidth, squareHeight),
                      ),
                      onPanUpdate: (details) => _handleSquareInteraction(
                        details.localPosition,
                        const Size(squareWidth, squareHeight),
                      ),
                      onTapDown: (details) => _handleSquareInteraction(
                        details.localPosition,
                        const Size(squareWidth, squareHeight),
                      ),
                      child: SizedBox(
                        width: squareWidth,
                        height: squareHeight,
                        child: Stack(
                          children: [
                            Container(
                              width: squareWidth,
                              height: squareHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: hueOnlyColor,
                              ),
                            ),
                            Container(
                              width: squareWidth,
                              height: squareHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: <Color>[
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: squareWidth,
                              height: squareHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.transparent,
                                    Colors.black,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: markerLeft - 7,
                              top: markerTop - 7,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.24,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    final markerLeft = ((hsvColor.hue / 360) * barWidth)
                        .clamp(0.0, barWidth)
                        .toDouble();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (details) => _handleHueInteraction(
                        details.localPosition,
                        Size(barWidth, 8),
                      ),
                      onPanUpdate: (details) => _handleHueInteraction(
                        details.localPosition,
                        Size(barWidth, 8),
                      ),
                      onTapDown: (details) => _handleHueInteraction(
                        details.localPosition,
                        Size(barWidth, 8),
                      ),
                      child: SizedBox(
                        height: 14,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 3,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      Colors.red,
                                      Colors.yellow,
                                      Colors.green,
                                      Colors.cyan,
                                      Colors.blue,
                                      Color(0xFFFF00FF),
                                      Colors.red,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: markerLeft - 7,
                              top: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: HSVColor.fromAHSV(
                                    1,
                                    hsvColor.hue,
                                    1,
                                    1,
                                  ).toColor(),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF6FA1FF)),
                        ),
                        child: TextField(
                          controller: controller,
                          onChanged: onHexChanged,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF56617D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 58,
                      height: 34,
                      decoration: BoxDecoration(
                        color: previewColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE7EAF3)),
                      bottom: BorderSide(color: Color(0xFFE7EAF3)),
                    ),
                  ),
                  child: Text(
                    'Swatches >',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13.5,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: onApply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4B5563),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD5DAE6)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13.5,
                            color: const Color(0xFF4B5563),
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

class _RetainerInvoicesSettingsHeader extends StatelessWidget {
  const _RetainerInvoicesSettingsHeader({
    required this.orgName,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchItems,
    required this.onBack,
    required this.onClose,
  });

  final String orgName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFFFF5D5D),
              size: 24,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            color: AppTheme.borderLight,
          ),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8DDF0)),
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Settings',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                orgName,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 320,
            child: SettingsSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              items: searchItems,
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Text(
                    'Close Settings',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.close, size: 14, color: Color(0xFFFF5C73)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetainerInvoicesPageTitle extends StatelessWidget {
  const _RetainerInvoicesPageTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Retainer Invoices',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetainerInvoicesTabsRow extends StatelessWidget {
  const _RetainerInvoicesTabsRow({
    required this.activeTab,
    required this.onTabSelected,
  });

  final RetainerInvoicesSettingsTab activeTab;
  final ValueChanged<RetainerInvoicesSettingsTab> onTabSelected;

  static const List<(String, RetainerInvoicesSettingsTab)> _tabs =
      <(String, RetainerInvoicesSettingsTab)>[
        ('Preferences', RetainerInvoicesSettingsTab.preferences),
        ('Approvals', RetainerInvoicesSettingsTab.approvals),
        ('Fields', RetainerInvoicesSettingsTab.fields),
        ('Buttons', RetainerInvoicesSettingsTab.buttons),
        ('Related Lists', RetainerInvoicesSettingsTab.relatedLists),
      ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final (label, tab) = _tabs[index];
          final isActive = tab == activeTab;
          return InkWell(
            onTap: () => onTabSelected(tab),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: isActive
                      ? const Border(
                          bottom: BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: isActive
                        ? AppTheme.textPrimary
                        : const Color(0xFF56617D),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

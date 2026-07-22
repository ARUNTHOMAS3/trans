import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';

enum TaxImportKind { tax, taxGroup }

class SettingsTaxImportPage extends ConsumerStatefulWidget {
  const SettingsTaxImportPage({super.key, this.importKind = TaxImportKind.tax});

  final TaxImportKind importKind;

  @override
  ConsumerState<SettingsTaxImportPage> createState() =>
      _SettingsTaxImportPageState();
}

class _SettingsTaxImportPageState extends ConsumerState<SettingsTaxImportPage> {
  int _currentStep = 1;
  String? _selectedFileName;
  double? _selectedFileSize;
  String _characterEncoding = 'UTF-8 (Unicode)';

  // Mapping state variables
  String? _taxTypeMapping;
  String? _taxSpecificTypeMapping;
  String? _taxDisplayNameMapping;
  String? _taxNameMapping;
  String? _taxPercentageMapping;
  String? _taxGroupNameMapping;
  String? _accountMapping;
  String? _startDateMapping;
  String? _endDateMapping;
  String _startDateType = 'yyyy-MM-dd';
  String _endDateType = 'yyyy-MM-dd';
  bool _saveSelections = false;

  bool get _isTaxGroupImport => widget.importKind == TaxImportKind.taxGroup;
  String get _importSubject => _isTaxGroupImport ? 'Tax Group' : 'Taxes';
  String get _importSuccessSubject =>
      _isTaxGroupImport ? 'Tax groups' : 'Taxes';

  final List<String> _importedFileHeaders = [
    'Tax Group Name',
    'Tax Name',
    'Rate',
    'Tax Type',
    'Specific Type',
    'Display Name',
    'Account',
    'Start Date',
    'End Date',
    'Description',
  ];

  void _initializeMappings() {
    _taxNameMapping = 'Tax Name';
    _taxPercentageMapping = 'Rate';
    _taxGroupNameMapping = _isTaxGroupImport ? 'Tax Group Name' : null;
    _taxTypeMapping = 'Tax Type';
    _taxSpecificTypeMapping = 'Specific Type';
    _taxDisplayNameMapping = 'Display Name';
    _accountMapping = 'Account';
    _startDateMapping = 'Start Date';
    _endDateMapping = 'End Date';
  }

  String get _orgSystemId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  void _cancel() {
    context.go('/$_orgSystemId${AppRoutes.settingsTaxes}');
  }

  Future<void> _pickFile({String source = 'File'}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv', 'xls', 'xlsx'],
        allowMultiple: false,
        withData: true,
      );

      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() {
        _selectedFileName = file.name;
        _selectedFileSize = file.size / 1024;
      });

      if (mounted) {
        ZerpaiToast.success(context, 'Uploaded $source: ${file.name}');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to pick file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final orgName =
        ref.watch(authUserProvider)?.orgName.trim() ?? 'ORGANIZATION';

    final stepTitles = [
      '$_importSubject - Select File',
      _isTaxGroupImport ? 'Map Fields' : '$_importSubject - Map Fields',
      _isTaxGroupImport ? 'Preview' : '$_importSubject - Preview',
    ];
    final subHeaderTitle = stepTitles[_currentStep - 1];

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSettingsSidebar = constraints.maxWidth >= 980;
        return Column(
          children: [
            SettingsPageHeader(
              orgName: orgName,
              searchItems: [
                SettingsSearchItem(
                  group: 'Taxes & Compliance',
                  label: 'Taxes',
                  onSelected: _cancel,
                ),
              ],
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSettingsSidebar)
                    SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: ColoredBox(
                      color: AppTheme.bgDisabled,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: ColoredBox(
                            color: Colors.white,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildSubHeader(subHeaderTitle),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 60,
                                            vertical: 30,
                                          ),
                                          child: Center(
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: _currentStep == 2
                                                    ? 860
                                                    : _currentStep == 3
                                                    ? 700
                                                    : 720,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (!_isTaxGroupImport) ...[
                                                    Center(
                                                      child: _buildStepper(),
                                                    ),
                                                    const SizedBox(height: 24),
                                                  ],
                                                  if (_currentStep == 1) ...[
                                                    _buildDropzone(),
                                                    _buildSampleFileLink(),
                                                    const SizedBox(height: 40),
                                                    _buildEncodingRow(),
                                                    const SizedBox(height: 40),
                                                    _buildTipsCard(),
                                                    const SizedBox(height: 48),
                                                  ] else if (_currentStep ==
                                                      2) ...[
                                                    ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                            maxWidth: 860,
                                                          ),
                                                      child:
                                                          _buildMapFieldsContent(),
                                                    ),
                                                    const SizedBox(height: 48),
                                                  ] else ...[
                                                    _buildPreviewContent(),
                                                    const SizedBox(height: 48),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      _buildFooter(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubHeader(String title) {
    if (_isTaxGroupImport) {
      return Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStepper(verticalPadding: 0),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  color: AppTheme.errorRed,
                  size: 20,
                ),
                onPressed: _cancel,
                hoverColor: AppTheme.bgHover,
                splashRadius: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, color: AppTheme.errorRed, size: 20),
            onPressed: _cancel,
            hoverColor: AppTheme.bgHover,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ── Stepper ──────────────────────────────────────────────────────────────

  Widget _buildStepper({double verticalPadding = 24}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepItem(1, 'Configure'),
          _stepDivider(),
          _stepItem(2, 'Map Fields'),
          _stepDivider(),
          _stepItem(3, 'Preview'),
        ],
      ),
    );
  }

  Widget _stepItem(int stepNumber, String label) {
    final bool isCompleted = stepNumber < _currentStep;
    final bool isActive = stepNumber == _currentStep;
    final activeColor = const Color(0xFF1F6FEB);
    final completedColor = const Color(0xFF22B378);
    final inactiveColor = const Color(0xFF9CA3AF);

    Color circleColor;
    if (isCompleted) {
      circleColor = completedColor;
    } else if (isActive) {
      circleColor = activeColor;
    } else {
      circleColor = Colors.transparent;
    }

    Widget circleContent;
    if (isCompleted) {
      circleContent = const Icon(Icons.check, color: Colors.white, size: 13);
    } else {
      circleContent = Text(
        stepNumber.toString(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : inactiveColor,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? activeColor
                  : isCompleted
                  ? completedColor
                  : inactiveColor,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: circleContent,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: (isActive || isCompleted)
                ? FontWeight.w600
                : FontWeight.w500,
            color: isActive
                ? Colors.black
                : isCompleted
                ? const Color(0xFF374151)
                : inactiveColor,
          ),
        ),
      ],
    );
  }

  Widget _stepDivider() {
    return Container(
      width: 48,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFE5E7EB),
    );
  }

  // ── Step 1: Select File ───────────────────────────────────────────────────

  Widget _buildDropzone() {
    return CustomPaint(
      painter: DashedRectPainter(
        color: const Color(0xFFD1D5DB),
        strokeWidth: 1.2,
        gap: 6,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedFileName == null) ...[
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.upload,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Drag and drop file to import',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ] else ...[
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.fileSpreadsheet,
                  color: Color(0xFF22B378),
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedFileName!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Size: ${_selectedFileSize!.toStringAsFixed(1)} KB',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildChooseFileSplitButton(),
            const SizedBox(height: 12),
            const Text(
              'Maximum File Size: 25 MB  •  File Format: CSV or TSV or XLS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChooseFileSplitButton() {
    final Color buttonColor = const Color(0xFF22B378);
    final String buttonLabel = _selectedFileName == null
        ? 'Choose File'
        : 'Replace File';

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () => _pickFile(source: 'File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ),
          Container(
            width: 24,
            height: 32,
            decoration: BoxDecoration(
              color: buttonColor,
              border: const Border(left: BorderSide(color: Colors.white24)),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(4),
              ),
            ),
            child: PopupMenuButton<String>(
              tooltip: '',
              color: Colors.white,
              surfaceTintColor: Colors.white,
              padding: EdgeInsets.zero,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 0),
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 180),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: const SizedBox(
                width: 24,
                height: 32,
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              onSelected: (value) async {
                if (value == 'desktop') {
                  await _pickFile(source: 'Desktop');
                } else if (value == 'cloud') {
                  await _pickFile(source: 'Cloud');
                } else if (value == 'documents') {
                  await _pickFile(source: 'Documents');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'desktop',
                  padding: EdgeInsets.zero,
                  child: _PopupRow(label: 'Attach From Desktop'),
                ),
                PopupMenuItem(
                  value: 'cloud',
                  padding: EdgeInsets.zero,
                  child: _PopupRow(label: 'Attach From Cloud'),
                ),
                PopupMenuItem(
                  value: 'documents',
                  padding: EdgeInsets.zero,
                  child: _PopupRow(label: 'Attach From Documents'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleFileLink() {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      alignment: Alignment.center,
      child: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          text: 'Download a ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF4B5563),
          ),
          children: [
            TextSpan(
              text: 'sample file',
              style: const TextStyle(
                color: Color(0xFF1F6FEB),
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(
              text:
                  ' and compare it to your import file to ensure you have the file perfect for the import.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncodingRow() {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Character Encoding',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 4),
        Icon(LucideIcons.helpCircle, size: 13, color: Colors.grey[400]),
      ],
    );
    final dropdown = FormDropdown<String>(
      value: _characterEncoding,
      items: const [
        'UTF-8 (Unicode)',
        'UTF-16 (Unicode)',
        'ISO-8859-1',
        'ISO-8859-2',
        'ISO-8859-9 (Turkish)',
        'GB2312 (Simplified Chinese)',
        'Big5 (Traditional Chinese)',
      ],
      onChanged: (value) => setState(() {
        _characterEncoding = value ?? 'UTF-8 (Unicode)';
      }),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              const SizedBox(height: 8),
              SizedBox(width: constraints.maxWidth, child: dropdown),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            label,
            const SizedBox(width: 48),
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: 320, child: dropdown),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withAlpha(76),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.lightbulb, color: Color(0xFFD97706), size: 16),
              SizedBox(width: 8),
              Text(
                'Page Tips',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bulletPoint(
            _isTaxGroupImport
                ? 'Import data with the details of GST Treatment by referring these '
                : 'Import tax data by referring these ',
            'accepted formats.',
            true,
          ),
          const SizedBox(height: 8),
          _bulletPoint(
            'If you have files in other formats, you can convert it to an accepted file format using any online/offline converter.',
            '',
            false,
          ),
          const SizedBox(height: 8),
          _bulletPoint(
            'You can configure your import settings and save them for future too!',
            '',
            false,
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String prefix, String linkText, bool hasLink) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: Icon(Icons.circle, size: 4, color: Color(0xFF4B5563)),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: prefix,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
              children: [
                if (hasLink)
                  TextSpan(
                    text: linkText,
                    style: const TextStyle(
                      color: Color(0xFF1F6FEB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Map Fields ────────────────────────────────────────────────────

  Widget _buildMapFieldsContent() {
    if (_isTaxGroupImport) {
      return _buildTaxGroupMapFieldsContent();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File name banner
        RichText(
          text: TextSpan(
            text: 'Your Selected File : ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF374151),
            ),
            children: [
              TextSpan(
                text: _selectedFileName ?? 'No file selected',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Blue auto-selected notice
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F6FEB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'i',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'The best match to each field on the selected file have been auto-selected.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Default Data Formats card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Default Data Formats',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ZerpaiToast.info(
                        context,
                        'Default data formats editing is not available yet.',
                      );
                    },
                    icon: const Icon(LucideIcons.pencil, size: 13),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1F6FEB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Date',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Select format at field level',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Tax Details section
        const Text(
          'Tax Details',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),

        // Mapping rows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _mappingRow(
                'Tax Type',
                _taxTypeMapping,
                (v) => setState(() => _taxTypeMapping = v),
              ),
              _mappingRow(
                'Tax Specific Type',
                _taxSpecificTypeMapping,
                (v) => setState(() => _taxSpecificTypeMapping = v),
              ),
              _mappingRow(
                'Tax Display Name',
                _taxDisplayNameMapping,
                (v) => setState(() => _taxDisplayNameMapping = v),
              ),
              _mappingRowRequired(
                'Tax Name',
                _taxNameMapping,
                (v) => setState(() => _taxNameMapping = v),
              ),
              _mappingRowRequired(
                'Tax Percentage',
                _taxPercentageMapping,
                (v) => setState(() => _taxPercentageMapping = v),
              ),
              _mappingRow(
                'Account To Track Sales',
                _accountMapping,
                (v) => setState(() => _accountMapping = v),
              ),
              _mappingRowDate(
                'Start Date',
                _startDateMapping,
                _startDateType,
                (v) => setState(() => _startDateMapping = v),
                (v) => setState(() => _startDateType = v ?? 'yyyy-MM-dd'),
              ),
              _mappingRowDate(
                'End Date',
                _endDateMapping,
                _endDateType,
                (v) => setState(() => _endDateMapping = v),
                (v) => setState(() => _endDateType = v ?? 'yyyy-MM-dd'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 42),

        // Save checkbox
        Row(
          children: [
            Checkbox(
              value: _saveSelections,
              onChanged: (v) => setState(() => _saveSelections = v ?? false),
              activeColor: const Color(0xFF1F6FEB),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            const Text(
              'Save these selections for use during future imports.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaxGroupMapFieldsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Your Selected File : ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF374151),
            ),
            children: [
              TextSpan(
                text: _selectedFileName ?? 'No file selected',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Color(0xFF4285F4), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The best match to each field on the selected file have been auto-selected.',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Tax Details',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _mappingRowRequired(
                'Tax Group Name',
                _taxGroupNameMapping,
                (v) => setState(() => _taxGroupNameMapping = v),
              ),
              _mappingRowRequired(
                'Tax Name',
                _taxNameMapping,
                (v) => setState(() => _taxNameMapping = v),
              ),
              _mappingRowRequired(
                'Tax Percentage',
                _taxPercentageMapping,
                (v) => setState(() => _taxPercentageMapping = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 42),
        Row(
          children: [
            Checkbox(
              value: _saveSelections,
              onChanged: (v) => setState(() => _saveSelections = v ?? false),
              activeColor: const Color(0xFF1F6FEB),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            const Text(
              'Save these selections for use during future imports.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const double _mapLabelWidth = 210;
  static const double _mapFieldWidth = 288;
  static const double _mapDateFormatWidth = 250;
  static const double _mapDateGap = 28;
  static const double _mapRowHeight = 58;

  Widget _mappingRow(
    String fieldName,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return _mappingRowShell(
      label: _mapLabel(fieldName),
      field: _mapHeaderDropdown(value, onChanged),
    );
  }

  Widget _mappingRowRequired(
    String fieldName,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return _mappingRowShell(
      label: _mapLabel('$fieldName *', isRequired: true),
      field: _mapHeaderDropdown(value, onChanged),
    );
  }

  Widget _mappingRowDate(
    String fieldName,
    String? headerValue,
    String dateFormatValue,
    ValueChanged<String?> onHeaderChanged,
    ValueChanged<String?> onDateFormatChanged,
  ) {
    return _mappingRowShell(
      label: _mapLabel(fieldName),
      field: _mapHeaderDropdown(headerValue, onHeaderChanged),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _mapDateFormatWidth,
            child: FormDropdown<String>(
              value: dateFormatValue,
              items: const [
                'yyyy-MM-dd',
                'dd-MM-yyyy',
                'MM-dd-yyyy',
                'dd/MM/yyyy',
                'MM/dd/yyyy',
                'yyyy/MM/dd',
              ],
              onChanged: onDateFormatChanged,
              height: 42,
              showSearch: false,
              menuWidth: _mapDateFormatWidth,
            ),
          ),
          const SizedBox(width: 16),
          const ZTooltip(
            message: 'Select the date format used by this file column.',
            child: Icon(
              LucideIcons.helpCircle,
              size: 15,
              color: Color(0xFF8A8FA3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mappingRowShell({
    required Widget label,
    required Widget field,
    Widget? trailing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        if (compact) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label,
                const SizedBox(height: 8),
                field,
                if (trailing != null) ...[const SizedBox(height: 8), trailing],
              ],
            ),
          );
        }

        return SizedBox(
          height: _mapRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: _mapLabelWidth, child: label),
              field,
              if (trailing != null) ...[
                const SizedBox(width: _mapDateGap),
                trailing,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _mapLabel(String label, {bool isRequired = false}) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isRequired ? const Color(0xFFFF1F1F) : const Color(0xFF171717),
      ),
    );
  }

  Widget _mapHeaderDropdown(String? value, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: _mapFieldWidth,
      child: FormDropdown<String>(
        value: value,
        hint: 'Select',
        items: _importedFileHeaders,
        onChanged: onChanged,
        height: 42,
        menuWidth: _mapFieldWidth,
      ),
    );
  }

  // ── Step 3: Preview ────────────────────────────────────────────────────────

  Widget _buildPreviewContent() {
    return _buildPreviewSummary();
  }

  Widget _buildPreviewSummary() {
    if (_isTaxGroupImport) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFFF5364),
                      size: 16,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'None of the rows can be imported',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _previewSummaryRow(
                label: 'Tax Group that are ready to be imported',
                count: '',
                warning: false,
                showCount: false,
              ),
              _previewSummaryRow(
                label: 'No. of Records skipped',
                count: '200',
                warning: true,
              ),
              _previewSummaryRow(
                label: 'Unmapped Fields',
                count: '12',
                warning: true,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Color(0xFF4285F4), size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '6 of 7 Taxes in your file are ready to be imported.',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _previewSummaryRow(
              label: 'Taxes that are ready to be imported',
              count: '6',
              warning: false,
            ),
            _previewSummaryRow(
              label: 'No. of Records skipped',
              count: '194',
              warning: true,
            ),
            _previewSummaryRow(
              label: 'Unmapped Fields',
              count: '24',
              warning: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewSummaryRow({
    required String label,
    required String count,
    required bool warning,
    bool showCount = true,
  }) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          if (warning) ...[
            const Icon(
              Icons.warning_rounded,
              color: Color(0xFFF2994A),
              size: 16,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                text: showCount ? '$label  - ' : label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: warning
                      ? const Color(0xFF111111)
                      : const Color(0xFF666666),
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  if (showCount)
                    TextSpan(
                      text: count,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {
              ZerpaiToast.info(
                context,
                '$label details are not available yet.',
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4D90FE),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View Details'),
                SizedBox(width: 4),
                Icon(LucideIcons.chevronDown, size: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget previewRow(String field, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              field,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: value != null
                    ? const Color(0xFF111827)
                    : const Color(0xFF9CA3AF),
                fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    if (_currentStep == 3) {
      return _buildPreviewFooter();
    }

    final bool canNext = _currentStep == 1 ? _selectedFileName != null : true;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          // Previous button (Steps 2+)
          if (_currentStep > 1) ...[
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.chevron_left, size: 16),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Next / Import button
          ElevatedButton(
            onPressed: canNext
                ? () {
                    if (_currentStep == 1) {
                      _initializeMappings();
                      setState(() => _currentStep = 2);
                    } else if (_currentStep == 2) {
                      setState(() => _currentStep = 3);
                    } else {
                      ZerpaiToast.success(
                        context,
                        'Import complete! $_importSuccessSubject have been imported successfully.',
                      );
                      _cancel();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD1FAE5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currentStep == 3 ? 'Import' : 'Next'),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Cancel
          OutlinedButton(
            onPressed: _cancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewFooter() {
    return Container(
      height: 84,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _currentStep--),
                  icon: const Icon(Icons.chevron_left, size: 16),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    ZerpaiToast.success(
                      context,
                      'Import complete! Taxes have been imported successfully.',
                    );
                    _cancel();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('Import'),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111111),
                    side: const BorderSide(color: Color(0xFFDADCE0)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── DashedRectPainter ────────────────────────────────────────────────────────

class DashedRectPainter extends CustomPainter {
  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
  });

  final Color color;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(4),
        ),
      );

    final dashPath = Path();
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final length = gap * 1.5;
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}

// ── _PopupRow ─────────────────────────────────────────────────────────────────

class _PopupRow extends StatefulWidget {
  const _PopupRow({required this.label});

  final String label;

  @override
  State<_PopupRow> createState() => _PopupRowState();
}

class _PopupRowState extends State<_PopupRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        color: _hovered ? const Color(0xFF1F6FEB) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          widget.label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: _hovered ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

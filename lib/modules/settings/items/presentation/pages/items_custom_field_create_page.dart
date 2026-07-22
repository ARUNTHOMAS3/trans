import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';

class SettingsItemsCustomFieldCreatePage extends ConsumerStatefulWidget {
  const SettingsItemsCustomFieldCreatePage({super.key});

  @override
  ConsumerState<SettingsItemsCustomFieldCreatePage> createState() =>
      _SettingsItemsCustomFieldCreatePageState();
}

class _SettingsItemsCustomFieldCreatePageState
    extends ConsumerState<SettingsItemsCustomFieldCreatePage> {
  static const double _formLabelWidth = 210;
  static const double _formColumnGap = 16;
  static const double _formFieldMaxWidth = 322;
  static const double _compactFormBreakpoint = 640;
  static const int _maxDefaultImageBytes = 10 * 1024 * 1024;

  final MenuController _imageUploadMenuController = MenuController();
  final MenuController _addOptionsMenuController = MenuController();
  final MenuController _optionsSettingsMenuController = MenuController();
  final GlobalKey _defaultDateFieldKey = GlobalKey();
  final ScrollController _optionsListScrollController = ScrollController();
  final ScrollController _predefinedOptionsScrollController =
      ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _helpTextController = TextEditingController();
  final TextEditingController _relatedListNameController =
      TextEditingController();
  final TextEditingController _defaultValueController = TextEditingController();
  final TextEditingController _formulaController = TextEditingController();
  final TextEditingController _bulkOptionsController = TextEditingController();
  final TextEditingController _customInputFormatController =
      TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _startingNumberController =
      TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final List<PlatformFile> _defaultImageFiles = <PlatformFile>[];
  final List<TextEditingController> _dropdownOptionControllers =
      List<TextEditingController>.generate(5, (_) => TextEditingController());
  final List<String> _inactiveDropdownOptionValues = <String>[];
  final List<bool> _dropdownOptionSelections = List<bool>.filled(
    5,
    false,
    growable: true,
  );

  String _createCustomFieldFor = 'Item';
  String? _selectedDataType;
  bool _isMandatory = false;
  bool _containsPii = false;
  bool _containsEphi = false;
  bool _preventDuplicateValues = false;
  bool _showWhenCreatingTransactions = false;
  bool _tickedByDefault = false;
  bool _addToExistingItems = false;
  bool _addColorToDropdownOptions = false;
  bool _displayRichTextEditor = false;
  bool _attachmentImage = true;
  bool _attachmentPdf = true;
  bool _attachmentDocument = true;
  bool _attachmentAllFiles = true;
  bool _isImageUploadMenuOpen = false;
  bool _isAddOptionsMenuOpen = false;
  bool _isBulkOptionsMode = false;
  bool _isPredefinedOptionsMode = false;
  bool _isInactiveOptionsMode = false;
  String? _hoveredImageUploadOption;
  String? _hoveredAddOptionsMenuItem;
  String? _hoveredOptionsSettingsMenuItem;
  String? _hoveredDropdownOptionMenuItem;
  int? _hoveredDropdownOptionRowIndex;
  String _selectedImageUploadOption = 'Attach From Desktop';
  String _selectedAddOptionsMenuItem = 'Add options in bulk';
  String? _selectedDropdownOptionMenuKey;
  String? _selectedOptionsSettingsMenuItem;
  String _selectedPredefinedOptionsGroup = 'Days of the Week';
  String? _selectedLookupModule;
  String? _selectedMultiSelectDefaultValue;
  _InputFormatOption? _selectedInputFormat;
  bool _useStandardInputFormat = false;
  String? _selectedFormulaOutputDataType = 'Text Box (Single Line)';
  bool _useRelativeDateDefaultValue = false;
  DateTime? _selectedDefaultDate;
  String? _selectedRelativeDateDefaultOption = 'Today';
  String _selectedLookupDisplayAs = 'Pop-Up';

  static const List<String> _imageUploadOptions = <String>[
    'Attach From Desktop',
    'Attach From Documents',
  ];

  static const List<String> _addOptionsMenuItems = <String>[
    'Add options in bulk',
    'Use Predefined Options',
  ];

  static const List<String> _optionsSettingsMenuItems = <String>[
    'View Inactive Options',
    'Sort',
  ];

  static const List<String> _dropdownOptionRowMenuItems = <String>[
    'Mark as Inactive',
    'Delete',
  ];

  static const Map<String, List<String>> _predefinedOptionsGroups =
      <String, List<String>>{
        'Days of the Week': <String>[
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
        ],
        'Months of the Year': <String>[
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ],
        'Countries': <String>[
          'Afghanistan',
          'Aland Islands',
          'Albania',
          'Algeria',
          'American Samoa',
          'Andorra',
          'Angola',
          'Anguilla',
          'Antarctica',
          'Antigua and Barbuda',
          'Argentina',
          'Armenia',
          'Aruba',
          'Australia',
          'Austria',
          'Azerbaijan',
          'Bahamas',
          'Bahrain',
          'Bangladesh',
          'Barbados',
          'Belarus',
          'Belgium',
          'Belize',
          'Benin',
          'Bermuda',
          'Bhutan',
          'Bolivia',
          'Bosnia and Herzegovina',
          'Botswana',
          'Brazil',
          'British Indian Ocean Territory',
          'Brunei',
          'Bulgaria',
          'Burkina Faso',
          'Burundi',
          'Cambodia',
          'Cameroon',
          'Canada',
          'Cape Verde',
          'Cayman Islands',
          'Central African Republic',
          'Chad',
          'Chile',
          'China',
          'Christmas Island',
          'Cocos Islands',
          'Colombia',
          'Comoros',
          'Congo',
          'Costa Rica',
          'Croatia',
          'Cuba',
          'Curacao',
          'Cyprus',
          'Czech Republic',
          'Denmark',
          'Djibouti',
          'Dominica',
          'Dominican Republic',
          'Ecuador',
          'Egypt',
          'El Salvador',
          'Equatorial Guinea',
          'Eritrea',
          'Estonia',
          'Eswatini',
          'Ethiopia',
          'Falkland Islands',
          'Faroe Islands',
          'Fiji',
          'Finland',
          'France',
          'French Guiana',
          'French Polynesia',
          'Gabon',
          'Gambia',
          'Georgia',
          'Germany',
          'Ghana',
          'Gibraltar',
          'Greece',
          'Greenland',
          'Grenada',
          'Guadeloupe',
          'Guam',
          'Guatemala',
          'Guernsey',
          'Guinea',
          'Guinea-Bissau',
          'Guyana',
          'Haiti',
          'Honduras',
          'Hong Kong',
          'Hungary',
          'Iceland',
          'India',
          'Indonesia',
          'Iran',
          'Iraq',
          'Ireland',
          'Isle of Man',
          'Israel',
          'Italy',
          'Jamaica',
          'Japan',
          'Jersey',
          'Jordan',
          'Kazakhstan',
          'Kenya',
          'Kiribati',
          'Kuwait',
          'Kyrgyzstan',
          'Laos',
          'Latvia',
          'Lebanon',
          'Lesotho',
          'Liberia',
          'Libya',
          'Liechtenstein',
          'Lithuania',
          'Luxembourg',
          'Macao',
          'Madagascar',
          'Malawi',
          'Malaysia',
          'Maldives',
          'Mali',
          'Malta',
          'Marshall Islands',
          'Martinique',
          'Mauritania',
          'Mauritius',
          'Mayotte',
          'Mexico',
          'Micronesia',
          'Moldova',
          'Monaco',
          'Mongolia',
          'Montenegro',
          'Montserrat',
          'Morocco',
          'Mozambique',
          'Myanmar',
          'Namibia',
          'Nauru',
          'Nepal',
          'Netherlands',
          'New Caledonia',
          'New Zealand',
          'Nicaragua',
          'Niger',
          'Nigeria',
          'Niue',
          'North Korea',
          'North Macedonia',
          'Northern Mariana Islands',
          'Norway',
          'Oman',
          'Pakistan',
          'Palau',
          'Palestine',
          'Panama',
          'Papua New Guinea',
          'Paraguay',
          'Peru',
          'Philippines',
          'Poland',
          'Portugal',
          'Puerto Rico',
          'Qatar',
          'Reunion',
          'Romania',
          'Russia',
          'Rwanda',
          'Saint Barthelemy',
          'Saint Helena',
          'Saint Kitts and Nevis',
          'Saint Lucia',
          'Saint Martin',
          'Saint Pierre and Miquelon',
          'Saint Vincent and the Grenadines',
          'Samoa',
          'San Marino',
          'Sao Tome and Principe',
          'Saudi Arabia',
          'Senegal',
          'Serbia',
          'Seychelles',
          'Sierra Leone',
          'Singapore',
          'Sint Maarten',
          'Slovakia',
          'Slovenia',
          'Solomon Islands',
          'Somalia',
          'South Africa',
          'South Korea',
          'South Sudan',
          'Spain',
          'Sri Lanka',
          'Sudan',
          'Suriname',
          'Sweden',
          'Switzerland',
          'Syria',
          'Taiwan',
          'Tajikistan',
          'Tanzania',
          'Thailand',
          'Timor-Leste',
          'Togo',
          'Tokelau',
          'Tonga',
          'Trinidad and Tobago',
          'Tunisia',
          'Turkey',
          'Turkmenistan',
          'Turks and Caicos Islands',
          'Tuvalu',
          'Uganda',
          'Ukraine',
          'United Arab Emirates',
          'United Kingdom',
          'United States',
          'Uruguay',
          'Uzbekistan',
          'Vanuatu',
          'Vatican City',
          'Venezuela',
          'Vietnam',
          'Virgin Islands, British',
          'Virgin Islands, U.S.',
          'Yemen',
          'Zambia',
          'Zimbabwe',
        ],
      };

  static const List<String> _formulaOutputDataTypeOptions = <String>[
    'Text Box (Single Line)',
    'Number',
    'Decimal',
    'Amount',
    'Percent',
    'Date',
    'Date and Time',
    'Check Box',
  ];

  static const List<String> _dataTypeOptions = <String>[
    'Text Box (Single Line)',
    'Email',
    'URL',
    'Phone',
    'Number',
    'Decimal',
    'Amount',
    'Percent',
    'Date',
    'Date and Time',
    'Check Box',
    'Auto-Generate Number',
    'Multi-select',
    'Lookup',
    'Text Box (Multi-line)',
    'Attachment',
    'External Lookup',
    'Multi-select Lookup',
    'Image',
  ];

  static const List<String> _relativeDateDefaultValueOptions = <String>[
    'Today',
    'Tomorrow',
    'Yesterday',
    'Starting Date of Week',
    'Ending Date of Week',
    'Starting Date of Next Week',
    'Ending Date of Next Week',
    'Starting Date of Previous Week',
    'Ending Date of Previous Week',
    'Starting Date of Month',
    'Ending Date of Month',
    'Starting Date of Next Month',
    'Ending Date of Next Month',
    'Starting Date of Previous Month',
    'Ending Date of Previous Month',
    'Starting Date of Fiscal Year',
    'Ending Date of Fiscal Year',
  ];

  static const List<_InputFormatOption>
  _inputFormatOptions = <_InputFormatOption>[
    _InputFormatOption(
      label: 'Numbers',
      description:
          'This format ensures that the custom field accepts only a combination of the numbers 0-9.',
    ),
    _InputFormatOption(
      label: 'Alphanumeric Characters Without Spaces',
      description:
          'This format ensures that the custom field accepts only a combination of lowercase letters (a-z), uppercase letters (A-Z), and numbers (0-9).',
    ),
    _InputFormatOption(
      label: 'Alphanumeric Characters With Spaces',
      description:
          'This format ensures that the custom field accepts only a combination of lowercase letters (a-z), uppercase letters (A-Z), numbers (0-9), and spaces.',
    ),
    _InputFormatOption(
      label: 'Alphanumeric Characters With Hyphens and Underscores',
      description:
          'This format ensures that the custom field accepts only a combination of lowercase letters (a-z), uppercase letters (A-Z), numbers (0-9), hyphens (-), and underscores (_).',
    ),
    _InputFormatOption(
      label: 'Alphabets Without Spaces',
      description:
          'This format ensures that the custom field accepts only a combination of lowercase (a-z) and uppercase (A-Z) letters.',
    ),
    _InputFormatOption(
      label: 'Alphabets With Spaces',
      description:
          'This format ensures that the custom field accepts only a combination of lowercase letters (a-z), uppercase letters (A-Z), and spaces.',
    ),
  ];

  static const List<String> _lookupModuleOptions = <String>[
    'Invoice',
    'Sales Order',
    'Purchase Order',
    'Customers',
    'Vendors',
    'Items',
    'Users',
    'Bill',
    'Locations',
    'Transfer Order',
    'Sales Receipt',
    'Retainer Invoice',
    'Package',
    'Shipment Order',
    'Picklist',
    'Purchase Receive',
    'Sales Return',
    'Inventory Adjustment',
    'Delivery Challan',
    'Customer Payment',
    'Credit Note',
    'Vendor Payment',
    'Account',
    'Sales Person',
    'Category',
    'Assemblies',
    'Gate Passes',
    'Material Issue',
    'Material Request',
  ];

  bool get _showsExtendedFieldOptions =>
      _selectedDataType == 'Text Box (Single Line)' ||
      _selectedDataType == 'Email' ||
      _selectedDataType == 'URL' ||
      _selectedDataType == 'Phone' ||
      _selectedDataType == 'Number' ||
      _selectedDataType == 'Decimal' ||
      _selectedDataType == 'Amount' ||
      _selectedDataType == 'Percent' ||
      _selectedDataType == 'Date' ||
      _selectedDataType == 'Date and Time' ||
      _selectedDataType == 'Check Box' ||
      _selectedDataType == 'Auto-Generate Number' ||
      _selectedDataType == 'Dropdown' ||
      _selectedDataType == 'Multi-select' ||
      _selectedDataType == 'Lookup' ||
      _selectedDataType == 'External Lookup' ||
      _selectedDataType == 'Multi-select Lookup' ||
      _selectedDataType == 'Text Box (Multi-line)' ||
      _selectedDataType == 'Attachment' ||
      _selectedDataType == 'Formula' ||
      _selectedDataType == 'Image';

  bool get _isEmailDataType => _selectedDataType == 'Email';

  bool get _isUrlDataType => _selectedDataType == 'URL';

  bool get _isPhoneDataType => _selectedDataType == 'Phone';

  bool get _isNumberDataType => _selectedDataType == 'Number';

  bool get _isDecimalDataType => _selectedDataType == 'Decimal';

  bool get _isAmountDataType => _selectedDataType == 'Amount';

  bool get _isPercentDataType => _selectedDataType == 'Percent';

  bool get _isDateDataType => _selectedDataType == 'Date';

  bool get _isDateAndTimeDataType => _selectedDataType == 'Date and Time';

  bool get _isDateFamilyDataType => _isDateDataType || _isDateAndTimeDataType;

  bool get _isCheckBoxDataType => _selectedDataType == 'Check Box';

  bool get _isAutoGenerateNumberDataType =>
      _selectedDataType == 'Auto-Generate Number';

  bool get _isDropdownDataType => _selectedDataType == 'Dropdown';

  bool get _isMultiSelectDataType => _selectedDataType == 'Multi-select';

  bool get _isOptionsListDataType =>
      _isDropdownDataType || _isMultiSelectDataType;

  bool get _isLookupDataType => _selectedDataType == 'Lookup';

  bool get _isExternalLookupDataType => _selectedDataType == 'External Lookup';

  bool get _isMultiSelectLookupDataType =>
      _selectedDataType == 'Multi-select Lookup';

  bool get _isLookupFamilyDataType =>
      _isLookupDataType || _isMultiSelectLookupDataType;

  bool get _showsLookupRelatedList =>
      _isMultiSelectLookupDataType &&
      _selectedLookupModule != null &&
      _selectedLookupModule!.trim().isNotEmpty;

  bool get _showsLookupDisplayAs =>
      _isMultiSelectLookupDataType &&
      (_selectedLookupModule == 'Purchase Order' ||
          _selectedLookupModule == 'Purchase Receive' ||
          _selectedLookupModule == 'Account' ||
          _selectedLookupModule == 'Bill' ||
          _selectedLookupModule == 'Customers' ||
          _selectedLookupModule == 'Items' ||
          _selectedLookupModule == 'Users' ||
          _selectedLookupModule == 'Vendors');

  bool get _isTextBoxMultiLineDataType =>
      _selectedDataType == 'Text Box (Multi-line)';

  bool get _isAttachmentDataType => _selectedDataType == 'Attachment';

  bool get _isFormulaDataType => _selectedDataType == 'Formula';

  bool get _isImageDataType => _selectedDataType == 'Image';

  bool get _showsDataPrivacyOption =>
      !_isDecimalDataType &&
      !_isAmountDataType &&
      !_isPercentDataType &&
      !_isCheckBoxDataType &&
      !_isAutoGenerateNumberDataType &&
      !_isOptionsListDataType &&
      !_isLookupFamilyDataType &&
      !_isExternalLookupDataType &&
      !_isTextBoxMultiLineDataType &&
      !_isAttachmentDataType &&
      !_isFormulaDataType &&
      !_isImageDataType;

  bool get _showsDuplicateValueOption =>
      !_isDateFamilyDataType &&
      !_isCheckBoxDataType &&
      !_isAutoGenerateNumberDataType &&
      !_isOptionsListDataType &&
      !_isLookupFamilyDataType &&
      !_isExternalLookupDataType &&
      !_isTextBoxMultiLineDataType &&
      !_isAttachmentDataType &&
      !_isFormulaDataType &&
      !_isImageDataType;

  bool get _showsInputFormatOption =>
      !_isDateFamilyDataType &&
      !_isCheckBoxDataType &&
      !_isAutoGenerateNumberDataType &&
      !_isOptionsListDataType &&
      !_isLookupFamilyDataType &&
      !_isExternalLookupDataType &&
      !_isAttachmentDataType &&
      !_isFormulaDataType &&
      !_isImageDataType;

  bool get _supportsInputFormatModeToggle =>
      _selectedDataType == 'Text Box (Single Line)';

  bool get _showsShowWhenCreatingTransactionsOption =>
      !_isAutoGenerateNumberDataType &&
      !_isMultiSelectLookupDataType &&
      !_isMultiSelectDataType &&
      !_isTextBoxMultiLineDataType &&
      !_isAttachmentDataType &&
      !_isFormulaDataType &&
      !_isImageDataType;

  bool get _showsDefaultValueOption =>
      !_isAutoGenerateNumberDataType &&
      !_isLookupFamilyDataType &&
      !_isExternalLookupDataType &&
      !_isTextBoxMultiLineDataType &&
      !_isFormulaDataType;

  bool get _showsMandatoryOption => !_isFormulaDataType;

  int get _selectedDropdownOptionCount =>
      _dropdownOptionSelections.where((isSelected) => isSelected).length;

  List<String> get _availableOptionsListValues {
    final seen = <String>{};
    final values = <String>[];
    for (final controller in _dropdownOptionControllers) {
      final value = controller.text.trim();
      if (value.isEmpty || seen.contains(value)) {
        continue;
      }
      seen.add(value);
      values.add(value);
    }
    return values;
  }

  String get _remainingFieldsText {
    if (_isFormulaDataType) {
      return 'Remaining Fields: 2';
    }
    if (_isDecimalDataType ||
        _isAmountDataType ||
        _isPercentDataType ||
        _isCheckBoxDataType) {
      return 'Remaining Fields: 20';
    }
    if (_isAutoGenerateNumberDataType) {
      return 'Remaining Fields: 1';
    }
    if (_isMultiSelectLookupDataType) {
      return 'Remaining Fields: 1';
    }
    if (_isImageDataType) {
      return 'Remaining Fields: 4';
    }
    if (_isAttachmentDataType) {
      return 'Remaining Fields: 10';
    }
    if (_isMultiSelectDataType ||
        _isTextBoxMultiLineDataType ||
        _isLookupDataType ||
        _isExternalLookupDataType) {
      return 'Remaining Fields: 5';
    }
    if (_isDropdownDataType) {
      return 'Remaining Fields: 25';
    }
    if (_isNumberDataType || _isDateFamilyDataType) {
      return 'Remaining Fields: 35';
    }
    return 'Remaining Fields: 50';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _optionsListScrollController.dispose();
    _predefinedOptionsScrollController.dispose();
    _labelController.dispose();
    _helpTextController.dispose();
    _relatedListNameController.dispose();
    _defaultValueController.dispose();
    _formulaController.dispose();
    _bulkOptionsController.dispose();
    _customInputFormatController.dispose();
    _prefixController.dispose();
    _startingNumberController.dispose();
    _suffixController.dispose();
    for (final controller in _dropdownOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<SettingsSearchItem> _buildSearchItems(BuildContext context) {
    return kSettingsNavigationSections
        .expand(
          (section) => section.blocks.expand(
            (block) => block.items.map(
              (entry) => SettingsSearchItem(
                group: block.title,
                label: entry.label,
                subtitle: section.title,
                keywords: <String>[section.title, block.title, entry.label],
                onSelected: () => _handleEntryTap(context, entry),
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  void _handleEntryTap(BuildContext context, SettingsNavigationEntry entry) {
    if (entry.route == null) {
      return;
    }
    context.go(_orgScopedRoute(context, entry.route!));
  }

  String _orgScopedRoute(BuildContext context, String route) {
    final path = GoRouterState.of(context).uri.path;
    final match = RegExp(r'^/(\d{10,20})(?:/|$)').firstMatch(path);
    final orgSystemId = match?.group(1);
    if (orgSystemId == null || orgSystemId.isEmpty) {
      return route;
    }
    return '/$orgSystemId$route';
  }

  void _goBackToItemsSettings() {
    context.go(_orgScopedRoute(context, AppRoutes.settingsItems));
  }

  void _handleDataTypeChanged(String? value) {
    FocusManager.instance.primaryFocus?.unfocus();
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedDataType = value;
        _useStandardInputFormat = false;
        _selectedInputFormat = null;
        _customInputFormatController.clear();
        _useRelativeDateDefaultValue = false;
        _selectedRelativeDateDefaultOption = 'Today';
        _selectedMultiSelectDefaultValue = null;
        _selectedLookupModule = null;
        _isBulkOptionsMode = false;
        _isPredefinedOptionsMode = false;
        _isInactiveOptionsMode = false;
        _bulkOptionsController.clear();
        _relatedListNameController.clear();
        if (value != 'Image') {
          _defaultImageFiles.clear();
        }
        final isNextDateFamily = value == 'Date' || value == 'Date and Time';
        if (!isNextDateFamily) {
          _selectedDefaultDate = null;
          _defaultValueController.clear();
        }
      });
    });
  }

  void _clearUnsupportedSelectedDataTypeIfNeeded() {
    final currentValue = _selectedDataType;
    if (currentValue == null || _dataTypeOptions.contains(currentValue)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedDataType != currentValue) {
        return;
      }
      setState(() {
        _selectedDataType = null;
      });
    });
  }

  void _clearUnsupportedDefaultOptionIfNeeded() {
    if (!_isMultiSelectDataType) {
      return;
    }
    final currentValue = _selectedMultiSelectDefaultValue;
    if (currentValue == null ||
        _availableOptionsListValues.contains(currentValue)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedMultiSelectDefaultValue != currentValue) {
        return;
      }
      setState(() {
        _selectedMultiSelectDefaultValue = null;
      });
    });
  }

  void _openBulkOptionsMode() {
    setState(() {
      _isBulkOptionsMode = true;
      _isPredefinedOptionsMode = false;
      _isInactiveOptionsMode = false;
      _bulkOptionsController.text = _dropdownOptionControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .join('\n');
    });
  }

  void _closeBulkOptionsMode() {
    setState(() {
      _isBulkOptionsMode = false;
      _isPredefinedOptionsMode = false;
      _isInactiveOptionsMode = false;
    });
  }

  void _openPredefinedOptionsMode() {
    setState(() {
      _isPredefinedOptionsMode = true;
      _isBulkOptionsMode = false;
      _isInactiveOptionsMode = false;
      _selectedPredefinedOptionsGroup = _predefinedOptionsGroups.keys.first;
    });
  }

  void _openInactiveOptionsMode() {
    setState(() {
      _isInactiveOptionsMode = false;
      _isBulkOptionsMode = false;
      _isPredefinedOptionsMode = false;
      _hoveredDropdownOptionRowIndex = null;
      _hoveredDropdownOptionMenuItem = null;
      _hoveredDropdownOptionMenuItem = null;
    });
  }

  void _sortBulkOptionsLines() {
    final lines =
        _bulkOptionsController.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    setState(() {
      _bulkOptionsController.text = lines.join('\n');
    });
  }

  void _applyBulkOptions() {
    final lines = _bulkOptionsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      setState(() {
        _isBulkOptionsMode = false;
      });
      return;
    }

    setState(() {
      for (final controller in _dropdownOptionControllers) {
        controller.dispose();
      }
      _dropdownOptionControllers
        ..clear()
        ..addAll(lines.map((value) => TextEditingController(text: value)));
      _dropdownOptionSelections
        ..clear()
        ..addAll(List<bool>.filled(lines.length, false));
      _selectedMultiSelectDefaultValue =
          _availableOptionsListValues.contains(_selectedMultiSelectDefaultValue)
          ? _selectedMultiSelectDefaultValue
          : null;
      _isBulkOptionsMode = false;
      _isPredefinedOptionsMode = false;
      _isInactiveOptionsMode = false;
    });
  }

  void _applyPredefinedOptions() {
    final values =
        _predefinedOptionsGroups[_selectedPredefinedOptionsGroup] ?? <String>[];
    if (values.isEmpty) {
      setState(() {
        _isPredefinedOptionsMode = false;
      });
      return;
    }

    setState(() {
      for (final controller in _dropdownOptionControllers) {
        controller.dispose();
      }
      _dropdownOptionControllers
        ..clear()
        ..addAll(values.map((value) => TextEditingController(text: value)));
      _dropdownOptionSelections
        ..clear()
        ..addAll(List<bool>.filled(values.length, false));
      _selectedMultiSelectDefaultValue =
          _availableOptionsListValues.contains(_selectedMultiSelectDefaultValue)
          ? _selectedMultiSelectDefaultValue
          : null;
      _isPredefinedOptionsMode = false;
    });
  }

  void _reorderDropdownOption(int oldIndex, int newIndex) {
    setState(() {
      _syncDropdownOptionSelections();
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final controller = _dropdownOptionControllers.removeAt(oldIndex);
      final selected = _dropdownOptionSelections.removeAt(oldIndex);
      _dropdownOptionControllers.insert(newIndex, controller);
      _dropdownOptionSelections.insert(newIndex, selected);
      _hoveredDropdownOptionRowIndex = null;
    });
  }

  void _sortDropdownOptionsAlphabetically() {
    _syncDropdownOptionSelections();
    final paired = List.generate(
      _dropdownOptionControllers.length,
      (index) => (
        controller: _dropdownOptionControllers[index],
        selected: _dropdownOptionSelections[index],
      ),
    );
    paired.sort(
      (a, b) => a.controller.text.trim().toLowerCase().compareTo(
        b.controller.text.trim().toLowerCase(),
      ),
    );
    setState(() {
      for (var index = 0; index < paired.length; index++) {
        _dropdownOptionControllers[index] = paired[index].controller;
        _dropdownOptionSelections[index] = paired[index].selected;
      }
      _hoveredDropdownOptionRowIndex = null;
    });
  }

  void _clearDropdownOptionSelection() {
    setState(() {
      _syncDropdownOptionSelections();
      for (var index = 0; index < _dropdownOptionSelections.length; index++) {
        _dropdownOptionSelections[index] = false;
      }
    });
  }

  void _deleteSelectedDropdownOptions() {
    _syncDropdownOptionSelections();
    final selectedIndexes = <int>[];
    for (var index = 0; index < _dropdownOptionSelections.length; index++) {
      if (_dropdownOptionSelections[index]) {
        selectedIndexes.add(index);
      }
    }

    if (selectedIndexes.isEmpty) {
      return;
    }

    setState(() {
      for (final index in selectedIndexes.reversed) {
        _dropdownOptionControllers[index].dispose();
        _dropdownOptionControllers.removeAt(index);
        _dropdownOptionSelections.removeAt(index);
      }

      if (_dropdownOptionControllers.isEmpty) {
        _dropdownOptionControllers.add(TextEditingController());
        _dropdownOptionSelections.add(false);
      }

      if (_selectedMultiSelectDefaultValue != null &&
          !_availableOptionsListValues.contains(
            _selectedMultiSelectDefaultValue,
          )) {
        _selectedMultiSelectDefaultValue = null;
      }
    });
  }

  void _deleteDropdownOptionAt(int index) {
    if (index < 0 || index >= _dropdownOptionControllers.length) {
      return;
    }

    setState(() {
      _syncDropdownOptionSelections();
      _dropdownOptionControllers[index].dispose();
      _dropdownOptionControllers.removeAt(index);
      _dropdownOptionSelections.removeAt(index);

      if (_dropdownOptionControllers.isEmpty) {
        _dropdownOptionControllers.add(TextEditingController());
        _dropdownOptionSelections.add(false);
      }

      if (_selectedMultiSelectDefaultValue != null &&
          !_availableOptionsListValues.contains(
            _selectedMultiSelectDefaultValue,
          )) {
        _selectedMultiSelectDefaultValue = null;
      }

      _hoveredDropdownOptionRowIndex = null;
    });
  }

  void _markDropdownOptionInactive(int index) {
    if (index < 0 || index >= _dropdownOptionControllers.length) {
      return;
    }

    final value = _dropdownOptionControllers[index].text.trim();

    setState(() {
      if (value.isNotEmpty && !_inactiveDropdownOptionValues.contains(value)) {
        _inactiveDropdownOptionValues.add(value);
      }

      _syncDropdownOptionSelections();
      _dropdownOptionControllers[index].dispose();
      _dropdownOptionControllers.removeAt(index);
      _dropdownOptionSelections.removeAt(index);

      if (_dropdownOptionControllers.isEmpty) {
        _dropdownOptionControllers.add(TextEditingController());
        _dropdownOptionSelections.add(false);
      }

      if (_selectedMultiSelectDefaultValue != null &&
          !_availableOptionsListValues.contains(
            _selectedMultiSelectDefaultValue,
          )) {
        _selectedMultiSelectDefaultValue = null;
      }

      _isInactiveOptionsMode = false;
      _isBulkOptionsMode = false;
      _isPredefinedOptionsMode = false;
      _hoveredDropdownOptionRowIndex = null;
      _hoveredDropdownOptionMenuItem = null;
    });
  }

  void _handleDropdownOptionMenuAction(int index, String label) {
    setState(() => _selectedDropdownOptionMenuKey = '$index::$label');

    if (label == 'Delete') {
      _deleteDropdownOptionAt(index);
      return;
    }

    if (label == 'Mark as Inactive') {
      _markDropdownOptionInactive(index);
    }
  }

  Future<void> _selectDefaultCustomDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _selectedDefaultDate ?? DateTime.now(),
      targetKey: _defaultDateFieldKey,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDefaultDate = picked;
      _defaultValueController.text = DateFormat('dd-MM-yyyy').format(picked);
    });
  }

  void _toggleDateDefaultValueMode() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _useRelativeDateDefaultValue = !_useRelativeDateDefaultValue;
      if (_useRelativeDateDefaultValue) {
        _selectedDefaultDate = null;
        _defaultValueController.clear();
        _selectedRelativeDateDefaultOption ??= 'Today';
      } else {
        _selectedRelativeDateDefaultOption = 'Today';
      }
    });
  }

  Future<void> _pickDefaultImage(String sourceLabel) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp', 'gif'],
      allowMultiple: false,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.size > _maxDefaultImageBytes) {
      ZerpaiToast.error(context, 'Please upload an image of 10MB or less.');
      return;
    }

    setState(() {
      _selectedImageUploadOption = sourceLabel;
      _defaultImageFiles
        ..clear()
        ..add(file);
    });
  }

  Widget _buildDateFamilyDefaultValueField() {
    final hintText = _isDateAndTimeDataType
        ? 'dd-MM-yyyy hh:mm a'
        : 'dd-MM-yyyy';
    final displayText = _defaultValueController.text.isEmpty
        ? hintText
        : _defaultValueController.text;
    final displayColor = _defaultValueController.text.isEmpty
        ? AppTheme.textMuted
        : const Color(0xFF111827);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: _defaultDateFieldKey,
        onTap: _selectDefaultCustomDate,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              displayText,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: displayColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleInputFormatMode() {
    if (!mounted || _useStandardInputFormat) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _useStandardInputFormat = true;
        _customInputFormatController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _clearUnsupportedSelectedDataTypeIfNeeded();
    _clearUnsupportedDefaultOptionIfNeeded();
    final currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    ref.watch(orgSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SettingsPageHeader(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            searchItems: _buildSearchItems(context),
            showBackButton: true,
            onBack: () =>
                context.go(_orgScopedRoute(context, AppRoutes.settings)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsNavigationSidebar(currentPath: currentPath),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitleBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 24, 24),
                          child: _buildFormCard(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Text(
        'Items',
        style: AppTheme.pageTitle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'New Field - Items',
                    style: AppTheme.pageTitle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _goBackToItemsSettings,
                  child: const Icon(
                    LucideIcons.x,
                    size: 22,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 810),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCreateFieldForRow(),
                  const SizedBox(height: 18),
                  _buildFormRow(
                    label: 'Label Name*',
                    labelColor: const Color(0xFFFE5D5D),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _formFieldMaxWidth,
                      ),
                      child: CustomTextField(
                        controller: _labelController,
                        hintText: '',
                        height: 32,
                        contentCase: ContentCase.sentence,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeRow(),
                  if (_showsExtendedFieldOptions) ...[
                    const SizedBox(height: 4),
                    _buildIndentedFieldNote(_remainingFieldsText),
                    if (_isFormulaDataType) ...[
                      const SizedBox(height: 14),
                      _buildIndentedFieldNote(
                        'Note: Custom fields created using the formula data type will be displayed in the item\'s details page and not on it\'s creation or edit page.',
                        noteColor: const Color(0xFF667085),
                        maxWidth: _formFieldMaxWidth,
                      ),
                    ],
                    if (_isTextBoxMultiLineDataType) ...[
                      const SizedBox(height: 14),
                      _buildIndentedFieldContent(
                        child: _buildCheckboxLabel(
                          label: 'Display rich-text editor',
                          value: _displayRichTextEditor,
                          onChanged: (value) =>
                              setState(() => _displayRichTextEditor = value),
                        ),
                      ),
                    ],
                    if (_isUrlDataType) ...[
                      const SizedBox(height: 16),
                      _buildFormRow(
                        label: 'Hyperlink Label',
                        labelTooltipMessage:
                            'This text will be shown as the clickable label for the stored URL.',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _formFieldMaxWidth,
                          ),
                          child: CustomTextField(
                            hintText: '',
                            height: 32,
                            contentCase: ContentCase.sentence,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildFormRow(
                      label: 'Help Text',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _formFieldMaxWidth,
                        ),
                        child: CustomTextField(
                          controller: _helpTextController,
                          hintText: '',
                          height: 32,
                          contentCase: ContentCase.sentence,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildIndentedFieldNote(
                      'Enter some text to help users understand the purpose of this custom field.',
                      noteColor: const Color(0xFF667085),
                      maxWidth: _formFieldMaxWidth,
                    ),
                    if (_isLookupFamilyDataType) ...[
                      const SizedBox(height: 18),
                      _buildLookupModuleRow(),
                      if (_showsLookupRelatedList) ...[
                        const SizedBox(height: 8),
                        _buildLookupPermissionNotice(),
                        if (_showsLookupDisplayAs) ...[
                          const SizedBox(height: 18),
                          _buildLookupDisplayAsRow(),
                        ],
                        const SizedBox(height: 18),
                        _buildRelatedListNameRow(),
                      ],
                    ],
                    if (_isExternalLookupDataType) ...[
                      const SizedBox(height: 18),
                      _buildExternalLookupFieldRow(),
                    ],
                    if (_isAttachmentDataType) ...[
                      const SizedBox(height: 18),
                      _buildAttachmentFileTypesRow(),
                    ],
                    if (_isAutoGenerateNumberDataType) ...[
                      const SizedBox(height: 18),
                      _buildFormRow(
                        label: 'Prefix',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _formFieldMaxWidth,
                          ),
                          child: CustomTextField(
                            controller: _prefixController,
                            hintText: '',
                            height: 32,
                            contentCase: ContentCase.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFormRow(
                        label: 'Starting Number*',
                        labelColor: const Color(0xFFFE5D5D),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _formFieldMaxWidth,
                          ),
                          child: CustomTextField(
                            controller: _startingNumberController,
                            hintText: '',
                            height: 32,
                            keyboardType: TextInputType.number,
                            contentCase: ContentCase.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFormRow(
                        label: 'Suffix',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _formFieldMaxWidth,
                          ),
                          child: CustomTextField(
                            controller: _suffixController,
                            hintText: '',
                            height: 32,
                            contentCase: ContentCase.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAutoGenerateExistingItemsNotice(),
                    ],
                    if (_isFormulaDataType) ...[
                      const SizedBox(height: 18),
                      _buildFormulaOutputDataTypeRow(),
                      const SizedBox(height: 12),
                      _buildFormulaEditorRow(),
                      const SizedBox(height: 12),
                      _buildFormulaExistingItemsNotice(),
                    ],
                    if (_isOptionsListDataType) ...[
                      const SizedBox(height: 18),
                      _buildDropdownOptionsSection(),
                    ],
                    if (_showsDataPrivacyOption) ...[
                      const SizedBox(height: 18),
                      _buildDataPrivacySection(),
                    ],
                    if (_showsDuplicateValueOption) ...[
                      const SizedBox(height: 18),
                      _buildBoolChoiceRow(
                        label: 'Prevent Duplicate Values',
                        tooltipMessage:
                            'Enable this to require a unique value for every item in this field.',
                        selectedValue: _preventDuplicateValues,
                        onChanged: (value) =>
                            setState(() => _preventDuplicateValues = value),
                      ),
                    ],
                    if (_showsInputFormatOption) ...[
                      const SizedBox(height: 18),
                      _buildInputFormatRow(),
                      const SizedBox(height: 12),
                    ] else
                      const SizedBox(height: 18),
                    if (_showsDefaultValueOption) _buildDefaultValueRow(),
                  ],
                  if (_showsMandatoryOption) ...[
                    const SizedBox(height: 18),
                    _buildMandatoryRow(),
                  ],
                  if (_showsExtendedFieldOptions &&
                      _showsShowWhenCreatingTransactionsOption) ...[
                    const SizedBox(height: 18),
                    _buildBoolChoiceRow(
                      label: 'Show when creating\ntransactions',
                      selectedValue: _showWhenCreatingTransactions,
                      onChanged: (value) =>
                          setState(() => _showWhenCreatingTransactions = value),
                    ),
                  ],
                  const SizedBox(height: 26),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.borderLight,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: _goBackToItemsSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: _goBackToItemsSettings,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF111827),
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateFieldForRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = _isCompactFormLayout(constraints.maxWidth);
        final options = SizedBox(
          width: isCompact ? double.infinity : _formFieldMaxWidth,
          child: Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _buildRadioOption(
                value: 'Item',
                label: 'Item',
                selectedValue: _createCustomFieldFor,
                onChanged: (value) =>
                    setState(() => _createCustomFieldFor = value),
              ),
              _buildRadioOption(
                value: 'Batch',
                label: 'Batch',
                selectedValue: _createCustomFieldFor,
                onChanged: (value) =>
                    setState(() => _createCustomFieldFor = value),
              ),
            ],
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormLabel('Create Custom Field For'),
              const SizedBox(height: 10),
              options,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _formLabelWidth,
              child: _buildFormLabel('Create Custom Field For'),
            ),
            const SizedBox(width: 16),
            options,
          ],
        );
      },
    );
  }

  Widget _buildDataTypeRow() {
    final field = SizedBox(
      width: _formFieldMaxWidth,
      child: FormDropdown<String>(
        value: _selectedDataType,
        items: _dataTypeOptions,
        onChanged: _handleDataTypeChanged,
        hint: '',
        height: 32,
        showSearch: true,
        placeholder: 'Search',
        borderRadius: BorderRadius.circular(6),
        iconSize: 18,
        menuWidth: _formFieldMaxWidth,
        itemHeight: 36,
        menuMaxHeight: 300,
        maxVisibleItems: 8,
        boldSelected: false,
        paintSelectionBackground: false,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: AppTheme.bodyText.copyWith(
          fontSize: 13,
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w400,
        ),
        itemBuilder: _buildDataTypeDropdownItem,
      ),
    );

    return _buildFormRow(
      label: 'Data Type*',
      labelColor: const Color(0xFFFE5D5D),
      fieldWidth: _formFieldMaxWidth + 22,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          field,
          _buildHelpTooltip(
            'Use this for short text, numeric values, or a mix of both up to 255 characters. Example: A-Z, 0-9, and special characters.',
          ),
        ],
      ),
    );
  }

  Widget _buildInputFormatRow() {
    if (_isEmailDataType ||
        _isUrlDataType ||
        _isPhoneDataType ||
        _isNumberDataType ||
        _isDecimalDataType ||
        _isAmountDataType ||
        _isPercentDataType) {
      return _buildFormRow(
        label: 'Input Format',
        labelTooltipMessage:
            'Select a standard format or configure a custom one so entered values follow a defined pattern. Example: use [0-9]{10} for a 10-digit mobile number.',
        child: SizedBox(
          width: _formFieldMaxWidth,
          child: CustomTextField(
            hintText: '',
            height: 32,
            readOnly: true,
            contentCase: ContentCase.none,
          ),
        ),
      );
    }

    final standardInputFormatDropdown = FormDropdown<_InputFormatOption>(
      value: _selectedInputFormat,
      items: _inputFormatOptions,
      onChanged: (value) {
        setState(() => _selectedInputFormat = value);
      },
      hint: '',
      height: 32,
      placeholder: 'Search',
      showSearch: true,
      menuMaxHeight: 280,
      maxVisibleItems: 4,
      borderRadius: BorderRadius.circular(6),
      iconSize: 18,
      boldSelected: false,
      paintSelectionBackground: false,
      itemEstimatedHeight: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      displayStringForValue: (value) => value.label,
      searchStringForValue: (value) => '${value.label} ${value.description}',
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 13,
        color: const Color(0xFF111827),
        fontWeight: FontWeight.w400,
      ),
      itemBuilder: _buildInputFormatDropdownItem,
    );

    final inputFormatField = _supportsInputFormatModeToggle
        ? (_useStandardInputFormat
              ? KeyedSubtree(
                  key: const ValueKey('standard-input-format'),
                  child: standardInputFormatDropdown,
                )
              : CustomTextField(
                  controller: _customInputFormatController,
                  hintText: '',
                  height: 32,
                  contentCase: ContentCase.none,
                ))
        : standardInputFormatDropdown;

    return _buildFormRow(
      label: 'Input Format',
      labelTooltipMessage:
          'Select a standard format or configure a custom one so entered values follow a defined pattern. Example: use [0-9]{10} for a 10-digit mobile number.',
      fieldWidth: _supportsInputFormatModeToggle ? 520 : _formFieldMaxWidth,
      child: Wrap(
        spacing: 24,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: _formFieldMaxWidth, child: inputFormatField),
          if (_supportsInputFormatModeToggle)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _useStandardInputFormat ? null : _toggleInputFormatMode,
              child: Text(
                _useStandardInputFormat
                    ? 'Configure Custom Format'
                    : 'Use Standard Formats',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataPrivacySection() {
    final content = SizedBox(
      width: _formFieldMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _buildCheckboxLabel(
                label: 'PII',
                value: _containsPii,
                onChanged: (value) => setState(() => _containsPii = value),
              ),
              _buildCheckboxLabel(
                label: 'ePHI',
                value: _containsEphi,
                onChanged: (value) => setState(() => _containsEphi = value),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Data will be stored without encryption and will be visible to all users.',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12.5,
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );

    return _buildFormRow(
      label: 'Data Privacy',
      labelTooltipMessage:
          'To protect customer data privacy, enable Personally Identifiable Information (PII) or Electronic Protected Health Information (ePHI). PII is any data used to identify an individual, and ePHI is medical information stored electronically that can identify an individual.',
      child: content,
    );
  }

  Widget _buildFormFieldLane({required Widget child, double? width}) {
    return SizedBox(width: width ?? _formFieldMaxWidth, child: child);
  }

  Widget _buildDefaultValueRow() {
    if (_isCheckBoxDataType) {
      return _buildFormRow(
        label: 'Default Value',
        labelTooltipMessage:
            'This value will appear by default for this custom field while creating a transaction.',
        child: _buildCheckboxLabel(
          label: 'Ticked by default',
          value: _tickedByDefault,
          onChanged: (value) => setState(() => _tickedByDefault = value),
        ),
      );
    }

    if (_isImageDataType) {
      return _buildFormRow(
        label: 'Default Value',
        labelTooltipMessage:
            'This value will appear by default for this custom field while creating a transaction.',
        child: SizedBox(
          width: 322,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageUploadButton(),
              const SizedBox(height: 8),
              Text(
                'You can upload a file that is 10MB or lesser',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12.5,
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (_defaultImageFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _defaultImageFiles.first.name,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12.5,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_isMultiSelectDataType) {
      return _buildFormRow(
        label: 'Default Value',
        labelTooltipMessage:
            'This value will appear by default for this custom field while creating a transaction.',
        child: SizedBox(
          width: 322,
          child: FormDropdown<String>(
            value: _selectedMultiSelectDefaultValue,
            items: _availableOptionsListValues,
            onChanged: (value) {
              setState(() => _selectedMultiSelectDefaultValue = value);
            },
            hint: '',
            height: 32,
            showSearch: false,
            borderRadius: BorderRadius.circular(6),
            iconSize: 18,
            boldSelected: false,
            paintSelectionBackground: false,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w400,
            ),
            itemBuilder: _buildDataTypeDropdownItem,
          ),
        ),
      );
    }

    return _buildFormRow(
      label: 'Default Value',
      labelTooltipMessage:
          'This value will appear by default for this custom field while creating a transaction.',
      child: SizedBox(
        width: 322,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isDateFamilyDataType
                ? (_useRelativeDateDefaultValue
                      ? FormDropdown<String>(
                          value: _selectedRelativeDateDefaultOption,
                          items: _relativeDateDefaultValueOptions,
                          onChanged: (value) {
                            setState(
                              () => _selectedRelativeDateDefaultOption = value,
                            );
                          },
                          hint: '',
                          height: 32,
                          showSearch: false,
                          borderRadius: BorderRadius.circular(6),
                          iconSize: 18,
                          boldSelected: false,
                          paintSelectionBackground: false,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w400,
                          ),
                          itemBuilder: _buildDataTypeDropdownItem,
                        )
                      : _buildDateFamilyDefaultValueField())
                : CustomTextField(
                    controller: _defaultValueController,
                    hintText: '',
                    height: 32,
                    contentCase:
                        (_isEmailDataType ||
                            _isUrlDataType ||
                            _isPhoneDataType ||
                            _isNumberDataType ||
                            _isDecimalDataType ||
                            _isAmountDataType ||
                            _isPercentDataType ||
                            _isDateFamilyDataType)
                        ? ContentCase.none
                        : ContentCase.sentence,
                    prefixWidget: _isAmountDataType
                        ? Text(
                            'INR',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF344054),
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        : null,
                    suffixWidget: _isPercentDataType
                        ? Text(
                            '%',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF344054),
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        : null,
                    suffixSeparator: _isPercentDataType,
                    prefixIcon: _isEmailDataType
                        ? Icons.mail_outline
                        : (_isUrlDataType
                              ? Icons.language
                              : (_isPhoneDataType ? Icons.phone : null)),
                    keyboardType: _isEmailDataType
                        ? TextInputType.emailAddress
                        : (_isUrlDataType
                              ? TextInputType.url
                              : (_isPhoneDataType
                                    ? TextInputType.phone
                                    : (_isNumberDataType
                                          ? TextInputType.number
                                          : ((_isDecimalDataType ||
                                                    _isAmountDataType ||
                                                    _isPercentDataType)
                                                ? const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  )
                                                : TextInputType.text)))),
                  ),
            if (_isDateFamilyDataType) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: _toggleDateDefaultValueMode,
                  child: Text(
                    _useRelativeDateDefaultValue
                        ? 'Select Custom Date'
                        : 'Select Relative Date',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadButton() {
    return MenuAnchor(
      controller: _imageUploadMenuController,
      onOpen: () => setState(() => _isImageUploadMenuOpen = true),
      onClose: () => setState(() {
        _isImageUploadMenuOpen = false;
        _hoveredImageUploadOption = null;
      }),
      alignmentOffset: const Offset(0, 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
        elevation: WidgetStatePropertyAll<double>(6),
        padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: AppTheme.borderLight),
          ),
        ),
      ),
      menuChildren: _imageUploadOptions
          .map(
            (option) => _buildImageUploadMenuItem(
              option,
              selected: _selectedImageUploadOption == option,
            ),
          )
          .toList(growable: false),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD0D5DD)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.upload,
                  size: 14,
                  color: Color(0xFF98A2B3),
                ),
                const SizedBox(width: 8),
                Text(
                  'Upload File',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF475467),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  _isImageUploadMenuOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: const Color(0xFF98A2B3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOptionsButton() {
    return MenuAnchor(
      controller: _addOptionsMenuController,
      onOpen: () => setState(() => _isAddOptionsMenuOpen = true),
      onClose: () => setState(() {
        _isAddOptionsMenuOpen = false;
        _hoveredAddOptionsMenuItem = null;
      }),
      alignmentOffset: const Offset(0, 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
        elevation: WidgetStatePropertyAll<double>(6),
        padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: AppTheme.borderLight),
          ),
        ),
      ),
      menuChildren: _addOptionsMenuItems
          .map(
            (option) => _buildAddOptionsMenuItem(
              option,
              selected: _selectedAddOptionsMenuItem == option,
            ),
          )
          .toList(growable: false),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.plusCircle,
                size: 15,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'Add Options',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isAddOptionsMenuOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: const Color(0xFF111827),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOptionsMenuItem(String label, {required bool selected}) {
    final bool isHovered = _hoveredAddOptionsMenuItem == label;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredAddOptionsMenuItem = label),
      onExit: (_) => setState(() {
        if (_hoveredAddOptionsMenuItem == label) {
          _hoveredAddOptionsMenuItem = null;
        }
      }),
      child: InkWell(
        onTap: () {
          setState(() => _selectedAddOptionsMenuItem = label);
          _addOptionsMenuController.close();
          if (label == 'Add options in bulk') {
            _openBulkOptionsMode();
          } else if (label == 'Use Predefined Options') {
            _openPredefinedOptionsMode();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryBlue
                : (selected ? const Color(0xFFF2F4F7) : Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: isHovered
                        ? Colors.white
                        : (selected
                              ? const Color(0xFF344054)
                              : const Color(0xFF475467)),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (selected && !isHovered)
                const Icon(Icons.check, size: 16, color: Color(0xFF667085)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSettingsButton() {
    return MenuAnchor(
      controller: _optionsSettingsMenuController,
      onOpen: () => setState(() {}),
      onClose: () => setState(() {
        _hoveredOptionsSettingsMenuItem = null;
      }),
      alignmentOffset: const Offset(0, 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
        elevation: WidgetStatePropertyAll<double>(6),
        padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: AppTheme.borderLight),
          ),
        ),
      ),
      menuChildren: _optionsSettingsMenuItems
          .map(
            (option) => _buildOptionsSettingsMenuItem(
              option,
              selected: _selectedOptionsSettingsMenuItem == option,
            ),
          )
          .toList(growable: false),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: const Icon(
            Icons.settings_outlined,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
        );
      },
    );
  }

  Widget _buildOptionsSettingsMenuItem(String label, {required bool selected}) {
    final bool isHovered = _hoveredOptionsSettingsMenuItem == label;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredOptionsSettingsMenuItem = label),
      onExit: (_) => setState(() {
        if (_hoveredOptionsSettingsMenuItem == label) {
          _hoveredOptionsSettingsMenuItem = null;
        }
      }),
      child: InkWell(
        onTap: () {
          setState(() => _selectedOptionsSettingsMenuItem = label);
          _optionsSettingsMenuController.close();
          if (label == 'View Inactive Options') {
            _openInactiveOptionsMode();
          } else if (label == 'Sort') {
            _sortDropdownOptionsAlphabetically();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryBlue
                : (selected ? const Color(0xFFF2F4F7) : Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: isHovered
                        ? Colors.white
                        : (selected
                              ? const Color(0xFF344054)
                              : const Color(0xFF475467)),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (selected && !isHovered)
                const Icon(Icons.check, size: 16, color: Color(0xFF667085)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadMenuItem(String label, {required bool selected}) {
    final bool isHovered = _hoveredImageUploadOption == label;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredImageUploadOption = label),
      onExit: (_) => setState(() {
        if (_hoveredImageUploadOption == label) {
          _hoveredImageUploadOption = null;
        }
      }),
      child: InkWell(
        onTap: () async {
          setState(() => _selectedImageUploadOption = label);
          _imageUploadMenuController.close();
          await _pickDefaultImage(label);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 238,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryBlue
                : (selected ? const Color(0xFFF2F4F7) : Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: isHovered
                        ? Colors.white
                        : (selected
                              ? const Color(0xFF344054)
                              : const Color(0xFF475467)),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (selected && !isHovered)
                const Icon(Icons.check, size: 16, color: Color(0xFF667085)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoolChoiceRow({
    required String label,
    required bool selectedValue,
    required ValueChanged<bool> onChanged,
    String? tooltipMessage,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _formLabelWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                  ),
                ),
              ),
              if (tooltipMessage != null) ...[
                const SizedBox(width: 4),
                _buildHelpTooltip(tooltipMessage),
              ],
            ],
          ),
        ),
        const SizedBox(width: _formColumnGap),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Row(
            children: [
              _buildBoolRadioOption(
                value: true,
                label: 'Yes',
                selectedValue: selectedValue,
                onChanged: onChanged,
              ),
              const SizedBox(width: 18),
              _buildBoolRadioOption(
                value: false,
                label: 'No',
                selectedValue: selectedValue,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxLabel({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _buildCompactCheckbox(
              value: value,
              onChanged: (next) => onChanged(next ?? false),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return SizedBox(
      width: 14,
      height: 14,
      child: CheckboxTheme(
        data: CheckboxThemeData(
          side: const BorderSide(color: Color(0xFFD0D5DD), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primaryBlue;
            }
            return Colors.white;
          }),
          checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        ),
        child: Checkbox(value: value, onChanged: onChanged),
      ),
    );
  }

  Widget _buildMandatoryRow() {
    return _buildBoolChoiceRow(
      label: 'Is Mandatory',
      selectedValue: _isMandatory,
      onChanged: (value) => setState(() => _isMandatory = value),
    );
  }

  Widget _buildLookupModuleRow() {
    return _buildFormRow(
      label: 'Module*',
      labelColor: const Color(0xFFFE5D5D),
      labelTooltipMessage:
          'Select the source module whose records should be available in this lookup.',
      child: SizedBox(
        width: 322,
        child: FormDropdown<String>(
          value: _selectedLookupModule,
          items: _lookupModuleOptions,
          onChanged: _handleLookupModuleChanged,
          hint: '',
          height: 32,
          showSearch: true,
          allowClear: true,
          showClearDivider: true,
          borderRadius: BorderRadius.circular(6),
          iconSize: 18,
          boldSelected: false,
          paintSelectionBackground: false,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w400,
          ),
          itemBuilder: _buildDataTypeDropdownItem,
        ),
      ),
    );
  }

  void _handleLookupModuleChanged(String? value) {
    setState(() {
      _selectedLookupModule = value;
      _selectedLookupDisplayAs =
          value == 'Customers' ||
              value == 'Items' ||
              value == 'Users' ||
              value == 'Vendors'
          ? 'Dropdown'
          : 'Pop-Up';
      if (value == null || value.trim().isEmpty) {
        _relatedListNameController.clear();
      }
    });
  }

  Widget _buildLookupPermissionNotice() {
    final moduleName = _selectedLookupModule?.trim();
    final displayModuleName = (moduleName == null || moduleName.isEmpty)
        ? 'selected'
        : moduleName;

    return _buildIndentedFieldContent(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _formFieldMaxWidth),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Ensure that the users have permission to view the '
            '$displayModuleName module and this field to fetch values.',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12.5,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedListNameRow() {
    return _buildFormRow(
      label: 'Related List Name*',
      labelColor: const Color(0xFFFE5D5D),
      labelTooltipMessage:
          'Enter the related list label that should appear on the selected '
          'module record.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _formFieldMaxWidth),
        child: CustomTextField(
          controller: _relatedListNameController,
          hintText: '',
          height: 32,
          contentCase: ContentCase.sentence,
        ),
      ),
    );
  }

  Widget _buildLookupDisplayAsRow() {
    return _buildFormRow(
      label: 'Display As',
      child: SizedBox(
        width: _formFieldMaxWidth,
        child: Wrap(
          spacing: 24,
          runSpacing: 10,
          children: [
            _buildRadioOption(
              value: 'Pop-Up',
              label: 'Pop-Up',
              selectedValue: _selectedLookupDisplayAs,
              onChanged: (value) =>
                  setState(() => _selectedLookupDisplayAs = value),
            ),
            _buildRadioOption(
              value: 'Dropdown',
              label: 'Dropdown',
              selectedValue: _selectedLookupDisplayAs,
              onChanged: (value) =>
                  setState(() => _selectedLookupDisplayAs = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalLookupFieldRow() {
    return _buildFormRow(
      label: 'External Field*',
      labelColor: const Color(0xFFFE5D5D),
      child: SizedBox(
        width: 322,
        child: CustomTextField(
          hintText: 'Click to select Field',
          height: 32,
          readOnly: true,
          contentCase: ContentCase.none,
        ),
      ),
    );
  }

  Widget _buildAttachmentFileTypesRow() {
    return _buildFormRow(
      label: 'File Type*',
      labelColor: const Color(0xFFFE5D5D),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 16.0;
          final optionWidth = constraints.maxWidth > 220
              ? (constraints.maxWidth - spacing) / 2
              : constraints.maxWidth;

          Widget buildOption({
            required String label,
            required bool value,
            required ValueChanged<bool> onChanged,
          }) {
            return SizedBox(
              width: optionWidth,
              child: _buildCheckboxLabel(
                label: label,
                value: value,
                onChanged: onChanged,
              ),
            );
          }

          return Wrap(
            spacing: spacing,
            runSpacing: 10,
            children: [
              buildOption(
                label: 'Image',
                value: _attachmentImage,
                onChanged: (value) => setState(() => _attachmentImage = value),
              ),
              buildOption(
                label: 'Document',
                value: _attachmentDocument,
                onChanged: (value) =>
                    setState(() => _attachmentDocument = value),
              ),
              buildOption(
                label: 'PDF',
                value: _attachmentPdf,
                onChanged: (value) => setState(() => _attachmentPdf = value),
              ),
              buildOption(
                label: 'All Files',
                value: _attachmentAllFiles,
                onChanged: (value) =>
                    setState(() => _attachmentAllFiles = value),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdownOptionsSection() {
    if (_isBulkOptionsMode) {
      return _buildBulkOptionsSection();
    }
    if (_isPredefinedOptionsMode) {
      return _buildPredefinedOptionsSection();
    }
    if (_isInactiveOptionsMode) {
      return _buildInactiveOptionsSection();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isMultiSelectDataType
              ? 'Multiselect Options :'
              : 'Dropdown Options :',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 810,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedDropdownOptionCount > 0) ...[
                      Text(
                        'Selected : $_selectedDropdownOptionCount',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _clearDropdownOptionSelection,
                        borderRadius: BorderRadius.circular(4),
                        child: const Icon(
                          LucideIcons.x,
                          size: 15,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ] else
                      Text(
                        'Options Count : ${_dropdownOptionControllers.length}',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Spacer(),
                    if (_selectedDropdownOptionCount > 0) ...[
                      const Icon(
                        LucideIcons.eyeOff,
                        size: 16,
                        color: Color(0xFF98A2B3),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: _deleteSelectedDropdownOptions,
                        borderRadius: BorderRadius.circular(4),
                        child: const Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ] else ...[
                      if (_isDropdownDataType) ...[
                        _buildCheckboxLabel(
                          label: 'Add color to options',
                          value: _addColorToDropdownOptions,
                          onChanged: (value) => setState(
                            () => _addColorToDropdownOptions = value,
                          ),
                        ),
                        const SizedBox(width: 18),
                      ],
                      _buildAddOptionsButton(),
                      const SizedBox(width: 16),
                      _buildOptionsSettingsButton(),
                    ],
                  ],
                ),
              ),
              SizedBox(
                height: 250,
                child: ClipRect(
                  child: Scrollbar(
                    controller: _optionsListScrollController,
                    thumbVisibility: true,
                    child: ReorderableListView(
                      buildDefaultDragHandles: false,
                      primary: false,
                      scrollController: _optionsListScrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                      onReorder: _reorderDropdownOption,
                      physics: const ClampingScrollPhysics(),
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      children: List<Widget>.generate(
                        _dropdownOptionControllers.length,
                        (index) => _buildDropdownOptionRow(
                          index,
                          key: ValueKey(_dropdownOptionControllers[index]),
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
  }

  Widget _buildBulkOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isMultiSelectDataType
              ? 'Multiselect Options :'
              : 'Dropdown Options :',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 810,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _closeBulkOptionsMode,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Back',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _sortBulkOptionsLines,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sort_by_alpha,
                            size: 15,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sort',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Every new line will be considered as a seperate option.',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12.5,
                        color: const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _bulkOptionsController,
                      hintText: '',
                      maxLines: 10,
                      height: 190,
                      contentCase: ContentCase.sentence,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: _applyBulkOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'Add Options',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildPredefinedOptionsSection() {
    final groupEntries = _predefinedOptionsGroups.entries.toList(
      growable: false,
    );
    final selectedOptions =
        _predefinedOptionsGroups[_selectedPredefinedOptionsGroup] ?? <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isMultiSelectDataType
              ? 'Multiselect Options :'
              : 'Dropdown Options :',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 810,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _closeBulkOptionsMode,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Back',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 370,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 340,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Column(
                        children: groupEntries
                            .map((entry) {
                              final isSelected =
                                  _selectedPredefinedOptionsGroup == entry.key;
                              return InkWell(
                                onTap: () => setState(
                                  () => _selectedPredefinedOptionsGroup =
                                      entry.key,
                                ),
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEFF6FF)
                                        : Colors.white,
                                    border: const Border(
                                      bottom: BorderSide(
                                        color: AppTheme.borderLight,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 13,
                                            color: isSelected
                                                ? AppTheme.primaryBlue
                                                : const Color(0xFF111827),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: AppTheme.primaryBlue,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 6, 12),
                        child: Scrollbar(
                          controller: _predefinedOptionsScrollController,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _predefinedOptionsScrollController,
                            padding: EdgeInsets.zero,
                            itemCount: selectedOptions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final option = selectedOptions[index];
                              return Text(
                                option,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF111827),
                                  fontWeight: FontWeight.w400,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _applyPredefinedOptions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Add Options',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
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
  }

  Widget _buildInactiveOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isMultiSelectDataType
              ? 'Multiselect Options :'
              : 'Dropdown Options :',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 810,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _closeBulkOptionsMode,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Inactive Options',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 250,
                child: _inactiveDropdownOptionValues.isEmpty
                    ? Center(
                        child: Text(
                          'There are no inactive options',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF98A2B3),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _inactiveDropdownOptionValues.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Text(
                              _inactiveDropdownOptionValues[index],
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: AppTheme.borderLight,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownOptionRow(int index, {required Key key}) {
    _syncDropdownOptionSelections();
    final bool showActions = _hoveredDropdownOptionRowIndex == index;
    final bool isSelected = index < _dropdownOptionSelections.length
        ? _dropdownOptionSelections[index]
        : false;
    const double actionLaneWidth = 54;
    const double dragLaneWidth = 18;

    return MouseRegion(
      key: key,
      onEnter: (_) => setState(() => _hoveredDropdownOptionRowIndex = index),
      onExit: (_) {
        if (_hoveredDropdownOptionRowIndex == index) {
          setState(() => _hoveredDropdownOptionRowIndex = null);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: index == _dropdownOptionControllers.length - 1 ? 0 : 18,
        ),
        child: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: ReorderableDragStartListener(
                index: index,
                child: SizedBox(
                  width: dragLaneWidth,
                  height: 32,
                  child: const Center(
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 16,
              height: 16,
              child: CheckboxTheme(
                data: CheckboxThemeData(
                  side: const BorderSide(color: Color(0xFFD0D5DD), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryBlue;
                    }
                    return Colors.white;
                  }),
                  checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      _syncDropdownOptionSelections();
                      _dropdownOptionSelections[index] = value ?? false;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _dropdownOptionControllers[index],
                hintText: '',
                height: 32,
                contentCase: ContentCase.sentence,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: actionLaneWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  opacity: showActions ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: IgnorePointer(
                    ignoring: !showActions,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () =>
                              _addDropdownOption(insertAfterIndex: index),
                          borderRadius: BorderRadius.circular(4),
                          child: const Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildDropdownOptionRowMenu(index),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDropdownOption({int? insertAfterIndex}) {
    setState(() {
      _syncDropdownOptionSelections();
      final controller = TextEditingController();
      final selection = false;
      final shouldInsert =
          insertAfterIndex != null &&
          insertAfterIndex >= 0 &&
          insertAfterIndex < _dropdownOptionControllers.length;

      if (shouldInsert) {
        final targetIndex = insertAfterIndex + 1;
        _dropdownOptionControllers.insert(targetIndex, controller);
        _dropdownOptionSelections.insert(targetIndex, selection);
      } else {
        _dropdownOptionControllers.add(controller);
        _dropdownOptionSelections.add(selection);
      }
    });
  }

  Widget _buildDropdownOptionRowMenu(int index) {
    return MenuAnchor(
      onClose: () => setState(() {
        _hoveredDropdownOptionMenuItem = null;
      }),
      alignmentOffset: const Offset(0, 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
        elevation: WidgetStatePropertyAll<double>(6),
        padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: AppTheme.borderLight),
          ),
        ),
      ),
      menuChildren: _dropdownOptionRowMenuItems
          .map(
            (option) => _buildDropdownOptionRowMenuItem(
              index,
              option,
              selected: _selectedDropdownOptionMenuKey == '$index::$option',
            ),
          )
          .toList(growable: false),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: const Icon(
            LucideIcons.moreHorizontal,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
        );
      },
    );
  }

  Widget _buildDropdownOptionRowMenuItem(
    int index,
    String label, {
    required bool selected,
  }) {
    final bool isHovered = _hoveredDropdownOptionMenuItem == '$index::$label';

    return MouseRegion(
      onEnter: (_) =>
          setState(() => _hoveredDropdownOptionMenuItem = '$index::$label'),
      onExit: (_) => setState(() {
        if (_hoveredDropdownOptionMenuItem == '$index::$label') {
          _hoveredDropdownOptionMenuItem = null;
        }
      }),
      child: InkWell(
        onTap: () => _handleDropdownOptionMenuAction(index, label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHovered
                ? AppTheme.primaryBlue
                : (selected ? const Color(0xFFF2F4F7) : Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: isHovered
                        ? Colors.white
                        : (selected
                              ? const Color(0xFF344054)
                              : const Color(0xFF475467)),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (selected && !isHovered)
                const Icon(Icons.check, size: 16, color: Color(0xFF667085)),
            ],
          ),
        ),
      ),
    );
  }

  void _syncDropdownOptionSelections() {
    if (_dropdownOptionSelections.length < _dropdownOptionControllers.length) {
      _dropdownOptionSelections.addAll(
        List<bool>.filled(
          _dropdownOptionControllers.length - _dropdownOptionSelections.length,
          false,
        ),
      );
      return;
    }

    if (_dropdownOptionSelections.length > _dropdownOptionControllers.length) {
      _dropdownOptionSelections.removeRange(
        _dropdownOptionControllers.length,
        _dropdownOptionSelections.length,
      );
    }
  }

  Widget _buildAutoGenerateExistingItemsNotice() {
    return Container(
      width: 840,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7CC),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 210,
                child: Text(
                  'Add to existing items',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(
                child: _buildCheckboxLabel(
                  label:
                      'Add this custom field to all the existing items and auto-generate the number in all of them.',
                  value: _addToExistingItems,
                  onChanged: (value) =>
                      setState(() => _addToExistingItems = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF59A96A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is a one-time setup and you cannot edit this setting later.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaOutputDataTypeRow() {
    return _buildFormRow(
      label: 'Output Data Type *',
      labelColor: const Color(0xFFFE5D5D),
      child: SizedBox(
        width: 322,
        child: FormDropdown<String>(
          value: _selectedFormulaOutputDataType,
          items: _formulaOutputDataTypeOptions,
          onChanged: (value) {
            setState(() => _selectedFormulaOutputDataType = value);
          },
          hint: '',
          height: 32,
          showSearch: false,
          borderRadius: BorderRadius.circular(6),
          iconSize: 18,
          menuWidth: 322,
          itemHeight: 36,
          menuMaxHeight: 260,
          maxVisibleItems: 6,
          boldSelected: false,
          paintSelectionBackground: false,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaEditorRow() {
    return _buildFormRow(
      label: 'Formula*',
      labelColor: const Color(0xFFFE5D5D),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _formulaController,
                hintText:
                    'Enter the formula here or insert it using the options below',
                height: 68,
                maxLines: 3,
                contentCase: ContentCase.none,
                textStyle: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(
                      'INSERT',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildFormulaInsertButton(
                    icon: Icons.functions,
                    label: 'Functions',
                  ),
                  _buildFormulaInsertButton(
                    icon: Icons.view_list_outlined,
                    label: 'Fields',
                  ),
                  _buildFormulaInsertButton(
                    icon: Icons.calculate_outlined,
                    label: 'Operators',
                  ),
                  _buildFormulaCheckSyntaxButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaInsertButton({
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF344054),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF667085),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaCheckSyntaxButton() {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryBlue,
          side: const BorderSide(color: AppTheme.primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          'Check Syntax',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaExistingItemsNotice() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7CC),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 210,
                  child: Text(
                    'Add to existing items',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildCheckboxLabel(
                    label:
                        'Add this custom field to all the existing items and auto-calculate the value using the formula in all of them.',
                    value: _addToExistingItems,
                    onChanged: (value) =>
                        setState(() => _addToExistingItems = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF59A96A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a one-time setup and you cannot edit this setting later.',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    Color labelColor = const Color(0xFF111827),
    String? labelTooltipMessage,
    double? fieldWidth,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = _isCompactFormLayout(constraints.maxWidth);

        final labelWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: _buildFormLabel(label, color: labelColor)),
            if (labelTooltipMessage != null) ...[
              const SizedBox(width: 4),
              _buildHelpTooltip(labelTooltipMessage),
            ],
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 10), child],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: _formLabelWidth, child: labelWidget),
            const SizedBox(width: _formColumnGap),
            _buildFormFieldLane(child: child, width: fieldWidth),
          ],
        );
      },
    );
  }

  bool _isCompactFormLayout(double maxWidth) {
    return maxWidth < _compactFormBreakpoint;
  }

  Widget _buildIndentedFieldContent({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = _isCompactFormLayout(constraints.maxWidth);
        return Padding(
          padding: EdgeInsets.only(
            left: isCompact ? 0 : _formLabelWidth + _formColumnGap,
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildIndentedFieldNote(
    String text, {
    Color noteColor = const Color(0xFF475467),
    double? maxWidth,
  }) {
    return _buildIndentedFieldContent(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Text(
          text,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.5,
            color: noteColor,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, {Color? color}) {
    return Text(
      label,
      style: AppTheme.bodyText.copyWith(
        fontSize: 13,
        color: color ?? const Color(0xFF111827),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildHelpTooltip(String message) {
    return ZTooltip(
      message: message,
      direction: ZTooltipDirection.top,
      child: const Icon(
        LucideIcons.helpCircle,
        size: 14,
        color: Color(0xFF98A2B3),
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String label,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioScope<String>(
            value: selectedValue,
            onChanged: (next) => onChanged(next),
            child: SizedBox(
              width: 16,
              height: 16,
              child: RadioGroupItem<String>(
                value: value,
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolRadioOption({
    required bool value,
    required String label,
    required bool selectedValue,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioScope<bool>(
            value: selectedValue,
            onChanged: (next) => onChanged(next),
            child: SizedBox(
              width: 16,
              height: 16,
              child: RadioGroupItem<bool>(
                value: value,
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypeDropdownItem(
    String value,
    bool isSelected,
    bool isHovered,
  ) {
    final backgroundColor = isHovered
        ? const Color(0xFF4285F4)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent);
    final textColor = isHovered
        ? Colors.white
        : (isSelected ? const Color(0xFF344054) : const Color(0xFF475467));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (isSelected && !isHovered)
              const Icon(Icons.check, size: 16, color: Color(0xFF667085)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFormatDropdownItem(
    _InputFormatOption value,
    bool isSelected,
    bool isHovered,
  ) {
    final backgroundColor = isHovered
        ? const Color(0xFF4285F4)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent);
    final titleColor = isHovered ? Colors.white : const Color(0xFF475467);
    final descriptionColor = isHovered ? Colors.white : const Color(0xFF667085);
    final tickColor = isHovered ? Colors.white : const Color(0xFF98A2B3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: titleColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.description,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      height: 1.35,
                      color: descriptionColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.check, size: 16, color: tickColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InputFormatOption {
  final String label;
  final String description;

  const _InputFormatOption({required this.label, required this.description});
}

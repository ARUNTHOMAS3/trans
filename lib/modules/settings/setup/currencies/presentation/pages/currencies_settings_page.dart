import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';

class _CurrencyRow {
  const _CurrencyRow({
    this.id,
    this.exchangeRateId,
    this.code = '',
    required this.name,
    required this.symbol,
    this.exchangeRate = '',
    this.asOfDate = '',
    this.isBaseCurrency = false,
    this.decimalPlaces = '2',
    this.format = '',
  });

  final String? id;
  final String? exchangeRateId;
  final String code;
  final String name;
  final String symbol;
  final String exchangeRate;
  final String asOfDate;
  final bool isBaseCurrency;
  final String decimalPlaces;
  final String format;

  _CurrencyRow copyWith({
    String? id,
    String? exchangeRateId,
    String? code,
    String? name,
    String? symbol,
    String? exchangeRate,
    String? asOfDate,
    bool? isBaseCurrency,
    String? decimalPlaces,
    String? format,
  }) {
    return _CurrencyRow(
      id: id ?? this.id,
      exchangeRateId: exchangeRateId ?? this.exchangeRateId,
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      asOfDate: asOfDate ?? this.asOfDate,
      isBaseCurrency: isBaseCurrency ?? this.isBaseCurrency,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      format: format ?? this.format,
    );
  }
}

const List<String> _currencyCodeOptions = <String>[
  'AED - UAE Dirham',
  'AFN - Afghan Afghani',
  'ALL - Albanian Lek',
  'AMD - Armenian Dram',
  'ANG - Netherlands Antillian Guilder',
  'AOA - Angolan Kwanza',
  'ARS - Argentine Peso',
  'AUD - Australian Dollar',
  'BND - Brunei Dollar',
  'CAD - Canadian Dollar',
  'CNY - Yuan Renminbi',
  'EUR - Euro',
  'GBP - Pound Sterling',
  'INR - Indian Rupee',
  'JPY - Japanese Yen',
  'SAR - Saudi Riyal',
  'USD - United States Dollar',
  'ZAR - South African Rand',
];

const List<String> _decimalPlaceOptions = <String>['0', '2', '3'];

const List<String> _currencyFormatOptions = <String>[];
const List<String> _exportModuleOptions = <String>['Exchange Rates'];
const List<String> _exportDecimalFormatOptions = <String>[
  '1234567.89',
  '1,234,567.89',
  '1.234.567,89',
];
const List<String> _exportTemplateFieldOptions = <String>[
  'Date',
  'Item Name',
  'Currency Code',
  'Exchange Rate',
];

const List<String> _importHeaderOptions = <String>[
  'Currency Code',
  'Date',
  'Exchange Rate',
];

class _ExportTemplateFieldRowData {
  const _ExportTemplateFieldRowData({
    required this.zohoField,
    required this.exportField,
  });

  final String? zohoField;
  final String exportField;
}

final List<_CurrencyRow> _currencyRowsStore = <_CurrencyRow>[];

class CurrenciesSettingsPage extends ConsumerStatefulWidget {
  const CurrenciesSettingsPage({super.key});

  @override
  ConsumerState<CurrenciesSettingsPage> createState() =>
      _CurrenciesSettingsPageState();
}

class _CurrenciesSettingsPageState
    extends ConsumerState<CurrenciesSettingsPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final List<_CurrencyRow> _currencyRowsState;
  late final List<String> _exportTemplateOptionsState;
  bool _isLoading = true;
  bool _exchangeRateFeedsEnabled = false;

  @override
  void initState() {
    super.initState();
    _currencyRowsState = List<_CurrencyRow>.from(_currencyRowsStore);
    _exportTemplateOptionsState = <String>[];
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final responses = await Future.wait([
        _apiClient.get('settings-setup/currencies', useCache: false),
        _apiClient.get(
          'settings-setup/currency-exchange-rates',
          useCache: false,
        ),
      ]);
      final rows = responses[0].data is List
          ? responses[0].data as List
          : const [];
      final rates = responses[1].data is List
          ? responses[1].data as List
          : const [];
      final latestRateByCurrency = <String, Map<String, dynamic>>{};
      for (final row in rates.whereType<Map>()) {
        final json = Map<String, dynamic>.from(row);
        final currencyId = json['currency_id']?.toString();
        if (currencyId != null &&
            !latestRateByCurrency.containsKey(currencyId)) {
          latestRateByCurrency[currencyId] = json;
        }
      }
      if (!mounted) return;
      setState(() {
        _currencyRowsState
          ..clear()
          ..addAll(
            rows.whereType<Map>().where((row) => row['is_active'] != false).map(
              (row) {
                final json = Map<String, dynamic>.from(row);
                final code = json['code']?.toString() ?? '';
                final name = json['name']?.toString() ?? '';
                final id = json['id']?.toString();
                final rate = id == null ? null : latestRateByCurrency[id];
                return _CurrencyRow(
                  id: id,
                  exchangeRateId: rate?['id']?.toString(),
                  code: code,
                  name: code.isEmpty ? name : '$code- $name',
                  symbol: json['symbol']?.toString() ?? '',
                  decimalPlaces: json['decimals']?.toString() ?? '2',
                  format: json['format']?.toString() ?? '',
                  exchangeRate: rate?['exchange_rate']?.toString() ?? '',
                  asOfDate: rate?['as_of_date']?.toString() ?? '',
                );
              },
            ),
          );
        _syncCurrencyStore();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ZerpaiToast.info(context, 'Unable to load currencies');
    }
  }

  Future<void> _saveCurrency({
    String? id,
    required String code,
    required String name,
    required String symbol,
    String? decimals,
    String? format,
  }) async {
    final payload = <String, dynamic>{
      'code': code,
      'name': name,
      'symbol': symbol,
      'decimals': int.tryParse(decimals ?? '2') ?? 2,
      'format': format ?? '',
      'is_active': true,
    };
    if (id == null || id.isEmpty) {
      await _apiClient.post('settings-setup/currencies', data: payload);
    } else {
      await _apiClient.patch('settings-setup/currencies/$id', data: payload);
    }
    await _loadCurrencies();
  }

  Future<void> _saveCurrencyExchangeRate({
    required _CurrencyRow currency,
    required String rate,
    required String date,
  }) async {
    if (currency.id == null || currency.id!.isEmpty) {
      throw StateError('Save the currency before adding an exchange rate');
    }
    final payload = <String, dynamic>{
      'currency_id': currency.id,
      'exchange_rate': double.parse(rate),
      'as_of_date': _toIsoDate(date),
      'source': 'manual',
    };
    if (currency.exchangeRateId != null &&
        currency.asOfDate == _toIsoDate(date)) {
      await _apiClient.patch(
        'settings-setup/currency-exchange-rates/${currency.exchangeRateId}',
        data: payload,
      );
    } else {
      await _apiClient.post(
        'settings-setup/currency-exchange-rates',
        data: payload,
      );
    }
    await _loadCurrencies();
  }

  Future<void> _showExchangeRates(_CurrencyRow currency) async {
    if (currency.id == null) return;
    try {
      final response = await _apiClient.get(
        'settings-setup/currency-exchange-rates?currency_id=${currency.id}',
        useCache: false,
      );
      final rates = response.data is List ? response.data as List : const [];
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('${currency.code} exchange rates'),
                  trailing: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: rates.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No exchange rates found'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: rates.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final rate = Map<String, dynamic>.from(
                              rates[index] as Map,
                            );
                            return ListTile(
                              title: Text(
                                rate['exchange_rate']?.toString() ?? '',
                              ),
                              subtitle: Text(
                                rate['as_of_date']?.toString() ?? '',
                              ),
                              trailing: Text(rate['source']?.toString() ?? ''),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to load exchange rates');
    }
  }

  Future<void> _deactivateCurrency(_CurrencyRow currency) async {
    if (currency.id == null) return;
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Deactivate Currency',
      message: 'This currency will no longer appear in active currency lists.',
      confirmLabel: 'Deactivate',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      await _apiClient.delete('settings-setup/currencies/${currency.id}');
      await _loadCurrencies();
      if (mounted) ZerpaiToast.success(context, 'Currency deactivated');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to deactivate currency');
    }
  }

  String _toIsoDate(String value) {
    final trimmed = value.trim();
    final parts = trimmed.split(RegExp(r'[-/]'));
    if (parts.length == 3 && parts[0].length <= 2) {
      return '${parts[2].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    }
    return trimmed;
  }

  void _syncCurrencyStore() {
    _currencyRowsStore
      ..clear()
      ..addAll(_currencyRowsState);
  }

  Future<void> _openNewCurrencyDialog() async {
    String? selectedCurrencyCode;
    String? selectedDecimalPlaces;
    String? selectedFormat;
    final TextEditingController symbolController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'New Currency',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 500,
                  height: 569.35,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1F101828),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _NewCurrencyDialog(
                    selectedCurrencyCode: selectedCurrencyCode,
                    onCurrencyCodeChanged: (String? value) {
                      setDialogState(() => selectedCurrencyCode = value);
                    },
                    symbolController: symbolController,
                    nameController: nameController,
                    selectedDecimalPlaces: selectedDecimalPlaces,
                    onDecimalPlacesChanged: (String? value) {
                      setDialogState(() => selectedDecimalPlaces = value);
                    },
                    selectedFormat: selectedFormat,
                    onFormatChanged: (String? value) {
                      setDialogState(() => selectedFormat = value);
                    },
                    onClose: () => Navigator.of(dialogContext).pop(),
                    onSave: () async {
                      final String? selectedCode = selectedCurrencyCode?.trim();
                      final String symbol = symbolController.text.trim();
                      final String name = nameController.text.trim();
                      if (selectedCode == null || selectedCode.isEmpty) {
                        ZerpaiToast.info(
                          dialogContext,
                          'Select currency code before saving',
                        );
                        return;
                      }
                      if (symbol.isEmpty || name.isEmpty) {
                        ZerpaiToast.info(
                          dialogContext,
                          'Complete required fields before saving',
                        );
                        return;
                      }
                      final String code = selectedCode
                          .split(' - ')
                          .first
                          .trim();
                      try {
                        await _saveCurrency(
                          code: code,
                          name: name,
                          symbol: symbol,
                          decimals: selectedDecimalPlaces,
                          format: selectedFormat,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        ZerpaiToast.success(
                          context,
                          'Currency added successfully',
                        );
                      } catch (_) {
                        if (dialogContext.mounted) {
                          ZerpaiToast.info(
                            dialogContext,
                            'Unable to save currency',
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    symbolController.dispose();
    nameController.dispose();
  }

  Future<void> _openEditCurrencyDialog(int index, _CurrencyRow row) async {
    final List<String> nameParts = row.name.split('- ');
    final TextEditingController currencyCodeController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts.first : '',
    );
    final TextEditingController symbolController = TextEditingController(
      text: row.symbol,
    );
    final TextEditingController nameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join('- ') : row.name,
    );
    String? selectedDecimalPlaces = row.decimalPlaces;
    String? selectedFormat = row.format.isEmpty ? '1,234,567.89' : row.format;

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Edit Currency',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 500,
                  height: 569.35,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1F101828),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _EditCurrencyDialog(
                    currencyCodeController: currencyCodeController,
                    symbolController: symbolController,
                    nameController: nameController,
                    selectedDecimalPlaces: selectedDecimalPlaces,
                    onDecimalPlacesChanged: (String? value) {
                      setDialogState(() => selectedDecimalPlaces = value);
                    },
                    selectedFormat: selectedFormat,
                    onFormatChanged: (String? value) {
                      setDialogState(() => selectedFormat = value);
                    },
                    onClose: () => Navigator.of(dialogContext).pop(),
                    onSave: () async {
                      final String code = currencyCodeController.text.trim();
                      final String symbol = symbolController.text.trim();
                      final String name = nameController.text.trim();
                      if (code.isEmpty || symbol.isEmpty || name.isEmpty) {
                        ZerpaiToast.info(
                          dialogContext,
                          'Complete required fields before saving',
                        );
                        return;
                      }
                      try {
                        await _saveCurrency(
                          id: row.id,
                          code: code,
                          name: name,
                          symbol: symbol,
                          decimals: selectedDecimalPlaces ?? row.decimalPlaces,
                          format: selectedFormat ?? row.format,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        ZerpaiToast.success(
                          context,
                          'Currency updated successfully',
                        );
                      } catch (_) {
                        if (dialogContext.mounted) {
                          ZerpaiToast.info(
                            dialogContext,
                            'Unable to update currency',
                          );
                        }
                      }
                    },
                    onAddExchangeRate: () {
                      final code = currencyCodeController.text.trim().isEmpty
                          ? 'AED'
                          : currencyCodeController.text.trim();
                      Navigator.of(
                        dialogContext,
                      ).pop(); // Close Edit Currency dialog first
                      _openAddExchangeRateDialog(context, index, code);
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    currencyCodeController.dispose();
    symbolController.dispose();
    nameController.dispose();
  }

  Future<void> _openAddExchangeRateDialog(
    BuildContext sourceContext,
    int index,
    String currencyCode,
  ) async {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController rateController = TextEditingController();

    await showGeneralDialog<void>(
      context: sourceContext,
      barrierLabel: 'Add Exchange Rate',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 500,
              height: 320.22,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F101828),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: _AddExchangeRateDialog(
                currencyCode: currencyCode,
                dateController: dateController,
                rateController: rateController,
                onClose: () => Navigator.of(dialogContext).pop(),
                onSave: () async {
                  final String date = dateController.text.trim();
                  final String rate = rateController.text.trim();
                  if (date.isEmpty || rate.isEmpty) {
                    ZerpaiToast.info(
                      dialogContext,
                      'Complete date and exchange rate before saving',
                    );
                    return;
                  }
                  try {
                    await _saveCurrencyExchangeRate(
                      currency: _currencyRowsState[index],
                      rate: rate,
                      date: date,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    ZerpaiToast.success(
                      context,
                      'Exchange rate added successfully',
                    );
                  } catch (_) {
                    if (!dialogContext.mounted) return;
                    ZerpaiToast.error(
                      dialogContext,
                      'Failed to save exchange rate',
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    dateController.dispose();
    rateController.dispose();
  }

  Future<void> _openExportExchangeRatesDialog({
    String? initialModule = 'Exchange Rates',
    String? initialTemplate,
    String? initialDecimalFormat = '1234567.89',
    String initialFileFormat = 'CSV (Comma Separated Value)',
    String initialPassword = '',
    bool initialObscure = true,
  }) async {
    String? selectedModule = initialModule;
    String? selectedTemplate = initialTemplate;
    String? selectedDecimalFormat = initialDecimalFormat;
    String exportFileFormat = initialFileFormat;
    final TextEditingController passwordController = TextEditingController(
      text: initialPassword,
    );
    bool obscurePassword = initialObscure;

    bool openNewTemplate = false;

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Export Exchange Rates',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 700,
                  height: 825.9,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1F101828),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _ExportExchangeRatesDialog(
                    selectedModule: selectedModule,
                    onModuleChanged: (String? value) {
                      setDialogState(() => selectedModule = value);
                    },
                    selectedTemplate: selectedTemplate,
                    onTemplateChanged: (String? value) {
                      setDialogState(() => selectedTemplate = value);
                    },
                    selectedDecimalFormat: selectedDecimalFormat,
                    onDecimalFormatChanged: (String? value) {
                      setDialogState(() => selectedDecimalFormat = value);
                    },
                    exportFileFormat: exportFileFormat,
                    onExportFileFormatChanged: (String value) {
                      setDialogState(() => exportFileFormat = value);
                    },
                    passwordController: passwordController,
                    obscurePassword: obscurePassword,
                    onTogglePasswordVisibility: () {
                      setDialogState(() => obscurePassword = !obscurePassword);
                    },
                    onClose: () => Navigator.of(dialogContext).pop(),
                    onExport: () {
                      Navigator.of(dialogContext).pop();
                      ZerpaiToast.success(
                        context,
                        'Export started successfully',
                      );
                    },
                    exportTemplateOptions: _exportTemplateOptionsState,
                    onSettingsTap: () {
                      openNewTemplate = true;
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    if (openNewTemplate) {
      final String? value = await _openNewExportTemplateDialog();
      if (value != null && value.trim().isNotEmpty) {
        final String templateName = value.trim();
        setState(() {
          if (!_exportTemplateOptionsState.contains(templateName)) {
            _exportTemplateOptionsState.add(templateName);
          }
        });
        selectedTemplate = templateName;
      }
      if (mounted) {
        await _openExportExchangeRatesDialog(
          initialModule: selectedModule,
          initialTemplate: selectedTemplate,
          initialDecimalFormat: selectedDecimalFormat,
          initialFileFormat: exportFileFormat,
          initialPassword: passwordController.text,
          initialObscure: obscurePassword,
        );
      }
    }
    passwordController.dispose();
  }

  Future<String?> _openNewExportTemplateDialog() async {
    final TextEditingController templateNameController =
        TextEditingController();
    final List<_ExportTemplateFieldRowData> fieldRows =
        <_ExportTemplateFieldRowData>[
          const _ExportTemplateFieldRowData(
            zohoField: 'Date',
            exportField: 'Date',
          ),
          const _ExportTemplateFieldRowData(
            zohoField: 'Item Name',
            exportField: 'Item Name',
          ),
        ];

    final String? result = await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'New Export Template',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 700,
                  height: 426.51,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1F101828),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _NewExportTemplateDialog(
                    templateNameController: templateNameController,
                    fieldRows: fieldRows,
                    onZohoFieldChanged: (int index, String? value) {
                      setDialogState(() {
                        final String nextValue = value ?? '';
                        fieldRows[index] = _ExportTemplateFieldRowData(
                          zohoField: value,
                          exportField: nextValue.isEmpty
                              ? fieldRows[index].exportField
                              : nextValue,
                        );
                      });
                    },
                    onExportFieldChanged: (int index, String value) {
                      setDialogState(() {
                        fieldRows[index] = _ExportTemplateFieldRowData(
                          zohoField: fieldRows[index].zohoField,
                          exportField: value,
                        );
                      });
                    },
                    onAddField: () {
                      setDialogState(() {
                        fieldRows.add(
                          const _ExportTemplateFieldRowData(
                            zohoField: null,
                            exportField: '',
                          ),
                        );
                      });
                    },
                    onRemoveField: (int index) {
                      setDialogState(() {
                        fieldRows.removeAt(index);
                      });
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final _ExportTemplateFieldRowData moved = fieldRows
                            .removeAt(oldIndex);
                        fieldRows.insert(newIndex, moved);
                      });
                    },
                    onClose: () => Navigator.of(dialogContext).pop(),
                    onSaveAndSelect: () {
                      final String templateName = templateNameController.text
                          .trim();
                      if (templateName.isEmpty) {
                        ZerpaiToast.info(
                          dialogContext,
                          'Enter template name before saving',
                        );
                        return;
                      }
                      Navigator.of(dialogContext).pop(templateName);
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    templateNameController.dispose();
    return result;
  }

  Future<void> _openEnableExchangeRatesFeedsDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Enable Exchange Rate Feeds',
      barrierDismissible: true,
      barrierColor: const Color(0x66000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 500,
              height: 163.79,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F101828),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.string(
                        '''<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="none">
  <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" fill="#EAB308" />
  <path d="M12 9v4" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
  <path d="M12 17h.01" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
</svg>''',
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'The exchange rates for the currencies will automatically be fetched in real time.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13.5,
                              height: 1.4,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      _DialogFooterButton(
                        label: 'OK',
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        borderColor: const Color(0xFF0F9D58),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          setState(() {
                            _exchangeRateFeedsEnabled = true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _DialogFooterButton(
                        label: 'Cancel',
                        backgroundColor: const Color(0xFFF8FAFC),
                        foregroundColor: const Color(0xFF334155),
                        borderColor: const Color(0xFFCBD5E1),
                        onTap: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openDisableExchangeRatesFeedsDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Disable Exchange Rate Feeds',
      barrierDismissible: true,
      barrierColor: const Color(0x66000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 500,
              height: 163.79,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F101828),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.string(
                        '''<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="none">
  <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" fill="#EAB308" />
  <path d="M12 9v4" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
  <path d="M12 17h.01" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
</svg>''',
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'You will have to manually enter the exchange rates for each currency, if you disable this feature.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13.5,
                              height: 1.4,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      _DialogFooterButton(
                        label: 'Disable',
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        borderColor: const Color(0xFF0F9D58),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          setState(() {
                            _exchangeRateFeedsEnabled = false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _DialogFooterButton(
                        label: 'Cancel',
                        backgroundColor: const Color(0xFFF8FAFC),
                        foregroundColor: const Color(0xFF334155),
                        borderColor: const Color(0xFFCBD5E1),
                        onTap: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'Currencies',
        subtitle: 'Setup',
        keywords: const <String>['currency', 'exchange rate', 'base currency'],
        onSelected: _focusSearch,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final String orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';
    final String currentPath = GoRouterState.of(context).uri.path;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
              child: _CurrenciesSettingsHeader(
                orgName: orgName,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                searchItems: _buildSearchItems(),
                onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: AppTheme.borderLight),
                          top: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 10, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Currencies',
                                  style: AppTheme.pageTitle.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                _TopActionButton(
                                  label: 'New Currency',
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  icon: Icons.add,
                                  onTap: _openNewCurrencyDialog,
                                ),
                                const SizedBox(width: 12),
                                _TopActionButton(
                                  label: _exchangeRateFeedsEnabled
                                      ? 'Disable Exchange Rate Feeds'
                                      : 'Enable Exchange Rate Feeds',
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  foregroundColor: AppTheme.textPrimary,
                                  borderColor: AppTheme.borderLight,
                                  onTap: () {
                                    if (_exchangeRateFeedsEnabled) {
                                      _openDisableExchangeRatesFeedsDialog();
                                    } else {
                                      _openEnableExchangeRatesFeedsDialog();
                                    }
                                  },
                                ),
                                const SizedBox(width: 12),
                                _MoreMenuButton(
                                  onImportRates: () => context.go(
                                    _withOrgPrefix(
                                      AppRoutes.settingsCurrenciesImport,
                                    ),
                                  ),
                                  onExportRates: _openExportExchangeRatesDialog,
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.borderLight,
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final minimumTableWidth =
                                    _exchangeRateFeedsEnabled ? 470.0 : 930.0;
                                final tableWidth =
                                    constraints.maxWidth > minimumTableWidth
                                    ? constraints.maxWidth
                                    : minimumTableWidth;
                                if (_isLoading) {
                                  return const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                if (_currencyRowsState.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No currencies found',
                                      style: AppTheme.bodyText.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  );
                                }
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: tableWidth,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          _CurrenciesTableHeader(
                                            isFeedsEnabled:
                                                _exchangeRateFeedsEnabled,
                                          ),
                                          for (
                                            int index = 0;
                                            index < _currencyRowsState.length;
                                            index++
                                          )
                                            _CurrencyTableRow(
                                              row: _currencyRowsState[index],
                                              isFeedsEnabled:
                                                  _exchangeRateFeedsEnabled,
                                              onEdit: () =>
                                                  _openEditCurrencyDialog(
                                                    index,
                                                    _currencyRowsState[index],
                                                  ),
                                              onViewRates: () =>
                                                  _showExchangeRates(
                                                    _currencyRowsState[index],
                                                  ),
                                              onDelete: () =>
                                                  _deactivateCurrency(
                                                    _currencyRowsState[index],
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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

class _CurrenciesSettingsHeader extends StatelessWidget {
  const _CurrenciesSettingsHeader({
    required this.orgName,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchItems,
    required this.onClose,
  });

  final String orgName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingsHeaderIdentity(orgName: orgName),
        const Spacer(),
        SizedBox(
          width: 340,
          child: SettingsSearchField(
            controller: searchController,
            focusNode: searchFocusNode,
            items: searchItems,
            onNoMatch: (String query) {
              ZerpaiToast.info(context, 'No settings matched "$query"');
            },
          ),
        ),
        const SizedBox(width: 14),
        _CloseSettingsButton(onTap: onClose),
      ],
    );
  }
}

class _SettingsHeaderIdentity extends StatelessWidget {
  const _SettingsHeaderIdentity({required this.orgName});

  final String orgName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.menu_book_outlined,
            size: 20,
            color: Color(0xFFFF5C5C),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Settings',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              orgName,
              style: AppTheme.bodyText.copyWith(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CloseSettingsButton extends StatelessWidget {
  const _CloseSettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Close Settings',
              style: AppTheme.bodyText.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.close, size: 15, color: Color(0xFFFF5C73)),
          ],
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.borderColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: foregroundColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CurrencyMoreAction { importRates, exportRates }

class _MoreMenuButton extends StatefulWidget {
  const _MoreMenuButton({
    required this.onImportRates,
    required this.onExportRates,
  });

  final VoidCallback onImportRates;
  final VoidCallback onExportRates;

  @override
  State<_MoreMenuButton> createState() => _MoreMenuButtonState();
}

class _MoreMenuButtonState extends State<_MoreMenuButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  _CurrencyMoreAction? _selectedAction;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _removeOverlay(),
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(-166, 38),
            showWhenUnlinked: false,
            child: Material(
              color: Colors.transparent,
              child: _CurrencyMoreMenu(
                selectedAction: _selectedAction,
                onSelected: (action) {
                  setState(() => _selectedAction = action);
                  _removeOverlay();
                  switch (action) {
                    case _CurrencyMoreAction.importRates:
                      widget.onImportRates();
                    case _CurrencyMoreAction.exportRates:
                      widget.onExportRates();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!mounted) return;
    setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleMenu,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 40,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const Icon(
            Icons.more_vert,
            size: 20,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CurrencyMoreMenu extends StatelessWidget {
  const _CurrencyMoreMenu({
    required this.selectedAction,
    required this.onSelected,
  });

  final _CurrencyMoreAction? selectedAction;
  final ValueChanged<_CurrencyMoreAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 214,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A101828),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F3F8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CurrencyMoreMenuItem(
              label: 'Import Exchange Rates',
              icon: Icons.file_download_outlined,
              isSelected: selectedAction == _CurrencyMoreAction.importRates,
              onTap: () => onSelected(_CurrencyMoreAction.importRates),
            ),
            _CurrencyMoreMenuItem(
              label: 'Export Exchange Rates',
              icon: Icons.file_upload_outlined,
              isSelected: selectedAction == _CurrencyMoreAction.exportRates,
              onTap: () => onSelected(_CurrencyMoreAction.exportRates),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyMoreMenuItem extends StatefulWidget {
  const _CurrencyMoreMenuItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CurrencyMoreMenuItem> createState() => _CurrencyMoreMenuItemState();
}

class _CurrencyMoreMenuItemState extends State<_CurrencyMoreMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isHovered
        ? const Color(0xFF3B82F6)
        : (widget.isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final Color foregroundColor = _isHovered
        ? Colors.white
        : AppTheme.primaryBlueDark;
    final Color textColor = _isHovered ? Colors.white : AppTheme.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: foregroundColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrenciesTableHeader extends StatelessWidget {
  const _CurrenciesTableHeader({required this.isFeedsEnabled});

  final bool isFeedsEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const _HeaderCell(label: 'NAME', width: 320),
          const _HeaderCell(label: 'SYMBOL', width: 110),
          if (!isFeedsEnabled) ...[
            const _HeaderCell(label: 'EXCHANGE RATE (IN INR)', width: 300),
            const _HeaderCell(label: 'AS OF DATE', width: 160),
          ],
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: AppTheme.captionText.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF67728A),
        ),
      ),
    );
  }
}

class _CurrencyTableRow extends StatefulWidget {
  const _CurrencyTableRow({
    required this.row,
    required this.isFeedsEnabled,
    required this.onEdit,
    required this.onViewRates,
    required this.onDelete,
  });

  final _CurrencyRow row;
  final bool isFeedsEnabled;
  final VoidCallback onEdit;
  final VoidCallback onViewRates;
  final VoidCallback onDelete;

  @override
  State<_CurrencyTableRow> createState() => _CurrencyTableRowState();
}

class _CurrencyTableRowState extends State<_CurrencyTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF7F8FC) : Colors.white,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 320,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    widget.row.name,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: AppTheme.primaryBlueDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.row.isBaseCurrency)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F9D2F),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'Base Currency',
                        style: AppTheme.captionText.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                widget.row.symbol,
                style: AppTheme.bodyText.copyWith(fontSize: 14),
              ),
            ),
            if (!widget.isFeedsEnabled) ...[
              SizedBox(
                width: 300,
                child: Text(
                  widget.row.exchangeRate,
                  style: AppTheme.bodyText.copyWith(fontSize: 14),
                ),
              ),
              SizedBox(
                width: 160,
                child: Text(
                  widget.row.asOfDate,
                  style: AppTheme.bodyText.copyWith(fontSize: 14),
                ),
              ),
            ],
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _isHovered ? 1 : 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CurrencyRowActionText(
                        label: 'Edit',
                        onTap: widget.onEdit,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '|',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                      if (!widget.isFeedsEnabled) ...[
                        const SizedBox(width: 8),
                        _CurrencyRowActionText(
                          label: 'view exchange rates',
                          onTap: widget.onViewRates,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '|',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF98A2B3),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: widget.onDelete,
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyRowActionText extends StatelessWidget {
  const _CurrencyRowActionText({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Text(
        label,
        style: AppTheme.bodyText.copyWith(
          fontSize: 12,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _NewCurrencyDialog extends StatelessWidget {
  const _NewCurrencyDialog({
    required this.selectedCurrencyCode,
    required this.onCurrencyCodeChanged,
    required this.symbolController,
    required this.nameController,
    required this.selectedDecimalPlaces,
    required this.onDecimalPlacesChanged,
    required this.selectedFormat,
    required this.onFormatChanged,
    required this.onClose,
    required this.onSave,
  });

  final String? selectedCurrencyCode;
  final ValueChanged<String?> onCurrencyCodeChanged;
  final TextEditingController symbolController;
  final TextEditingController nameController;
  final String? selectedDecimalPlaces;
  final ValueChanged<String?> onDecimalPlacesChanged;
  final String? selectedFormat;
  final ValueChanged<String?> onFormatChanged;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Row(
            children: [
              Text(
                'New Currency',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Color(0xFFFF4D4F)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CurrencyDialogLabel(label: 'Currency Code*', isRequired: true),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FormDropdown<String>(
                    value: selectedCurrencyCode,
                    items: _currencyCodeOptions,
                    hint: 'Select',
                    onChanged: onCurrencyCodeChanged,
                    displayStringForValue: (String value) => value,
                    showSearch: true,
                    menuMaxHeight: 245,
                    textStyle: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      color: selectedCurrencyCode == null
                          ? const Color(0xFF8A94A6)
                          : AppTheme.textPrimary,
                    ),
                    itemBuilder:
                        (String item, bool isSelected, bool isHovered) =>
                            _DialogDropdownRow(
                              label: item,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                  ),
                ),
                const SizedBox(height: 16),
                _CurrencyDialogLabel(
                  label: 'Currency Symbol*',
                  isRequired: true,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: CustomTextField(
                    controller: symbolController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CurrencyDialogLabel(label: 'Currency Name*', isRequired: true),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: CustomTextField(
                    controller: nameController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _CurrencyDialogLabel(label: 'Decimal Places'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FormDropdown<String>(
                    value: selectedDecimalPlaces,
                    items: _decimalPlaceOptions,
                    onChanged: onDecimalPlacesChanged,
                    displayStringForValue: (String value) => value,
                    showSearch: true,
                    menuMaxHeight: 160,
                    hint: '',
                    textStyle: AppTheme.bodyText.copyWith(fontSize: 12),
                    itemBuilder:
                        (String item, bool isSelected, bool isHovered) =>
                            _DialogDropdownRow(
                              label: item,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                  ),
                ),
                const SizedBox(height: 16),
                const _CurrencyDialogLabel(label: 'Format'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FormDropdown<String>(
                    value: selectedFormat,
                    items: _currencyFormatOptions,
                    onChanged: onFormatChanged,
                    displayStringForValue: (String value) => value,
                    showSearch: true,
                    menuMaxHeight: 132,
                    hint: '',
                    emptyText: 'NO RESULTS FOUND',
                    textStyle: AppTheme.bodyText.copyWith(fontSize: 12),
                    itemBuilder:
                        (String item, bool isSelected, bool isHovered) =>
                            _DialogDropdownRow(
                              label: item,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              _DialogFooterButton(
                label: 'Save',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                borderColor: const Color(0xFF2BB673),
                onTap: onSave,
              ),
              const SizedBox(width: 12),
              _DialogFooterButton(
                label: 'Cancel',
                backgroundColor: const Color(0xFFF8F9FB),
                foregroundColor: AppTheme.textPrimary,
                borderColor: AppTheme.borderLight,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencyDialogLabel extends StatelessWidget {
  const _CurrencyDialogLabel({required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.bodyText.copyWith(
        fontSize: 13,
        color: isRequired ? const Color(0xFFFF3B30) : AppTheme.textPrimary,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _DialogFooterButton extends StatelessWidget {
  const _DialogFooterButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: foregroundColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DialogDropdownRow extends StatelessWidget {
  const _DialogDropdownRow({
    required this.label,
    required this.isSelected,
    required this.isHovered,
  });

  final String label;
  final bool isSelected;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent);
    final Color textColor = isHovered ? Colors.white : AppTheme.textPrimary;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: backgroundColor,
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyText.copyWith(
          fontSize: 12,
          color: textColor,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _ExchangeRateDateField extends StatelessWidget {
  const _ExchangeRateDateField({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: true,
              onTap: onTap,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'dd-MM-yyyy',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF98A2B3)),
              ),
            ),
          ),
          InkWell(
            onTap: onTap,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportPageHeader extends StatelessWidget {
  const _ImportPageHeader({
    required this.title,
    required this.stepIndex,
    required this.onClose,
  });

  final String title;
  final int stepIndex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Text(
              title,
              style: AppTheme.pageTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 20, color: Color(0xFFFF4D4F)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ImportStepIndicator(stepIndex: stepIndex),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppTheme.borderLight),
      ],
    );
  }
}

class _ImportStepIndicator extends StatelessWidget {
  const _ImportStepIndicator({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ImportStepNode(
          indexLabel: '1',
          label: 'Configure',
          isActive: stepIndex == 0,
          isComplete: stepIndex > 0,
        ),
        _ImportStepConnector(isComplete: stepIndex > 0),
        _ImportStepNode(
          indexLabel: '2',
          label: 'Map Fields',
          isActive: stepIndex == 1,
          isComplete: stepIndex > 1,
        ),
        _ImportStepConnector(isComplete: stepIndex > 1),
        _ImportStepNode(
          indexLabel: '3',
          label: 'Preview',
          isActive: stepIndex == 2,
          isComplete: false,
        ),
      ],
    );
  }
}

class _ImportStepNode extends StatelessWidget {
  const _ImportStepNode({
    required this.indexLabel,
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final String indexLabel;
  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final Color fillColor = isComplete
        ? const Color(0xFF22A06B)
        : (isActive ? const Color(0xFF4C8DF6) : Colors.white);
    final Color borderColor = isComplete || isActive
        ? fillColor
        : const Color(0xFFE5E7EB);
    final Color textColor = isComplete || isActive
        ? AppTheme.textPrimary
        : const Color(0xFFD1D5DB);

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: isComplete
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text(
                  indexLabel,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFFD1D5DB),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _ImportStepConnector extends StatelessWidget {
  const _ImportStepConnector({required this.isComplete});

  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: isComplete ? const Color(0xFF22A06B) : const Color(0xFFE5E7EB),
    );
  }
}

class _ImportConfigureStep extends StatelessWidget {
  const _ImportConfigureStep({
    required this.selectedFileName,
    required this.characterEncoding,
    required this.fileDelimiter,
    required this.onChooseFile,
    required this.onRemoveFile,
    required this.onEncodingChanged,
    required this.onFileDelimiterChanged,
  });

  final String? selectedFileName;
  final String characterEncoding;
  final String fileDelimiter;
  final VoidCallback onChooseFile;
  final VoidCallback onRemoveFile;
  final ValueChanged<String?> onEncodingChanged;
  final ValueChanged<String?> onFileDelimiterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            width: 648,
            constraints: const BoxConstraints(minHeight: 252),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFCFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD7DDED),
                style: BorderStyle.solid,
              ),
            ),
            child: selectedFileName == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x140F172A),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.file_download_outlined,
                          size: 24,
                          color: Color(0xFF7C7E9A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Drag and drop file to import',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: onChooseFile,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2BB673),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Choose File',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 300,
                        child: Text(
                          'Maximum File Size: 25 MB • File Format: CSV or TSV or XLS',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 10.5,
                            height: 1.65,
                            color: const Color(0xFF667085),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const SizedBox(height: 24),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: SvgPicture.string(
                              '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#2196F3" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-file-icon lucide-file"><path d="M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z"/><path d="M14 2v5a1 1 0 0 0 1 1h5"/></svg>''',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selectedFileName!,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: onRemoveFile,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Remove',
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 12.5,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: onChooseFile,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2BB673),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        'Replace File',
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Colors.white24,
                                      indent: 6,
                                      endIndent: 6,
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Maximum File Size: 25 MB • File Format: CSV or TSV or XLS',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 11,
                                color: const Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 648,
            child: RichText(
              text: TextSpan(
                style: AppTheme.bodyText.copyWith(
                  fontSize: 11.5,
                  height: 1.5,
                  color: const Color(0xFF667085),
                ),
                children: [
                  const TextSpan(text: 'Download a '),
                  TextSpan(
                    text: 'sample file',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 11.5,
                      color: const Color(0xFF2563EB),
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onChooseFile,
                  ),
                  const TextSpan(
                    text:
                        ' and compare it to your import file to ensure you have the file perfect for the import.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 648,
            child: Row(
              children: [
                Row(
                  children: [
                    Text(
                      'Character Encoding',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 11.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const ZTooltip(
                      message:
                          'By default, the character encoding is UTF-8 (Unicode). Ensure you have selected the correct character encoding based on your import file.',
                      direction: ZTooltipDirection.top,
                      child: Icon(
                        Icons.help_outline,
                        size: 15,
                        color: Color(0xFF98A2B3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 74),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: FormDropdown<String>(
                      value: characterEncoding,
                      items: const <String>[
                        'UTF-8 (Unicode)',
                        'UTF-16',
                        'ASCII',
                      ],
                      onChanged: onEncodingChanged,
                      displayStringForValue: (String value) => value,
                      showSearch: false,
                      height: 34,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedFileName != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: 648,
              child: Row(
                children: [
                  Row(
                    children: [
                      Text(
                        'File Delimiter',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 11.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const ZTooltip(
                        message:
                            'By default, comma ( , ) is assumed to be the delimiter. Ensure that you have selected the correct delimiter based on your import file.',
                        direction: ZTooltipDirection.top,
                        child: Icon(
                          Icons.help_outline,
                          size: 15,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 109),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: FormDropdown<String>(
                        value: fileDelimiter,
                        items: const <String>[
                          'Comma (,)',
                          'Tab',
                          'Semicolon (;)',
                          'Pipe (|)',
                        ],
                        onChanged: onFileDelimiterChanged,
                        displayStringForValue: (String value) => value,
                        showSearch: false,
                        height: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Container(
            width: 648,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      size: 18,
                      color: Color(0xFFF4B740),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Page Tips',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...const <String>[
                  'Import data with the details of GST Treatment by referring these accepted formats.',
                  'If you have files in other formats, you can convert it to an accepted file format using any online/offline converter.',
                  'You can configure your import settings and save them for future too!',
                ].map(
                  (String tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(
                          child: Text(
                            tip,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 11.5,
                              height: 1.55,
                              color: AppTheme.textPrimary,
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
    );
  }
}

class _ImportMapFieldsStep extends StatelessWidget {
  const _ImportMapFieldsStep({
    required this.selectedFileName,
    required this.currencyCodeHeader,
    required this.dateHeader,
    required this.exchangeRateHeader,
    required this.dateFormat,
    required this.selectDateFormatAtFieldLevel,
    required this.defaultDateFormat,
    required this.saveSelections,
    required this.onEditDefaultDataFormats,
    required this.onCurrencyCodeChanged,
    required this.onDateHeaderChanged,
    required this.onExchangeRateChanged,
    required this.onDateFormatChanged,
    required this.onClearCurrencyCode,
    required this.onClearDate,
    required this.onClearExchangeRate,
    required this.onToggleSaveSelections,
  });

  final String selectedFileName;
  final String? currencyCodeHeader;
  final String? dateHeader;
  final String? exchangeRateHeader;
  final String dateFormat;
  final bool selectDateFormatAtFieldLevel;
  final String? defaultDateFormat;
  final bool saveSelections;
  final VoidCallback onEditDefaultDataFormats;
  final ValueChanged<String?> onCurrencyCodeChanged;
  final ValueChanged<String?> onDateHeaderChanged;
  final ValueChanged<String?> onExchangeRateChanged;
  final ValueChanged<String?> onDateFormatChanged;
  final VoidCallback onClearCurrencyCode;
  final VoidCallback onClearDate;
  final VoidCallback onClearExchangeRate;
  final ValueChanged<bool?> onToggleSaveSelections;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 812,
            child: Text(
              'Your Selected File : $selectedFileName',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ImportInfoBanner(
            width: 812,
            message:
                'The best match to each field on the selected file have been auto-selected.',
          ),
          const SizedBox(height: 18),
          Container(
            width: 812,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Default Data Formats',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onEditDefaultDataFormats,
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 11.5,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Date',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 11.5,
                    color: const Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectDateFormatAtFieldLevel
                      ? 'Select format at field level'
                      : (defaultDateFormat ?? 'Select'),
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 812,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Others',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 32,
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ZOHO INVENTORY FIELD',
                          style: AppTheme.captionText.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'IMPORTED FILE HEADERS',
                          style: AppTheme.captionText.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _MapFieldRow(
                  label: 'Currency Code *',
                  fieldValue: currencyCodeHeader,
                  onChanged: onCurrencyCodeChanged,
                  onClear: onClearCurrencyCode,
                ),
                _MapFieldRow(
                  label: 'Date *',
                  fieldValue: dateHeader,
                  onChanged: onDateHeaderChanged,
                  onClear: onClearDate,
                  dateFormat: dateFormat,
                  onDateFormatChanged: onDateFormatChanged,
                ),
                _MapFieldRow(
                  label: 'Exchange Rate *',
                  fieldValue: exchangeRateHeader,
                  onChanged: onExchangeRateChanged,
                  onClear: onClearExchangeRate,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: saveSelections,
                        onChanged: onToggleSaveSelections,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        activeColor: const Color(0xFF408DFB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Save these selections for use during future imports.',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
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

class _ImportPreviewStep extends StatelessWidget {
  const _ImportPreviewStep({
    required this.showSkippedDetails,
    required this.showUnmappedDetails,
    required this.onToggleSkipped,
    required this.onToggleUnmapped,
    required this.onDownloadSkippedRows,
  });

  final bool showSkippedDetails;
  final bool showUnmappedDetails;
  final VoidCallback onToggleSkipped;
  final VoidCallback onToggleUnmapped;
  final VoidCallback onDownloadSkippedRows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            width: 732,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEBEC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const _FilledTriangleAlertIcon(size: 18),
                const SizedBox(width: 10),
                Text(
                  'None of the rows can be imported',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 732,
            child: Column(
              children: [
                _PreviewSummaryRow(
                  label: 'Exchange Rates that are ready to be imported',
                  trailingLabel: 'View Details',
                  onTap: () {},
                ),
                _SkippedPreviewRow(
                  label: 'No. of Records skipped - 6',
                  isOpen: showSkippedDetails,
                  onToggle: onToggleSkipped,
                  onDownload: onDownloadSkippedRows,
                ),
                _PreviewSummaryRow(
                  label: 'Unmapped Fields',
                  trailingLabel: 'View Details',
                  leadingIcon: Icons.warning_amber_rounded,
                  isOpen: showUnmappedDetails,
                  onTap: onToggleUnmapped,
                  details: const <String>['effective_date', 'rate_source'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportInfoBanner extends StatelessWidget {
  const _ImportInfoBanner({required this.width, required this.message});

  final double width;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFF4C8DF6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'i',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyText.copyWith(
                fontSize: 11.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledTriangleAlertIcon extends StatelessWidget {
  const _FilledTriangleAlertIcon({
    this.size = 18,
    this.color = const Color(0xFFF7525A),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _TriangleFillPainter(color: color),
          ),
          Transform.translate(
            offset: Offset(0, size * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size * 0.12,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: size * 0.08),
                Container(
                  width: size * 0.12,
                  height: size * 0.12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleFillPainter extends CustomPainter {
  const _TriangleFillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(size.width / 2, size.height * 0.08)
      ..lineTo(size.width * 0.08, size.height * 0.9)
      ..lineTo(size.width * 0.92, size.height * 0.9)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleFillPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SkippedPreviewRow extends StatelessWidget {
  const _SkippedPreviewRow({
    required this.label,
    required this.isOpen,
    required this.onToggle,
    required this.onDownload,
  });

  final String label;
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onDownload;

  static const List<({String row, String entry, String reason})> _rows =
      <({String row, String entry, String reason})>[];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.transparent,
                ),
                const _FilledTriangleAlertIcon(
                  size: 16,
                  color: Color(0xFFF4B740),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isOpen) ...[
                  InkWell(
                    onTap: onDownload,
                    child: Row(
                      children: [
                        Text(
                          'Download skipped rows',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.download_outlined,
                          size: 15,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 1,
                    height: 16,
                    color: const Color(0xFFD0D5DD),
                  ),
                  const SizedBox(width: 12),
                ],
                InkWell(
                  onTap: onToggle,
                  child: Row(
                    children: [
                      Text(
                        isOpen ? 'Hide Details' : 'View Details',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isOpen)
            Column(
              children: _rows
                  .map(
                    (({String row, String entry, String reason}) rowData) =>
                        Container(
                          height: 39,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppTheme.borderLight),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    rowData.row,
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: Text(
                                  rowData.entry,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  rowData.reason,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _PreviewSummaryRow extends StatelessWidget {
  const _PreviewSummaryRow({
    required this.label,
    required this.trailingLabel,
    required this.onTap,
    this.leadingIcon,
    this.isOpen = false,
    this.details = const <String>[],
  });

  final String label;
  final String trailingLabel;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final bool isOpen;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  const _FilledTriangleAlertIcon(
                    size: 16,
                    color: Color(0xFFF4B740),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onTap,
                  child: Row(
                    children: [
                      Text(
                        trailingLabel,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF4C8DF6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: const Color(0xFF4C8DF6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isOpen && details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details
                    .map(
                      (String detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            detail,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DefaultDataFormatsDialog extends StatelessWidget {
  const _DefaultDataFormatsDialog({
    required this.selectFormatAtFieldLevel,
    required this.defaultDateFormat,
    required this.onSelectFormatAtFieldLevelChanged,
    required this.onDefaultDateFormatChanged,
    required this.onSave,
    required this.onClose,
  });

  final bool selectFormatAtFieldLevel;
  final String? defaultDateFormat;
  final ValueChanged<bool?> onSelectFormatAtFieldLevelChanged;
  final ValueChanged<String?> onDefaultDateFormatChanged;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
          child: Row(
            children: [
              Text(
                'Default Data Formats',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Color(0xFFFF4D4F)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Column(
            children: [
              Container(
                height: 38,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        'DATA TYPE',
                        style: AppTheme.captionText.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF667085),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(width: 1, color: AppTheme.borderLight),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Text(
                          'SELECT FORMAT AT FIELD LEVEL',
                          style: AppTheme.captionText.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF667085),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: AppTheme.borderLight),
                    SizedBox(
                      width: 308,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'DEFAULT FORMAT',
                          style: AppTheme.captionText.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF667085),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(width: 1, color: AppTheme.borderLight),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: selectFormatAtFieldLevel,
                            onChanged: onSelectFormatAtFieldLevelChanged,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            activeColor: const Color(0xFF408DFB),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: AppTheme.borderLight),
                    SizedBox(
                      width: 308,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          height: 32,
                          child: FormDropdown<String>(
                            value: defaultDateFormat,
                            items: const <String>[
                              'yyyy/MM/dd',
                              'd/M/yyyy',
                              'dd.MM.yy',
                              'MM/dd/yyyy',
                              'dd.MM.yyyy',
                              'yyyyMMdd',
                              'MM-dd-yyyy',
                              'yyyy-MM-dd',
                              'dd-MM-yyyy',
                            ],
                            hint: 'Select',
                            onChanged: onDefaultDateFormatChanged,
                            enabled: !selectFormatAtFieldLevel,
                            showSearch: true,
                            emptyText: 'NO RESULTS FOUND',
                            menuMaxHeight: 220,
                            height: 32,
                            activeBorderColor: const Color(0xFF408DFB),
                            displayStringForValue: (String value) => value,
                            itemBuilder:
                                (String item, bool isSelected, bool isHovered) {
                                  return Container(
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? const Color(0xFF408DFB)
                                          : (isSelected
                                                ? const Color(0xFFF2F4F7)
                                                : Colors.white),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 12,
                                              color: isHovered
                                                  ? Colors.white
                                                  : const Color(0xFF344054),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check,
                                            size: 16,
                                            color: isHovered
                                                ? Colors.white
                                                : const Color(0xFF408DFB),
                                          ),
                                      ],
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
            ],
          ),
        ),
        const Spacer(),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(
            children: [
              _DialogFooterButton(
                label: 'Save',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                borderColor: const Color(0xFF2BB673),
                onTap: onSave,
              ),
              const SizedBox(width: 10),
              _DialogFooterButton(
                label: 'Cancel',
                backgroundColor: const Color(0xFFF8F9FB),
                foregroundColor: AppTheme.textPrimary,
                borderColor: AppTheme.borderLight,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapFieldRow extends StatelessWidget {
  const _MapFieldRow({
    required this.label,
    required this.fieldValue,
    required this.onChanged,
    required this.onClear,
    this.dateFormat,
    this.onDateFormatChanged,
  });

  final String label;
  final String? fieldValue;
  final ValueChanged<String?> onChanged;
  final VoidCallback onClear;
  final String? dateFormat;
  final ValueChanged<String?>? onDateFormatChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 204,
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                color: const Color(0xFFFF3B30),
              ),
            ),
          ),
          SizedBox(
            width: 230,
            height: 34,
            child: _HeaderMappingField(
              value: fieldValue,
              onChanged: onChanged,
              onClear: onClear,
            ),
          ),
          if (dateFormat != null) ...[
            const SizedBox(width: 28),
            SizedBox(
              width: 220,
              height: 34,
              child: FormDropdown<String>(
                value: dateFormat,
                items: const <String>['yyyy-MM-dd', 'dd-MM-yyyy', 'MM-dd-yyyy'],
                onChanged: onDateFormatChanged!,
                displayStringForValue: (String value) => value,
                showSearch: true,
                emptyText: 'NO RESULTS FOUND',
                menuMaxHeight: 220,
                activeBorderColor: const Color(0xFF408DFB),
                itemBuilder: (String item, bool isSelected, bool isHovered) {
                  final Color textColor = isHovered
                      ? Colors.white
                      : const Color(0xFF344054);
                  final Color checkColor = isHovered
                      ? Colors.white
                      : const Color(0xFF408DFB);
                  return Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: isHovered
                          ? const Color(0xFF408DFB)
                          : (isSelected
                                ? const Color(0xFFF2F4F7)
                                : Colors.white),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check, size: 16, color: checkColor),
                      ],
                    ),
                  );
                },
                height: 34,
              ),
            ),
            const SizedBox(width: 12),
            const ZTooltip(
              message:
                  'This indicates the date format that is used in the file you\'re importing. Ensure that this is the same date format that is used in the import file. For example, if the date in your CSV file is 22-07-2008, then select dd-MM-yyyy as the date format.',
              direction: ZTooltipDirection.top,
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: Color(0xFF98A2B3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderMappingField extends StatelessWidget {
  const _HeaderMappingField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return FormDropdown<String>(
      value: value,
      items: _importHeaderOptions,
      hint: '',
      onChanged: onChanged,
      allowClear: true,
      showSearch: true,
      emptyText: 'NO RESULTS FOUND',
      menuMaxHeight: 150,
      height: 34,
      activeBorderColor: const Color(0xFF408DFB),
      displayStringForValue: (String item) => item,
      itemBuilder: (String item, bool isSelected, bool isHovered) {
        final Color textColor = isHovered
            ? Colors.white
            : const Color(0xFF344054);
        final Color checkColor = isHovered
            ? Colors.white
            : const Color(0xFF408DFB);
        return Container(
          height: 34,
          decoration: BoxDecoration(
            color: isHovered
                ? const Color(0xFF408DFB)
                : (isSelected ? const Color(0xFFF2F4F7) : Colors.white),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check, size: 16, color: checkColor),
            ],
          ),
        );
      },
    );
  }
}

class _ImportFooterBar extends StatelessWidget {
  const _ImportFooterBar({
    required this.stepIndex,
    required this.isNextEnabled,
    required this.onPrevious,
    required this.onNext,
    required this.onImport,
    required this.onCancel,
  });

  final int stepIndex;
  final bool isNextEnabled;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onImport;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          if (stepIndex > 0)
            _FooterActionButton(
              label: 'Previous',
              onTap: onPrevious,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              borderColor: AppTheme.borderLight,
              icon: Icons.chevron_left,
            )
          else
            const SizedBox(width: 0),
          const SizedBox(width: 12),
          if (stepIndex < 2)
            _FooterActionButton(
              label: 'Next',
              onTap: isNextEnabled ? onNext : null,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              borderColor: const Color(0xFF2BB673),
              icon: Icons.chevron_right,
              iconAfter: true,
            ),
          if (stepIndex == 2)
            _FooterActionButton(
              label: 'Import',
              onTap: onImport,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              borderColor: const Color(0xFF2BB673),
            ),
          const Spacer(),
          _FooterActionButton(
            label: 'Cancel',
            onTap: onCancel,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            borderColor: AppTheme.borderLight,
          ),
        ],
      ),
    );
  }
}

class _FooterActionButton extends StatelessWidget {
  const _FooterActionButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.icon,
    this.iconAfter = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final IconData? icon;
  final bool iconAfter;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!iconAfter && icon != null) ...[
                Icon(icon, size: 16, color: foregroundColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 11.5,
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (iconAfter && icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: foregroundColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ImportExchangeRatesPage extends ConsumerStatefulWidget {
  const ImportExchangeRatesPage({super.key});

  @override
  ConsumerState<ImportExchangeRatesPage> createState() =>
      _ImportExchangeRatesPageState();
}

class _ImportExchangeRatesPageState
    extends ConsumerState<ImportExchangeRatesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  int _stepIndex = 0;
  String? _selectedFileName;
  List<int>? _selectedFileBytes;
  String _characterEncoding = 'UTF-8 (Unicode)';
  String _fileDelimiter = 'Comma (,)';
  String? _currencyCodeHeader = 'Currency Code';
  String? _dateHeader = 'Date';
  String? _exchangeRateHeader = 'Exchange Rate';
  String _dateFormat = 'yyyy-MM-dd';
  bool _selectDateFormatAtFieldLevel = true;
  String? _defaultDateFormat;
  bool _saveSelections = false;
  bool _showSkippedDetails = false;
  bool _showUnmappedDetails = false;

  bool get _hasRequiredMappings =>
      _currencyCodeHeader != null &&
      _dateHeader != null &&
      _exchangeRateHeader != null;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'Currencies',
        subtitle: 'Setup',
        keywords: const <String>['currency', 'exchange rate', 'import'],
        onSelected: _focusSearch,
      ),
    ];
  }

  Future<void> _pickImportFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'tsv'],
      withData: true,
    );

    if (!mounted) {
      return;
    }

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      _selectedFileName = result.files.single.name;
      _selectedFileBytes = result.files.single.bytes;
    });
  }

  void _goNext() {
    if (_stepIndex == 0 && _selectedFileName == null) {
      ZerpaiToast.info(context, 'Choose a file before continuing');
      return;
    }
    if (_stepIndex == 1 && !_hasRequiredMappings) {
      ZerpaiToast.info(context, 'Map all required fields before continuing');
      return;
    }
    if (_stepIndex < 2) {
      setState(() => _stepIndex += 1);
    }
  }

  void _goPrevious() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex -= 1);
    }
  }

  Future<void> _handleImport() async {
    if (_selectedFileName == null ||
        _selectedFileBytes == null ||
        !_hasRequiredMappings) {
      ZerpaiToast.info(
        context,
        'Complete the import configuration before importing',
      );
      return;
    }
    try {
      final delimiter = _selectedFileName!.toLowerCase().endsWith('.tsv')
          ? '\t'
          : ',';
      final rows = _parseDelimitedRows(
        utf8.decode(_selectedFileBytes!, allowMalformed: true),
        delimiter,
      );
      if (rows.length < 2) {
        throw const FormatException('No exchange-rate rows found');
      }
      final headers = rows.first.map((value) => value.trim()).toList();
      final codeIndex = headers.indexOf(_currencyCodeHeader!);
      final dateIndex = headers.indexOf(_dateHeader!);
      final rateIndex = headers.indexOf(_exchangeRateHeader!);
      if (codeIndex < 0 || dateIndex < 0 || rateIndex < 0) {
        throw const FormatException('Mapped columns are missing from the file');
      }

      final responses = await Future.wait([
        ApiClient().get('settings-setup/currencies', useCache: false),
        ApiClient().get(
          'settings-setup/currency-exchange-rates',
          useCache: false,
        ),
      ]);
      final currencies = responses[0].data is List
          ? responses[0].data as List
          : const [];
      final rates = responses[1].data is List
          ? responses[1].data as List
          : const [];
      final currencyIdByCode = <String, String>{};
      for (final row in currencies.whereType<Map>()) {
        final code = row['code']?.toString().trim().toUpperCase();
        final id = row['id']?.toString();
        if (code != null && code.isNotEmpty && id != null) {
          currencyIdByCode[code] = id;
        }
      }
      final existingRateId = <String, String>{};
      for (final row in rates.whereType<Map>()) {
        final currencyId = row['currency_id']?.toString();
        final date = row['as_of_date']?.toString();
        final id = row['id']?.toString();
        if (currencyId != null && date != null && id != null) {
          existingRateId['$currencyId|$date'] = id;
        }
      }

      var imported = 0;
      var skipped = 0;
      for (final row in rows.skip(1)) {
        if (row.length <= codeIndex ||
            row.length <= dateIndex ||
            row.length <= rateIndex) {
          skipped++;
          continue;
        }
        final currencyId =
            currencyIdByCode[row[codeIndex].trim().toUpperCase()];
        final rate = double.tryParse(row[rateIndex].trim());
        final date = _normaliseImportDate(row[dateIndex].trim());
        if (currencyId == null || rate == null || rate <= 0 || date == null) {
          skipped++;
          continue;
        }
        final payload = <String, dynamic>{
          'currency_id': currencyId,
          'exchange_rate': rate,
          'as_of_date': date,
          'source': 'import',
        };
        final existingId = existingRateId['$currencyId|$date'];
        if (existingId == null) {
          await ApiClient().post(
            'settings-setup/currency-exchange-rates',
            data: payload,
          );
        } else {
          await ApiClient().patch(
            'settings-setup/currency-exchange-rates/$existingId',
            data: payload,
          );
        }
        imported++;
      }
      if (!mounted) return;
      setState(() => _stepIndex = 2);
      ZerpaiToast.success(
        context,
        skipped == 0
            ? '$imported exchange rates imported'
            : '$imported imported, $skipped skipped',
      );
    } catch (_) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to import exchange rates');
    }
  }

  List<List<String>> _parseDelimitedRows(String input, String delimiter) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (char == '"') {
        if (quoted && index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && char == delimiter) {
        row.add(field.toString());
        field = StringBuffer();
      } else if (!quoted && (char == '\n' || char == '\r')) {
        if (char == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index++;
        }
        row.add(field.toString());
        if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
        row = <String>[];
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    row.add(field.toString());
    if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
    return rows;
  }

  String? _normaliseImportDate(String value) {
    final parts = value.split(RegExp(r'[-/]'));
    if (parts.length != 3) return null;
    if (parts[0].length == 4) {
      return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
    }
    final dayFirst = !_dateFormat.toLowerCase().startsWith('mm');
    final day = dayFirst ? parts[0] : parts[1];
    final month = dayFirst ? parts[1] : parts[0];
    return '${parts[2].padLeft(4, '0')}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
  }

  Future<void> _downloadSkippedRows() async {
    const String csvContent = 'row,entry,reason\n';
    await Clipboard.setData(const ClipboardData(text: csvContent));
    if (!mounted) {
      return;
    }
    ZerpaiToast.success(context, 'Skipped rows data copied to clipboard');
  }

  Future<void> _openDefaultDataFormatsDialog() async {
    bool selectAtFieldLevel = _selectDateFormatAtFieldLevel;
    String? defaultDateFormat = _defaultDateFormat;

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Default Data Formats',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (dialogContext, _, __) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 700,
                  height: 251.01,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1F101828),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _DefaultDataFormatsDialog(
                    selectFormatAtFieldLevel: selectAtFieldLevel,
                    defaultDateFormat: defaultDateFormat,
                    onSelectFormatAtFieldLevelChanged: (bool? value) {
                      setDialogState(() {
                        selectAtFieldLevel = value ?? false;
                      });
                    },
                    onDefaultDateFormatChanged: (String? value) {
                      setDialogState(() {
                        defaultDateFormat = value;
                      });
                    },
                    onSave: () {
                      setState(() {
                        _selectDateFormatAtFieldLevel = selectAtFieldLevel;
                        _defaultDateFormat = defaultDateFormat;
                      });
                      Navigator.of(dialogContext).pop();
                    },
                    onClose: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final String orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
              child: _CurrenciesSettingsHeader(
                orgName: orgName,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                searchItems: _buildSearchItems(),
                onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsNavigationSidebar(
                    currentPath: AppRoutes.settingsCurrencies,
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: AppTheme.borderLight),
                          top: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  14,
                                  22,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _ImportPageHeader(
                                      title: _stepIndex == 0
                                          ? 'Exchange Rates - Select File'
                                          : (_stepIndex == 1
                                                ? 'Map Fields'
                                                : 'Preview'),
                                      stepIndex: _stepIndex,
                                      onClose: () => context.go(
                                        _withOrgPrefix(
                                          AppRoutes.settingsCurrencies,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_stepIndex == 0)
                                      _ImportConfigureStep(
                                        selectedFileName: _selectedFileName,
                                        characterEncoding: _characterEncoding,
                                        fileDelimiter: _fileDelimiter,
                                        onChooseFile: _pickImportFile,
                                        onRemoveFile: () {
                                          setState(() {
                                            _selectedFileName = null;
                                          });
                                        },
                                        onEncodingChanged: (String? value) {
                                          if (value != null) {
                                            setState(() {
                                              _characterEncoding = value;
                                            });
                                          }
                                        },
                                        onFileDelimiterChanged:
                                            (String? value) {
                                              if (value != null) {
                                                setState(() {
                                                  _fileDelimiter = value;
                                                });
                                              }
                                            },
                                      ),
                                    if (_stepIndex == 1)
                                      _ImportMapFieldsStep(
                                        selectedFileName:
                                            _selectedFileName ??
                                            'sample_exchangerate.csv',
                                        currencyCodeHeader: _currencyCodeHeader,
                                        dateHeader: _dateHeader,
                                        exchangeRateHeader: _exchangeRateHeader,
                                        dateFormat: _dateFormat,
                                        selectDateFormatAtFieldLevel:
                                            _selectDateFormatAtFieldLevel,
                                        defaultDateFormat: _defaultDateFormat,
                                        saveSelections: _saveSelections,
                                        onEditDefaultDataFormats:
                                            _openDefaultDataFormatsDialog,
                                        onCurrencyCodeChanged:
                                            (String? value) => setState(
                                              () => _currencyCodeHeader = value,
                                            ),
                                        onDateHeaderChanged: (String? value) =>
                                            setState(() => _dateHeader = value),
                                        onExchangeRateChanged:
                                            (String? value) => setState(
                                              () => _exchangeRateHeader = value,
                                            ),
                                        onDateFormatChanged: (String? value) {
                                          if (value != null) {
                                            setState(() {
                                              _dateFormat = value;
                                            });
                                          }
                                        },
                                        onClearCurrencyCode: () => setState(
                                          () => _currencyCodeHeader = null,
                                        ),
                                        onClearDate: () =>
                                            setState(() => _dateHeader = null),
                                        onClearExchangeRate: () => setState(
                                          () => _exchangeRateHeader = null,
                                        ),
                                        onToggleSaveSelections: (bool? value) =>
                                            setState(
                                              () => _saveSelections =
                                                  value ?? false,
                                            ),
                                      ),
                                    if (_stepIndex == 2)
                                      _ImportPreviewStep(
                                        showSkippedDetails: _showSkippedDetails,
                                        showUnmappedDetails:
                                            _showUnmappedDetails,
                                        onDownloadSkippedRows:
                                            _downloadSkippedRows,
                                        onToggleSkipped: () => setState(
                                          () => _showSkippedDetails =
                                              !_showSkippedDetails,
                                        ),
                                        onToggleUnmapped: () => setState(
                                          () => _showUnmappedDetails =
                                              !_showUnmappedDetails,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _ImportFooterBar(
                            stepIndex: _stepIndex,
                            isNextEnabled:
                                _stepIndex != 0 || _selectedFileName != null,
                            onPrevious: _goPrevious,
                            onNext: _goNext,
                            onImport: _handleImport,
                            onCancel: () => context.go(
                              _withOrgPrefix(AppRoutes.settingsCurrencies),
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

class _FilledPlusCircleIcon extends StatelessWidget {
  const _FilledPlusCircleIcon({this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.5,
            height: 1.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 1.7,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportExchangeRatesDialog extends StatelessWidget {
  const _ExportExchangeRatesDialog({
    required this.selectedModule,
    required this.onModuleChanged,
    required this.selectedTemplate,
    required this.onTemplateChanged,
    required this.selectedDecimalFormat,
    required this.onDecimalFormatChanged,
    required this.exportFileFormat,
    required this.onExportFileFormatChanged,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onClose,
    required this.onExport,
    required this.exportTemplateOptions,
    required this.onSettingsTap,
  });

  final String? selectedModule;
  final ValueChanged<String?> onModuleChanged;
  final String? selectedTemplate;
  final ValueChanged<String?> onTemplateChanged;
  final String? selectedDecimalFormat;
  final ValueChanged<String?> onDecimalFormatChanged;
  final String exportFileFormat;
  final ValueChanged<String> onExportFileFormatChanged;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onClose;
  final VoidCallback onExport;
  final List<String> exportTemplateOptions;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            children: [
              Text(
                'Export Exchange Rates',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Color(0xFFFF4D4F)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 2,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Container(
                              width: 2,
                              height: 2,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You can export your data from Zoho Inventory in CSV, XLS or XLSX format.',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                _CurrencyDialogLabel(label: 'Module*', isRequired: true),
                const SizedBox(height: 8),
                SizedBox(
                  width: 356,
                  height: 36,
                  child: FormDropdown<String>(
                    value: selectedModule,
                    items: _exportModuleOptions,
                    hint: 'Exchange Rates',
                    onChanged: onModuleChanged,
                    displayStringForValue: (String value) => value,
                    showSearch: true,
                    menuMaxHeight: 170,
                    textStyle: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                    itemBuilder:
                        (String item, bool isSelected, bool isHovered) =>
                            _DialogDropdownRow(
                              label: item,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      'Export Template',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const ZTooltip(
                      message:
                          "Select a template to export only specific fields of Exchange Rates. If you don't select any template, all fields will be exported.",
                      direction: ZTooltipDirection.top,
                      maxWidth: 300,
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 356,
                  height: 36,
                  child: FormDropdown<String>(
                    value: selectedTemplate,
                    items: exportTemplateOptions,
                    hint: 'Select an Export Template',
                    onChanged: onTemplateChanged,
                    displayStringForValue: (String value) => value,
                    showSearch: true,
                    showSettings: true,
                    settingsLabel: 'New Template',
                    settingsLeading: const _FilledPlusCircleIcon(size: 16),
                    onSettingsTap: onSettingsTap,
                    menuMaxHeight: 170,
                    emptyText: 'NO RESULTS FOUND',
                    textStyle: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      color: selectedTemplate == null
                          ? const Color(0xFF8A94A6)
                          : AppTheme.textPrimary,
                    ),
                    itemBuilder:
                        (String item, bool isSelected, bool isHovered) =>
                            _DialogDropdownRow(
                              label: item,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 18),
                _CurrencyDialogLabel(
                  label: 'Decimal Format*',
                  isRequired: true,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 356,
                  height: 36,
                  child: FormDropdown<String>(
                    value: selectedDecimalFormat,
                    items: _exportDecimalFormatOptions,
                    onChanged: onDecimalFormatChanged,
                    displayStringForValue: (String value) => value,
                    showSearch: true,
                    menuMaxHeight: 170,
                    textStyle: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                    itemBuilder:
                        (String item, bool isSelected, bool isHovered) =>
                            _DialogDropdownRow(
                              label: item,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                _CurrencyDialogLabel(
                  label: 'Export File Format*',
                  isRequired: true,
                ),
                const SizedBox(height: 10),
                _ExportFormatRadio(
                  label: 'CSV (Comma Separated Value)',
                  value: 'CSV (Comma Separated Value)',
                  groupValue: exportFileFormat,
                  onChanged: onExportFileFormatChanged,
                ),
                const SizedBox(height: 10),
                _ExportFormatRadio(
                  label: 'XLS (Microsoft Excel 1997-2004 Compatible)',
                  value: 'XLS (Microsoft Excel 1997-2004 Compatible)',
                  groupValue: exportFileFormat,
                  onChanged: onExportFileFormatChanged,
                ),
                const SizedBox(height: 10),
                _ExportFormatRadio(
                  label: 'XLSX (Microsoft Excel)',
                  value: 'XLSX (Microsoft Excel)',
                  groupValue: exportFileFormat,
                  onChanged: onExportFileFormatChanged,
                ),
                const SizedBox(height: 22),
                Text(
                  'File Protection Password',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 356,
                  height: 40,
                  child: CustomTextField(
                    controller: passwordController,
                    height: 40,
                    obscureText: obscurePassword,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),
                    suffixWidget: InkWell(
                      onTap: onTogglePasswordVisibility,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 17,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 356,
                  child: Text(
                    'Your password must be at least 12 characters and include one uppercase letter, lowercase letter, number, and special character.',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      height: 1.55,
                      color: const Color(0xFF667085),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                RichText(
                  text: TextSpan(
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12.5,
                      height: 1.55,
                      color: const Color(0xFF667085),
                    ),
                    children: const [
                      TextSpan(text: 'Note:  '),
                      TextSpan(
                        text:
                            'You can export only the first 25,000 rows. If you have more rows, please initiate a backup for the data in your Zoho Inventory organization, and download it. ',
                      ),
                      TextSpan(
                        text: 'Backup Your Data',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              _DialogFooterButton(
                label: 'Export',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                borderColor: const Color(0xFF2BB673),
                onTap: onExport,
              ),
              const SizedBox(width: 10),
              _DialogFooterButton(
                label: 'Cancel',
                backgroundColor: const Color(0xFFF8F9FB),
                foregroundColor: AppTheme.textPrimary,
                borderColor: AppTheme.borderLight,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportFormatRadio extends StatelessWidget {
  const _ExportFormatRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFF408DFB)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: selected
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF408DFB),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewExportTemplateDialog extends StatelessWidget {
  const _NewExportTemplateDialog({
    required this.templateNameController,
    required this.fieldRows,
    required this.onZohoFieldChanged,
    required this.onExportFieldChanged,
    required this.onAddField,
    required this.onRemoveField,
    required this.onReorder,
    required this.onClose,
    required this.onSaveAndSelect,
  });

  final TextEditingController templateNameController;
  final List<_ExportTemplateFieldRowData> fieldRows;
  final void Function(int index, String? value) onZohoFieldChanged;
  final void Function(int index, String value) onExportFieldChanged;
  final VoidCallback onAddField;
  final void Function(int index) onRemoveField;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onClose;
  final VoidCallback onSaveAndSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 18, 16),
          child: Row(
            children: [
              Text(
                'New Export Template',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Color(0xFFFF4D4F)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CurrencyDialogLabel(label: 'Template Name*', isRequired: true),
                const SizedBox(height: 10),
                SizedBox(
                  width: 418,
                  height: 40,
                  child: CustomTextField(
                    controller: templateNameController,
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  height: 34,
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 42),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'FIELD NAME IN ZOHO INVENTORY',
                          style: AppTheme.captionText.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'FIELD NAME IN EXPORT FILE',
                          style: AppTheme.captionText.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: fieldRows.length,
                  onReorder: onReorder,
                  itemBuilder: (context, index) {
                    return _ExportTemplateFieldRow(
                      key: ValueKey(
                        'export-template-field-row-$index-${fieldRows[index].zohoField}-${fieldRows[index].exportField}',
                      ),
                      row: fieldRows[index],
                      index: index,
                      onZohoFieldChanged: (String? value) {
                        onZohoFieldChanged(index, value);
                      },
                      onExportFieldChanged: (String value) {
                        onExportFieldChanged(index, value);
                      },
                      onRemove: () => onRemoveField(index),
                    );
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: onAddField,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.string(
                        '''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="none">
  <circle cx="12" cy="12" r="10" fill="#2196F3" />
  <path d="M8 12h8" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
  <path d="M12 8v8" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
</svg>''',
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add a New Field',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(
            children: [
              _DialogFooterButton(
                label: 'Save and Select',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                borderColor: const Color(0xFF2BB673),
                onTap: onSaveAndSelect,
              ),
              const SizedBox(width: 10),
              _DialogFooterButton(
                label: 'Cancel',
                backgroundColor: const Color(0xFFF8F9FB),
                foregroundColor: AppTheme.textPrimary,
                borderColor: AppTheme.borderLight,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportTemplateFieldRow extends StatefulWidget {
  const _ExportTemplateFieldRow({
    super.key,
    required this.row,
    required this.index,
    required this.onZohoFieldChanged,
    required this.onExportFieldChanged,
    required this.onRemove,
  });

  final _ExportTemplateFieldRowData row;
  final int index;
  final ValueChanged<String?> onZohoFieldChanged;
  final ValueChanged<String> onExportFieldChanged;
  final VoidCallback onRemove;

  @override
  State<_ExportTemplateFieldRow> createState() =>
      _ExportTemplateFieldRowState();
}

class _ExportTemplateFieldRowState extends State<_ExportTemplateFieldRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final TextEditingController exportFieldController = TextEditingController(
      text: widget.row.exportField,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF8FAFC) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: ReorderableDragStartListener(
                index: widget.index,
                child: const Icon(
                  Icons.drag_indicator,
                  size: 18,
                  color: Color(0xFF98A2B3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 40,
                child: FormDropdown<String>(
                  value: widget.row.zohoField,
                  items: _exportTemplateFieldOptions,
                  height: 40,
                  hint: '',
                  onChanged: widget.onZohoFieldChanged,
                  displayStringForValue: (String value) => value,
                  showSearch: true,
                  menuMaxHeight: 190,
                  textStyle: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    color: widget.row.zohoField == null
                        ? const Color(0xFF8A94A6)
                        : AppTheme.textPrimary,
                  ),
                  itemBuilder: (String item, bool isSelected, bool isHovered) =>
                      _DialogDropdownRow(
                        label: item,
                        isSelected: isSelected,
                        isHovered: isHovered,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 40,
                child: CustomTextField(
                  controller: exportFieldController,
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 11,
                  ),
                  onChanged: widget.onExportFieldChanged,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 24,
              height: 24,
              child: _isHovered
                  ? InkWell(
                      onTap: widget.onRemove,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: SvgPicture.string(
                        '''<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="none">
  <circle cx="12" cy="12" r="10" fill="#EF4444" />
  <path d="M8 12h8" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
</svg>''',
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCurrencyDialog extends StatelessWidget {
  const _EditCurrencyDialog({
    required this.currencyCodeController,
    required this.symbolController,
    required this.nameController,
    required this.selectedDecimalPlaces,
    required this.onDecimalPlacesChanged,
    required this.selectedFormat,
    required this.onFormatChanged,
    required this.onClose,
    required this.onSave,
    required this.onAddExchangeRate,
  });

  final TextEditingController currencyCodeController;
  final TextEditingController symbolController;
  final TextEditingController nameController;
  final String? selectedDecimalPlaces;
  final ValueChanged<String?> onDecimalPlacesChanged;
  final String? selectedFormat;
  final ValueChanged<String?> onFormatChanged;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onAddExchangeRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Row(
            children: [
              Text(
                'Edit Currency',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Color(0xFFFF4D4F)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CurrencyDialogLabel(label: 'Currency Code*', isRequired: true),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: CustomTextField(
                    controller: currencyCodeController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CurrencyDialogLabel(
                  label: 'Currency Symbol*',
                  isRequired: true,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: CustomTextField(
                    controller: symbolController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CurrencyDialogLabel(label: 'Currency Name*', isRequired: true),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: CustomTextField(
                    controller: nameController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _CurrencyDialogLabel(label: 'Decimal Places'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FormDropdown<String>(
                    value: selectedDecimalPlaces,
                    items: _decimalPlaceOptions,
                    onChanged: onDecimalPlacesChanged,
                    displayStringForValue: (String value) => value,
                    showSearch: true,
                    menuMaxHeight: 160,
                    hint: '',
                    textStyle: AppTheme.bodyText.copyWith(fontSize: 12),
                    itemBuilder:
                        (String item, bool isSelected, bool isHovered) =>
                            _DialogDropdownRow(
                              label: item,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                  ),
                ),
                const SizedBox(height: 16),
                const _CurrencyDialogLabel(label: 'Format'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: FormDropdown<String>(
                    value: selectedFormat,
                    items: const <String>[
                      '1,234,567.89',
                      '1.234.567,89',
                      '1 234 567.89',
                    ],
                    onChanged: onFormatChanged,
                    displayStringForValue: (String value) => value,
                    showSearch: true,
                    menuMaxHeight: 170,
                    hint: '',
                    textStyle: AppTheme.bodyText.copyWith(fontSize: 12),
                    itemBuilder:
                        (String item, bool isSelected, bool isHovered) =>
                            _DialogDropdownRow(
                              label: item,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              _DialogFooterButton(
                label: 'Save',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                borderColor: const Color(0xFF2BB673),
                onTap: onSave,
              ),
              const SizedBox(width: 12),
              _DialogFooterButton(
                label: 'Cancel',
                backgroundColor: const Color(0xFFF8F9FB),
                foregroundColor: AppTheme.textPrimary,
                borderColor: AppTheme.borderLight,
                onTap: onClose,
              ),
              const Spacer(),
              InkWell(
                onTap: onAddExchangeRate,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Text(
                  'Add Exchange Rate',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: AppTheme.primaryBlueDark,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddExchangeRateDialog extends StatelessWidget {
  _AddExchangeRateDialog({
    required this.currencyCode,
    required this.dateController,
    required this.rateController,
    required this.onClose,
    required this.onSave,
  });

  final String currencyCode;
  final TextEditingController dateController;
  final TextEditingController rateController;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final GlobalKey _dateFieldKey = GlobalKey();

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await ZerpaiDatePicker.show(
      context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      targetKey: _dateFieldKey,
    );
    if (pickedDate == null) return;
    final String day = pickedDate.day.toString().padLeft(2, '0');
    final String month = pickedDate.month.toString().padLeft(2, '0');
    final String year = pickedDate.year.toString();
    dateController.text = '$day-$month-$year';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Row(
            children: [
              Text(
                'Add Exchange Rate - $currencyCode',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Color(0xFFFF4D4F)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CurrencyDialogLabel(label: 'Date*', isRequired: true),
                const SizedBox(height: 8),
                SizedBox(
                  width: 334,
                  height: 36,
                  child: _ExchangeRateDateField(
                    key: _dateFieldKey,
                    controller: dateController,
                    onTap: () => _pickDate(context),
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Exchange Rate',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFFFF3B30),
                        ),
                      ),
                      TextSpan(
                        text: ' (in INR)*',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 334,
                  height: 36,
                  child: CustomTextField(
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              _DialogFooterButton(
                label: 'Save',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                borderColor: const Color(0xFF2BB673),
                onTap: onSave,
              ),
              const SizedBox(width: 12),
              _DialogFooterButton(
                label: 'Cancel',
                backgroundColor: const Color(0xFFF8F9FB),
                foregroundColor: AppTheme.textPrimary,
                borderColor: AppTheme.borderLight,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

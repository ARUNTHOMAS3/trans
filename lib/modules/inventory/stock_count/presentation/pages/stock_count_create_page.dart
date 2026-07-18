import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/category_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_calendar.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/resizable_box.dart';
import '../../models/stock_count_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import '../../providers/stock_count_provider.dart';
import 'package:zerpai_erp/modules/items/items/repositories/items_repository_provider.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';

final stockCountProductsProvider =
    FutureProvider.family<List<Item>, String?>((ref, warehouseId) async {
  final repo = ref.watch(itemRepositoryProvider);
  final user = ref.watch(authUserProvider);
  final entityId = user?.activeEntityId ?? user?.orgEntityId;

  final result = await repo.getProductsCursor(limit: 200);
  final products = List<Item>.from(result['items'] as List? ?? []);

  if (products.isEmpty) return [];

  if (entityId != null) {
    try {
      final productIds = products.map((p) => p.id).whereType<String>().toList();
      final supabase = Supabase.instance.client;
      var stockQuery = supabase
          .from('v_physical_stock')
          .select('product_id, stock_on_hand')
          .eq('entity_id', entityId);

      final normalizedWarehouseId = warehouseId?.trim();
      if (normalizedWarehouseId != null && normalizedWarehouseId.isNotEmpty) {
        stockQuery = stockQuery.eq('warehouse_id', normalizedWarehouseId);
      }

      final stockData = await stockQuery.inFilter('product_id', productIds);

      final stockMap = <String, double>{};
      for (final row in stockData) {
        final productId = row['product_id'] as String?;
        final stock = double.tryParse(row['stock_on_hand']?.toString() ?? '') ?? 0.0;
        if (productId != null) {
          stockMap[productId] = (stockMap[productId] ?? 0.0) + stock;
        }
      }

      return products.map((product) {
        if (product.id != null && stockMap.containsKey(product.id)) {
          return product.copyWith(stockOnHand: stockMap[product.id]);
        }
        return product.copyWith(stockOnHand: 0.0);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching physical stock: $e');
    }
  }

  return products;
});

class StockCountCreatePage extends ConsumerStatefulWidget {
  final String? editCountId;
  final StockCount? initialCount;
  final bool startAsRecurring;
  const StockCountCreatePage({
    super.key,
    this.editCountId,
    this.initialCount,
    this.startAsRecurring = false,
  });

  @override
  ConsumerState<StockCountCreatePage> createState() =>
      _StockCountCreatePageState();
}

class _StockCountCreatePageState extends ConsumerState<StockCountCreatePage> {
  static const Uuid _uuid = Uuid();
  static const double _fieldHeight = 32.0;
  String? _editingId;
  bool _hasLoadedData = false;

  bool get _isEditMode =>
      widget.editCountId != null || widget.initialCount != null;

  String get _primaryGenerateCountOn =>
      _generateCountOnDays.isEmpty ? 'Monday' : _generateCountOnDays.first;

  final WidgetStateProperty<Color?> _blueCheckedFill =
      WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF2563EB);
        }
        return Colors.white;
      });
  final _numberController = TextEditingController(text: 'D44');
  final _prefixController = TextEditingController(text: 'D');
  final _nextNumberController = TextEditingController(text: '44');
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _remindBeforeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _addedItemsSearchController = TextEditingController();

  String _selectedLocation = 'ZABNIX PRIVATE LIMITED';
  String? _selectedUser;
  bool _scheduleCounts = false;
  int _currentStep = 0;
  bool _showAssignWarning = false;
  bool _showNameWarning = false;
  bool _showItemsWarning = false;
  bool _showAddedItemsSearch = false;
  bool _importItems = false;
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  int _addedItemsCount = 0;
  List<Map<String, String>> _selectedItems = [];

  bool get _isPrimaryCountFieldEmpty =>
      _scheduleCounts
          ? _nameController.text.trim().isEmpty
          : _numberController.text.trim().isEmpty;

  String get _primaryCountFieldWarning =>
      _scheduleCounts
          ? 'Enter a stock count name.'
          : 'Enter a stock count number.';

  Widget _buildUniformDialogCheckbox({
    required bool value,
    required ValueChanged<bool?>? onChanged,
    WidgetStateProperty<Color?>? fillColor,
    Color activeColor = const Color(0xFF2563EB),
    OutlinedBorder? shape,
  }) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        ),
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          fillColor: fillColor ?? _blueCheckedFill,
          shape:
              shape ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
        ),
      ),
    );
  }


  // Schedule Fields
  String _scheduleType = 'Periodic';
  String _frequency = 'Every Day';
  DateTime _startDate = DateTime.now();
  final LinkedHashSet<String> _generateCountOnDays =
      LinkedHashSet<String>.from(<String>['Monday']);
  String _monthlyGenerateCountMode = 'A Specific Date';
  String _monthlyOrdinal = 'First';
  String _monthlyWeekday = 'Sunday';
  final TextEditingController _monthlyDayOfMonthController =
      TextEditingController(text: '1');
  String _yearlyGenerateCountMode = 'A Specific Date';
  String _yearlyMonth = 'January';
  String _yearlyOrdinal = 'First';
  String _yearlyWeekday = 'Sunday';
  final TextEditingController _yearlyDayOfMonthController =
      TextEditingController(text: '1');
  final GlobalKey _startDateKey = GlobalKey();
  final LayerLink _startDateLink = LayerLink();
  String? _generateTime;
  String _expiresAfter = 'Never Expires';
  DateTime? _expiryDate;
  final LayerLink _expiryDateLink = LayerLink();
  OverlayEntry? _expiryDateOverlayEntry;

  // Custom schedule dates
  final List<DateTime?> _customDates = [DateTime.now(), null];
  final List<GlobalKey> _customDateKeys = [GlobalKey(), GlobalKey()];
  final List<LayerLink> _customDateLinks = [LayerLink(), LayerLink()];
  final List<TextEditingController> _customDateControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isEditingFrequencyValue = false;
  int _frequencyValue = 1;
  double _descHeight = 120.0;
  final _frequencyValueController = TextEditingController(text: '1');

  List<String> _locations = [
    'ZABNIX PRIVATE LIMITED',
    'DEMO WAREHOUSE 1 (Warehouse)',
    'SAHAKAR TIRUR',
  ];

  List<Map<String, dynamic>> _dbWarehouses = [];

  Future<void> _loadWarehouses() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('warehouses')
          .select('id, name')
          .eq('is_active', true);
      
      if (mounted) {
        setState(() {
          _dbWarehouses = List<Map<String, dynamic>>.from(res);
          if (_dbWarehouses.isNotEmpty) {
            _locations = _dbWarehouses.map((w) => w['name'] as String).toList();
            if (!_locations.contains(_selectedLocation)) {
              _selectedLocation = _locations.first;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading warehouses: $e');
    }
  }

  Future<void> _loadAssignableUsers() async {
    try {
      final user = ref.read(authUserProvider);
      final entityId = user?.activeEntityId ?? user?.orgEntityId;

      var query = Supabase.instance.client
          .from('users')
          .select('id, full_name, email')
          .eq('is_active', true);

      if (entityId != null && entityId.trim().isNotEmpty) {
        query = query.eq('entity_id', entityId);
      }

      final res = await query.order('full_name');
      final Map<String, String> resolvedMap = {};
      final names = (res as List<dynamic>)
          .map((row) => row as Map<String, dynamic>)
          .map((row) {
            final id = row['id'] as String? ?? '';
            final fullName = (row['full_name'] as String? ?? '').trim();
            final email = (row['email'] as String? ?? '').trim();
            final key = fullName.isNotEmpty ? fullName : email;
            if (key.isNotEmpty && id.isNotEmpty) {
              resolvedMap[key] = id;
            }
            return key;
          })
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (mounted) {
        setState(() {
          _userMap
            ..clear()
            ..addAll(resolvedMap);
          _users
            ..clear()
            ..addAll(names);

          if (_selectedUser != null &&
              _selectedUser!.trim().isNotEmpty &&
              !_users.contains(_selectedUser)) {
            _users.add(_selectedUser!);
            _users.sort();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading assignable users: $e');
    }
  }

  Future<void> _loadNextStockCountNumber() async {
    if (_isEditMode) return;
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('inventory_stock_count')
          .select('stock_count_number');

      int maxVal = 43;
      for (final row in res) {
        final numStr = row['stock_count_number'] as String?;
        if (numStr != null && numStr.startsWith('D')) {
          final match = RegExp(r'^D(\d+)$').firstMatch(numStr);
          if (match != null) {
            final val = int.tryParse(match.group(1) ?? '');
            if (val != null && val > maxVal) {
              maxVal = val;
            }
          }
        }
      }

      final nextVal = maxVal + 1;
      if (mounted) {
        setState(() {
          _numberController.text = 'D$nextVal';
          _prefixController.text = 'D';
          _nextNumberController.text = '$nextVal';
        });
      }
    } catch (e) {
      debugPrint('Error loading next stock count number: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final res = await Supabase.instance.client
          .from('categories')
          .select('id, name, parent_id, is_active')
          .eq('is_active', true)
          .order('name');

      final flat = (res as List<dynamic>)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final nodes = CategoryNode.fromFlatList(flat);
      final descendantIds = <String, Set<String>>{};
      final namesById = <String, String>{};

      Set<String> collectIds(CategoryNode node) {
        final ids = <String>{node.id};
        namesById[node.id] = node.name;
        for (final child in node.children) {
          ids.addAll(collectIds(child));
        }
        descendantIds[node.id] = ids;
        return ids;
      }

      for (final node in nodes) {
        collectIds(node);
      }

      if (!mounted) return;
      setState(() {
        _categoryNodes = nodes;
        _categoryDescendantIds
          ..clear()
          ..addAll(descendantIds);
        _categoryNameById
          ..clear()
          ..addAll(namesById);
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadManufacturers() async {
    try {
      final res = await Supabase.instance.client
          .from('manufacturers')
          .select('id, name, is_active')
          .eq('is_active', true)
          .order('name');

      final names = (res as List<dynamic>)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .map((row) => (row['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _manufacturers
          ..clear()
          ..addAll(names);
      });
    } catch (e) {
      debugPrint('Error loading manufacturers: $e');
    }
  }

  Future<void> _loadBrands() async {
    try {
      final res = await Supabase.instance.client
          .from('brands')
          .select('id, name, is_active')
          .eq('is_active', true)
          .order('name');

      final names = (res as List<dynamic>)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .map((row) => (row['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _brands
          ..clear()
          ..addAll(names);
      });
    } catch (e) {
      debugPrint('Error loading brands: $e');
    }
  }

  bool _isUuid(String? str) {
    if (str == null) return false;
    final regExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return regExp.hasMatch(str.trim());
  }

  final List<String> _users = [];
  final Map<String, String> _userMap = {};
  List<CategoryNode> _categoryNodes = const [];
  final Map<String, Set<String>> _categoryDescendantIds = {};
  final Map<String, String> _categoryNameById = {};
  final List<String> _manufacturers = [];
  final List<String> _brands = [];

  final List<String> _frequencies = [
    'Every Day',
    'Every Week',
    'Every Month',
    'Every Year',
  ];
  final List<String> _weekdays = const [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  final List<String> _monthlyGenerateModes = const [
    'A Specific Date',
    'A Specific Day',
  ];
  final List<String> _monthlyOrdinals = const [
    'First',
    'Second',
    'Third',
    'Fourth',
    'Last',
  ];
  final List<String> _monthsOfYear = const [
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
  ];

  final List<String> _times = List<String>.generate(48, (index) {
    final totalMinutes = index * 30;
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  });

  final List<String> _expiryOptions = [
    'Never Expires',
    'Number of Counts',
    'Date',
  ];

  @override
  void initState() {
    super.initState();
    _applyRecurringRouteDefaults();
    _syncPreferencesFromNumber(_numberController.text);
    _generateCountOnDays
      ..clear()
      ..add(_weekdayLabelForDate(_startDate));
    _updateStartDateText();
    _syncAllCustomDateControllers();
    _loadWarehouses();
    _loadAssignableUsers();
    _loadCategories();
    _loadManufacturers();
    _loadBrands();
    _loadNextStockCountNumber();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCountData();
      });
    }
  }

  @override
  void didUpdateWidget(covariant StockCountCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startAsRecurring != widget.startAsRecurring ||
        oldWidget.editCountId != widget.editCountId ||
        oldWidget.initialCount != widget.initialCount) {
      _hasLoadedData = false;
      _editingId = null;
      _applyRecurringRouteDefaults();
      if (_isEditMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasLoadedData) {
            _loadCountData();
          }
        });
      }
    }
  }

  void _applyRecurringRouteDefaults() {
    if (!_isEditMode && widget.startAsRecurring) {
      _scheduleCounts = true;
    }
  }

  void _onCancel(String orgId) {
    final detailId = _editingId ?? widget.initialCount?.id ?? widget.editCountId;
    if (detailId != null && detailId.isNotEmpty) {
      context.go('/$orgId/inventory/stock-counts/$detailId');
    } else {
      context.go('/$orgId/inventory/stock-counts');
    }
  }

  void _populateFormFromCount(StockCount count) {
    _editingId = count.id;
    _numberController.text = count.stockCountNum;
    _syncPreferencesFromNumber(count.stockCountNum);
    _scheduleCounts = count.isRecurring;
    _nameController.text = count.recurringName ?? '';
    _descController.text = count.description ?? '';
    if ((count.location ?? '').isNotEmpty) {
      _selectedLocation = count.location!;
    }
    if (_locations.contains(count.assignedTo)) {
      _selectedLocation = count.assignedTo;
      _selectedUser = null;
    } else if (_users.contains(count.assignedTo)) {
      _selectedUser = count.assignedTo;
    } else {
      if (!_users.contains(count.assignedTo)) {
        _users.add(count.assignedTo);
      }
      _selectedUser = count.assignedTo;
    }
    _startDate = count.countDate;
    _generateCountOnDays
      ..clear()
      ..add(_weekdayLabelForDate(_startDate));
    _updateStartDateText();
    _scheduleType = count.scheduleType ?? _scheduleType;
    _frequency = count.frequency ?? _frequency;
    if (_frequency == 'Every Month') {
      _monthlyDayOfMonthController.text = _startDate.day.toString();
      _monthlyWeekday = _weekdayLabelForDate(_startDate);
    } else if (_frequency == 'Every Year') {
      _yearlyDayOfMonthController.text = _startDate.day.toString();
      _yearlyWeekday = _weekdayLabelForDate(_startDate);
      _yearlyMonth = _monthsOfYear[_startDate.month - 1];
    }
    _applyGenerateCountOnValue(count.generateCountOn);
    _generateTime = _normalizeGenerateTime(count.countGenerationTime);
    final parsedExpiryDate = _parseExpiryDate(count.scheduleExpiry);
    _expiryDate = parsedExpiryDate;
    _updateExpiryDateText();
    _expiresAfter = parsedExpiryDate != null
        ? 'Date'
        : (count.scheduleExpiry ?? _expiresAfter);
    _selectedItems = count.items
        .map(
          (item) => Map<String, String>.from(
            item.map((key, value) => MapEntry(key, value.toString())),
          ),
        )
        .toList();
    _addedItemsCount = _selectedItems.length;
    _hasLoadedData = true;
  }

  void _loadCountData() {
    final directCount = widget.initialCount;
    if (directCount != null) {
      setState(() {
        _populateFormFromCount(directCount);
      });
      return;
    }

    final countState = ref.read(stockCountsProvider);
    if (countState.counts.isEmpty) return;

    final count = countState.counts.firstWhere(
      (c) =>
          c.id == widget.editCountId || c.stockCountNum == widget.editCountId,
      orElse: () => StockCount(
        id: '',
        stockCountNum: '',
        assignedTo: '',
        status: StockCountStatus.yetToStart,
        countDate: DateTime.now(),
        totalItems: 0,
      ),
    );
    if (count.id.isEmpty) return;

    setState(() {
      _populateFormFromCount(count);
    });
  }

  void _updateStartDateText() {
    _startDateController.text =
        '${_startDate.day.toString().padLeft(2, '0')}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.year}';
  }

  String _weekdayLabelForDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
      default:
        return 'Sunday';
    }
  }

  int _weekdayValueForLabel(String label) {
    switch (label) {
      case 'Monday':
        return DateTime.monday;
      case 'Tuesday':
        return DateTime.tuesday;
      case 'Wednesday':
        return DateTime.wednesday;
      case 'Thursday':
        return DateTime.thursday;
      case 'Friday':
        return DateTime.friday;
      case 'Saturday':
        return DateTime.saturday;
      case 'Sunday':
      default:
        return DateTime.sunday;
    }
  }

  DateTime _alignDateToSelectedWeekday(DateTime baseDate, String weekdayLabel) {
    final targetWeekday = _weekdayValueForLabel(weekdayLabel);
    final delta = (targetWeekday - baseDate.weekday) % 7;
    return baseDate.add(Duration(days: delta));
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime _resolveMonthlySpecificDate(DateTime baseDate) {
    final parsedDay = int.tryParse(_monthlyDayOfMonthController.text.trim()) ?? 1;
    final clampedDay = parsedDay.clamp(1, _daysInMonth(baseDate.year, baseDate.month));
    return DateTime(baseDate.year, baseDate.month, clampedDay);
  }

  DateTime _resolveMonthlyOrdinalWeekdayDate(DateTime baseDate) {
    final targetWeekday = _weekdayValueForLabel(_monthlyWeekday);
    final lastDay = _daysInMonth(baseDate.year, baseDate.month);

    if (_monthlyOrdinal == 'Last') {
      final monthEnd = DateTime(baseDate.year, baseDate.month, lastDay);
      final delta = (monthEnd.weekday - targetWeekday) % 7;
      return monthEnd.subtract(Duration(days: delta));
    }

    final ordinalIndex = _monthlyOrdinals.indexOf(_monthlyOrdinal);
    final weekIndex = ordinalIndex < 0 ? 0 : ordinalIndex;
    final monthStart = DateTime(baseDate.year, baseDate.month, 1);
    final delta = (targetWeekday - monthStart.weekday) % 7;
    final day = 1 + delta + (weekIndex * 7);
    if (day > lastDay) {
      return DateTime(baseDate.year, baseDate.month, lastDay);
    }
    return DateTime(baseDate.year, baseDate.month, day);
  }

  int _monthNumberForLabel(String label) {
    final index = _monthsOfYear.indexOf(label);
    return index >= 0 ? index + 1 : 1;
  }

  DateTime _resolveYearlySpecificDate(DateTime baseDate) {
    final month = _monthNumberForLabel(_yearlyMonth);
    final parsedDay = int.tryParse(_yearlyDayOfMonthController.text.trim()) ?? 1;
    final clampedDay = parsedDay.clamp(1, _daysInMonth(baseDate.year, month));
    return DateTime(baseDate.year, month, clampedDay);
  }

  DateTime _resolveYearlyOrdinalWeekdayDate(DateTime baseDate) {
    final month = _monthNumberForLabel(_yearlyMonth);
    final targetWeekday = _weekdayValueForLabel(_yearlyWeekday);
    final lastDay = _daysInMonth(baseDate.year, month);

    if (_yearlyOrdinal == 'Last') {
      final monthEnd = DateTime(baseDate.year, month, lastDay);
      final delta = (monthEnd.weekday - targetWeekday) % 7;
      return monthEnd.subtract(Duration(days: delta));
    }

    final ordinalIndex = _monthlyOrdinals.indexOf(_yearlyOrdinal);
    final weekIndex = ordinalIndex < 0 ? 0 : ordinalIndex;
    final monthStart = DateTime(baseDate.year, month, 1);
    final delta = (targetWeekday - monthStart.weekday) % 7;
    final day = 1 + delta + (weekIndex * 7);
    if (day > lastDay) {
      return DateTime(baseDate.year, month, lastDay);
    }
    return DateTime(baseDate.year, month, day);
  }

  DateTime _resolvePeriodicBaseDate(DateTime baseDate) {
    if (_frequency == 'Every Week') {
      return _alignDateToSelectedWeekday(baseDate, _primaryGenerateCountOn);
    }
    if (_frequency == 'Every Month') {
      if (_monthlyGenerateCountMode == 'A Specific Day') {
        return _resolveMonthlyOrdinalWeekdayDate(baseDate);
      }
      return _resolveMonthlySpecificDate(baseDate);
    }
    if (_frequency == 'Every Year') {
      if (_yearlyGenerateCountMode == 'A Specific Day') {
        return _resolveYearlyOrdinalWeekdayDate(baseDate);
      }
      return _resolveYearlySpecificDate(baseDate);
    }
    return baseDate;
  }

  void _updateExpiryDateText() {
    _expiryDateController.text = _expiryDate == null
        ? ''
        : '${_expiryDate!.day.toString().padLeft(2, '0')}-'
              '${_expiryDate!.month.toString().padLeft(2, '0')}-'
              '${_expiryDate!.year}';
  }

  DateTime? _parseExpiryDate(String? rawValue) {
    final raw = rawValue?.trim() ?? '';
    if (raw.isEmpty) return null;

    final normalized = raw.startsWith('On ') ? raw.substring(3).trim() : raw;
    final dashMatch = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(normalized);
    if (dashMatch != null) {
      final day = int.tryParse(dashMatch.group(1) ?? '');
      final month = int.tryParse(dashMatch.group(2) ?? '');
      final year = int.tryParse(dashMatch.group(3) ?? '');
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    final textMatch = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})$',
    ).firstMatch(normalized);
    if (textMatch == null) return null;

    const months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final day = int.tryParse(textMatch.group(1) ?? '');
    final month = months[textMatch.group(2)];
    final year = int.tryParse(textMatch.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String? _buildScheduleExpiryValue() {
    if (!_scheduleCounts) return null;
    if (_expiresAfter != 'Date') return _expiresAfter;
    if (_expiryDate == null) return null;

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return 'On ${_expiryDate!.day.toString().padLeft(2, '0')} '
        '${months[_expiryDate!.month - 1]} ${_expiryDate!.year}';
  }

  void _hideExpiryDatePopup() {
    _expiryDateOverlayEntry?.remove();
    _expiryDateOverlayEntry = null;
  }

  void _showExpiryDatePopup() {
    if (_expiryDateOverlayEntry != null) {
      _hideExpiryDatePopup();
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    _expiryDateOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _expiryDateLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.bottomLeft,
                offset: const Offset(0, -6),
                child: IgnorePointer(
                  ignoring: false,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ZerpaiCalendar(
                        selectedDate: _expiryDate ?? _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        onDateSelected: (date) {
                          if (!mounted) return;
                          setState(() {
                            _expiryDate = date;
                            _updateExpiryDateText();
                          });
                          _hideExpiryDatePopup();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(_expiryDateOverlayEntry!);
  }

  void _syncPreferencesFromNumber(String stockCountNum) {
    final trimmed = stockCountNum.trim();
    if (trimmed.isEmpty) return;

    final match = RegExp(r'^([^\d]*)(\d+)$').firstMatch(trimmed);
    if (match != null) {
      _prefixController.text = match.group(1) ?? '';
      _nextNumberController.text = match.group(2) ?? '';
      return;
    }

    _prefixController.text = trimmed;
    _nextNumberController.text = '';
  }

  void _syncNumberFromPreferences() {
    final prefix = _prefixController.text.trim();
    final nextNumber = _nextNumberController.text.trim();
    _numberController.text = '$prefix$nextNumber';
  }

  String? _normalizeGenerateTime(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;

    final twentyFourHourMatch = RegExp(r'^(\d{2}):(\d{2})').firstMatch(raw);
    if (twentyFourHourMatch != null) {
      final normalized =
          '${twentyFourHourMatch.group(1)}:${twentyFourHourMatch.group(2)}';
      return _times.contains(normalized) ? normalized : null;
    }

    final twelveHourMatch = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (twelveHourMatch == null) return null;

    final hour = int.tryParse(twelveHourMatch.group(1) ?? '');
    final minute = int.tryParse(twelveHourMatch.group(2) ?? '');
    final meridiem = (twelveHourMatch.group(3) ?? '').toUpperCase();
    if (hour == null || minute == null) return null;

    var normalizedHour = hour % 12;
    if (meridiem == 'PM') {
      normalizedHour += 12;
    }

    final normalized =
        '${normalizedHour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
    return _times.contains(normalized) ? normalized : null;
  }

  String? _buildGenerateCountOnValue() {
    if (!_scheduleCounts) return null;

    final payload = <String, dynamic>{
      'frequency': _frequency,
      'frequency_value': _frequencyValue,
    };

    if (_frequency == 'Every Week') {
      payload['type'] = 'weekly';
      payload['days'] = _generateCountOnDays.toList();
    } else if (_frequency == 'Every Month') {
      payload['type'] = 'monthly';
      payload['mode'] = _monthlyGenerateCountMode;
      if (_monthlyGenerateCountMode == 'A Specific Date') {
        payload['day'] =
            int.tryParse(_monthlyDayOfMonthController.text.trim()) ?? 1;
      } else {
        payload['ordinal'] = _monthlyOrdinal;
        payload['weekday'] = _monthlyWeekday;
      }
    } else if (_frequency == 'Every Year') {
      payload['type'] = 'yearly';
      payload['mode'] = _yearlyGenerateCountMode;
      payload['month'] = _yearlyMonth;
      if (_yearlyGenerateCountMode == 'A Specific Date') {
        payload['day'] =
            int.tryParse(_yearlyDayOfMonthController.text.trim()) ?? 1;
      } else {
        payload['ordinal'] = _yearlyOrdinal;
        payload['weekday'] = _yearlyWeekday;
      }
    } else {
      payload['type'] = 'daily';
    }

    if (_scheduleType == 'Custom') {
      payload['custom_dates'] = _customDates
          .where((d) => d != null)
          .map(
            (d) =>
                '${d!.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          )
          .toList();
    }

    return jsonEncode(payload);
  }

  void _applyGenerateCountOnValue(Object? rawValue) {
    if (rawValue == null) return;

    Map<String, dynamic>? decoded;
    if (rawValue is String) {
      final trimmed = rawValue.trim();
      if (trimmed.isEmpty) return;
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        } else if (parsed is Map) {
          decoded = Map<String, dynamic>.from(parsed);
        }
      } catch (_) {
        return;
      }
    } else if (rawValue is Map<String, dynamic>) {
      decoded = rawValue;
    } else if (rawValue is Map) {
      decoded = Map<String, dynamic>.from(rawValue);
    }

    if (decoded == null) return;

    final frequency = decoded['frequency']?.toString();
    if (frequency != null && frequency.isNotEmpty) {
      _frequency = frequency;
    }

    final frequencyValue = int.tryParse(
      decoded['frequency_value']?.toString() ?? '',
    );
    if (frequencyValue != null && frequencyValue > 0) {
      _frequencyValue = frequencyValue;
      _frequencyValueController.text = frequencyValue.toString();
    }

    final type = decoded['type']?.toString();
    if (type == 'weekly') {
      final days = (decoded['days'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList();
      if (days.isNotEmpty) {
        _generateCountOnDays
          ..clear()
          ..addAll(days);
      }
    } else if (type == 'monthly') {
      _monthlyGenerateCountMode =
          decoded['mode']?.toString() ?? _monthlyGenerateCountMode;
      if (_monthlyGenerateCountMode == 'A Specific Date') {
        final day =
            int.tryParse(decoded['day']?.toString() ?? '') ?? _startDate.day;
        _monthlyDayOfMonthController.text = day.toString();
      } else {
        _monthlyOrdinal =
            decoded['ordinal']?.toString() ?? _monthlyOrdinal;
        _monthlyWeekday =
            decoded['weekday']?.toString() ?? _monthlyWeekday;
      }
    } else if (type == 'yearly') {
      _yearlyGenerateCountMode =
          decoded['mode']?.toString() ?? _yearlyGenerateCountMode;
      _yearlyMonth = decoded['month']?.toString() ?? _yearlyMonth;
      if (_yearlyGenerateCountMode == 'A Specific Date') {
        final day =
            int.tryParse(decoded['day']?.toString() ?? '') ?? _startDate.day;
        _yearlyDayOfMonthController.text = day.toString();
      } else {
        _yearlyOrdinal = decoded['ordinal']?.toString() ?? _yearlyOrdinal;
        _yearlyWeekday = decoded['weekday']?.toString() ?? _yearlyWeekday;
      }
    }

    final customDates = (decoded['custom_dates'] as List<dynamic>? ?? const [])
        .map((value) => DateTime.tryParse(value.toString()))
        .whereType<DateTime>()
        .toList();
    if (customDates.isNotEmpty) {
      _customDates
        ..clear()
        ..addAll(customDates);
      while (_customDateControllers.length < _customDates.length) {
        _customDateKeys.add(GlobalKey());
        _customDateLinks.add(LayerLink());
        _customDateControllers.add(TextEditingController());
      }
      while (_customDateControllers.length > _customDates.length) {
        _customDateKeys.removeLast();
        _customDateLinks.removeLast();
        _customDateControllers.removeLast().dispose();
      }
      _syncAllCustomDateControllers();
    }
  }

  void _syncCustomDateController(int index) {
    if (index < 0 || index >= _customDateControllers.length) return;
    final dateValue = _customDates[index];
    _customDateControllers[index].text = dateValue == null
        ? ''
        : '${dateValue.day.toString().padLeft(2, '0')}-'
              '${dateValue.month.toString().padLeft(2, '0')}-'
              '${dateValue.year}';
  }

  void _syncAllCustomDateControllers() {
    for (var i = 0; i < _customDateControllers.length; i++) {
      _syncCustomDateController(i);
    }
  }

  void _addCustomDateField([DateTime? value]) {
    _customDates.add(value);
    _customDateKeys.add(GlobalKey());
    _customDateLinks.add(LayerLink());
    final controller = TextEditingController();
    _customDateControllers.add(controller);
    final index = _customDateControllers.length - 1;
    final dateValue = _customDates[index];
    controller.text = dateValue == null
        ? ''
        : '${dateValue.day.toString().padLeft(2, '0')}-'
              '${dateValue.month.toString().padLeft(2, '0')}-'
              '${dateValue.year}';
  }

  void _removeCustomDateField(int index) {
    _customDates.removeAt(index);
    _customDateKeys.removeAt(index);
    _customDateLinks.removeAt(index);
    _customDateControllers.removeAt(index).dispose();
    if (_customDates.isEmpty) {
      _addCustomDateField();
    }
  }

  String get _frequencyUnit {
    if (_frequency.contains('Day')) return 'Day';
    if (_frequency.contains('Week')) return 'Week';
    if (_frequency.contains('Month')) return 'Month';
    if (_frequency.contains('Year')) return 'Year';
    return 'Day';
  }

  @override
  void dispose() {
    _hideExpiryDatePopup();
    _numberController.dispose();
    _prefixController.dispose();
    _nextNumberController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _remindBeforeController.dispose();
    _startDateController.dispose();
    _expiryDateController.dispose();
    _addedItemsSearchController.dispose();
    _monthlyDayOfMonthController.dispose();
    _yearlyDayOfMonthController.dispose();
    _frequencyValueController.dispose();
    for (final controller in _customDateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double _parseNumericValue(String? value) {
    final sanitized = (value ?? '').replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }

  List<Map<String, dynamic>> _buildSavedItems() {
    return _selectedItems.map((item) {
      return <String, dynamic>{
        'product_id': item['product_id'] ?? '',
        'name': item['name'] ?? '',
        'sku': item['sku'] ?? '',
        'systemQty': _parseNumericValue(item['stock']),
        'countedQty': null,
        'unit': item['unit'] ?? 'pcs',
        'rate': _parseNumericValue(item['rate']),
        'batches': <Map<String, dynamic>>[],
      };
    }).toList();
  }

  DateTime? _resolveNextCountDate() {
    if (!_scheduleCounts) return null;

    final baseDate = _resolvePeriodicBaseDate(_startDate);

    final days = _frequency.contains('Week')
        ? 7 * _frequencyValue
        : _frequency.contains('Month')
        ? 30 * _frequencyValue
        : _frequency.contains('Year')
        ? 365 * _frequencyValue
        : _frequencyValue;

    return baseDate.add(Duration(days: days));
  }

  String get _selectedWarehouseDisplayLabel {
    final selectedName = _selectedLocation.trim();
    if (selectedName.isEmpty) return 'Warehouse: -';
    return 'Warehouse: $selectedName';
  }

  String? get _selectedWarehouseId {
    final selectedName = _selectedLocation.trim();
    if (selectedName.isEmpty) return null;

    final selectedWarehouse = _dbWarehouses.cast<Map<String, dynamic>?>().firstWhere(
      (warehouse) => warehouse?['name'] == selectedName,
      orElse: () => null,
    );

    final warehouseId = selectedWarehouse?['id']?.toString().trim();
    if (warehouseId == null || warehouseId.isEmpty) return null;
    return warehouseId;
  }

  Future<void> _saveStockCount(String orgId) async {
    final bool hasUploadedFile = _importItems && _selectedFile != null;
    if (!hasUploadedFile && _selectedItems.isEmpty) {
      setState(() {
        _showItemsWarning = true;
      });
      return;
    }

    // For recurring counts, use name as the stock_count_number if number is empty.
    final String stockCountNum;
    if (_scheduleCounts) {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        stockCountNum = name;
      } else {
        stockCountNum = 'R${DateTime.now().millisecondsSinceEpoch % 100000}';
      }
    } else {
      final num = _numberController.text.trim();
      stockCountNum = num.isNotEmpty
          ? num
          : 'D${DateTime.now().millisecondsSinceEpoch % 100000}';
    }

    final selectedWarehouse = _dbWarehouses.firstWhere(
      (w) => w['name'] == _selectedLocation,
      orElse: () => <String, dynamic>{},
    );
    final warehouseUuid =
        selectedWarehouse['id'] ??
        (_dbWarehouses.isNotEmpty ? _dbWarehouses.first['id'] : null);

    // Guard: warehouse UUID required by DB schema.
    if (warehouseUuid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not determine warehouse. Please reload the page and try again.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final effectiveRecurringDate = _resolvePeriodicBaseDate(_startDate);
    final countDate = _scheduleCounts
        ? effectiveRecurringDate
        : (_customDates.isNotEmpty ? (_customDates.first ?? DateTime.now()) : DateTime.now());
    final formattedCountDate =
        '${countDate.year}-${countDate.month.toString().padLeft(2, '0')}-'
        '${countDate.day.toString().padLeft(2, '0')}';
    // generate_count_at is NOT NULL in DB — always provide a valid time string.
    final String formattedTime;
    final rawTime = (_generateTime ?? '11:00').trim();
    if (rawTime.isEmpty) {
      formattedTime = '11:00:00';
    } else if (rawTime.split(':').length == 2) {
      formattedTime = '$rawTime:00'; // '11:00' → '11:00:00'
    } else {
      formattedTime = rawTime; // already has seconds
    }
    final savedItems = _buildSavedItems();
    final scheduleExpiryValue = _buildScheduleExpiryValue();
    final generateCountOnValue = _buildGenerateCountOnValue();

    final localCount = StockCount(
      id: _editingId ??
          widget.initialCount?.id ??
          widget.editCountId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      stockCountNum: stockCountNum,
      recurringName: _scheduleCounts ? _nameController.text.trim() : null,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      location: _selectedLocation,
      assignedTo: _selectedUser ?? _selectedLocation,
      status: StockCountStatus.yetToStart,
      countDate: countDate,
      isRecurring: _scheduleCounts,
      scheduleType: _scheduleCounts ? _scheduleType : null,
      frequency: _scheduleCounts ? _frequency : null,
      scheduleStartDate: _scheduleCounts ? effectiveRecurringDate : null,
      scheduleExpiry: scheduleExpiryValue,
      countGenerationTime: _scheduleCounts ? _generateTime : null,
      generateCountOn: generateCountOnValue,
      nextCountDate: _resolveNextCountDate(),
      isActive: _scheduleCounts,
      totalItems: savedItems.length,
      items: savedItems,
    );

    final remindBeforeVal = double.tryParse(_remindBeforeController.text) ?? 0.0;
    
    final authUser = ref.read(authUserProvider);
    final entityId = authUser?.activeEntityId ?? authUser?.orgEntityId;

    final String? resolvedAssignToUuid = _selectedUser != null ? _userMap[_selectedUser] : null;

    final insertPayload = <String, dynamic>{
      'stock_count_number': stockCountNum,
      'description': localCount.description,
      'warehouse': warehouseUuid,
      'warehouse_id': warehouseUuid,
      'assign_to': resolvedAssignToUuid,
      'schedule_type': _scheduleCounts ? _scheduleType : 'Manual',
      'frequency': _scheduleCounts ? _frequency : null,
      'schedule_starts_on': formattedCountDate,
      'generate_count_at': formattedTime,
      'schedule_expires_after': scheduleExpiryValue,
      'remind_before': remindBeforeVal,
      'execution_time': formattedTime,
      'is_schedule_enabled': _scheduleCounts,
      'entity_id': entityId,
    };

    if (_editingId != null && _isUuid(_editingId)) {
      insertPayload['id'] = _editingId;
    } else if (widget.initialCount?.id != null &&
        _isUuid(widget.initialCount!.id)) {
      insertPayload['id'] = widget.initialCount!.id;
    } else if (widget.editCountId != null && _isUuid(widget.editCountId)) {
      insertPayload['id'] = widget.editCountId;
    }

    String? stockCountDbId;
    String? recurringStockCountDbId;
    try {
      final supabase = Supabase.instance.client;

      if (_scheduleCounts) {
        final recurringRecordId =
            (_editingId != null && _isUuid(_editingId))
                ? _editingId!
                : (widget.initialCount?.id != null &&
                        _isUuid(widget.initialCount!.id))
                    ? widget.initialCount!.id
                    : (widget.editCountId != null &&
                            _isUuid(widget.editCountId))
                        ? widget.editCountId!
                        : _uuid.v4();

        final customDatesJson = _customDates
            .where((d) => d != null)
            .map((d) => '${d!.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
            .toList();

        final recurringPayload = <String, dynamic>{
          'id': recurringRecordId,
          'schedule_type': _scheduleType,
          'frequency': _frequency,
          'schedule_starts_on': formattedCountDate,
          'generate_count_at': formattedTime,
          'schedule_expires_after': scheduleExpiryValue,
          'execution_time': formattedTime,
          'remind_before': remindBeforeVal,
          'generate_count_on': generateCountOnValue,
          'custom_schedule_dates': customDatesJson,
          'is_active': true,
          'entity_id': entityId,
          'stock_count_number': stockCountNum,
          'description': localCount.description,
          'warehouse': warehouseUuid,
          'assign_to': resolvedAssignToUuid,
          'status': 'Yet to Start',
        };

        final recResponse = await supabase
            .from('inventory_recurring_stock_count')
            .upsert(recurringPayload)
            .select('id')
            .single();

        recurringStockCountDbId = recResponse['id'] as String?;
        if (recurringStockCountDbId == null) throw Exception('No id returned from inventory_recurring_stock_count upsert');
      } else {
        // It's a manual count - Only save in inventory_stock_count
        final manualPayload = Map<String, dynamic>.from(insertPayload);
        final scResponse = await supabase
            .from('inventory_stock_count')
            .upsert(manualPayload)
            .select('id')
            .single();

        stockCountDbId = scResponse['id'] as String?;
        if (stockCountDbId == null) throw Exception('No id returned from inventory_stock_count upsert');
      }

      // 2. Replace existing item rows
      final itemForeignKeyColumn = 'stock_count_id';
      final itemTargetId = _scheduleCounts
          ? recurringStockCountDbId
          : stockCountDbId;

      await supabase
          .from('stock_count_items')
          .delete()
          .eq(itemForeignKeyColumn, itemTargetId!);


       // 3. Build and insert stock_count_items rows.
      if (_selectedItems.isNotEmpty) {
        final itemRows = _selectedItems
            .where((item) => (item['product_id'] ?? '').isNotEmpty)
            .map((item) {
          final rawRate = (item['rate'] ?? '').replaceAll(RegExp(r'[^\d.]'), '');
          final rate = double.tryParse(rawRate) ?? 0.0;
          return <String, dynamic>{
            itemForeignKeyColumn: itemTargetId,
            'product_id': item['product_id'],
            'sku': item['sku']?.isNotEmpty == true ? item['sku'] : 'N/A',
            'rate': rate,
          };
        }).toList();

        if (itemRows.isNotEmpty) {
          await supabase.from('stock_count_items').insert(itemRows);
        }
      }

      // 4. Handle attachment upload and save if import items toggle is on and a file is selected.
      if (_importItems && _selectedFile != null) {
        final uploadedUrl = await StorageService().uploadStockCountAttachment(_selectedFile!);
        if (uploadedUrl == null) {
          throw Exception('Failed to upload file to storage. Please try again.');
        }

        // Clean up previous attachments for this count
        final attachmentTable = _scheduleCounts 
            ? 'inventory_recurring_stock_count_attachments'
            : 'inventory_stock_count_attachments';
        final attachmentForeignKeyColumn = _scheduleCounts
            ? 'recurring_stock_count_id'
            : 'stock_count_id';
        final attachmentTargetId = _scheduleCounts
            ? recurringStockCountDbId
            : stockCountDbId;
            
        await supabase
            .from(attachmentTable)
            .delete()
            .eq(attachmentForeignKeyColumn, attachmentTargetId!);

        // Insert new attachment record
        await supabase.from(attachmentTable).insert({
          attachmentForeignKeyColumn: attachmentTargetId,
          'file_name': _selectedFileName ?? 'imported_items',
          'original_file_name': _selectedFileName ?? 'imported_items',
          'file_url': uploadedUrl,
          'file_type': _selectedFile!.extension ?? 'csv',
          'file_size': _selectedFile!.size,
        });
      }
    } catch (err) {
      debugPrint('Error saving stock count config to Supabase: $err');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save stock count: $err'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return; // abort — don't show success or navigate
    }

    final savedId = _scheduleCounts
        ? recurringStockCountDbId
        : stockCountDbId;
    final persistedCount = localCount.copyWith(
      id: savedId ?? localCount.id,
      location: _selectedLocation,
    );

    final notifier = ref.read(stockCountsProvider.notifier);
    if (_isEditMode) {
      notifier.updateCount(persistedCount);
    } else {
      notifier.addCount(persistedCount);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditMode
              ? 'Stock count ${persistedCount.stockCountNum} updated successfully.'
              : 'Stock count ${persistedCount.stockCountNum} saved successfully.',
        ),
        backgroundColor: const Color(0xFF22A95E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    final targetRoute = _scheduleCounts
        ? AppRoutes.recurringStockCounts
        : AppRoutes.stockCounts;
    context.go('/$orgId$targetRoute');
  }

  void _showPreferencesDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.only(top: 0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Container(
                  color: const Color(0xFFF7FAF9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Configure Stock Count# Preferences',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppTheme.errorRed,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Full-width grey line under header
                Container(height: 1, color: AppTheme.borderColor),

                // Content section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Stock Counts numbers are set on auto-generate mode to save your time. '
                        'Are you sure about changing this setting?',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Radio<bool>(
                              value: true,
                              groupValue: true,
                              activeColor: AppTheme.primaryBlueDark,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (_) {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Continue auto-generating Stock Counts numbers',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const ZTooltip(
                            message: 'Enable automated numbering sequence',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Prefix',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  CustomTextField(
                                    controller: _prefixController,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next Number',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  CustomTextField(
                                    controller: _nextNumberController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ZButton.primary(
                            label: 'Save',
                            onPressed: () {
                              final nextNumber = _nextNumberController.text
                                  .trim();
                              if (nextNumber.isEmpty ||
                                  int.tryParse(nextNumber) == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid next number.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _prefixController.text = _prefixController.text
                                    .trim();
                                _nextNumberController.text = nextNumber;
                                _syncNumberFromPreferences();
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                          const SizedBox(width: 12),
                          ZButton.secondary(
                            label: 'Cancel',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditMode && !_hasLoadedData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasLoadedData) {
          _loadCountData();
        }
      });
    }

    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final title = _isEditMode
        ? (_scheduleCounts ? 'Edit Recurring Stock Count' : 'Edit Stock Count')
        : (_scheduleCounts ? 'New Recurring Stock Count' : 'New Stock Count');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => _onCancel(orgId),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stepper Row
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _currentStep = 0;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: _currentStep == 1
                                ? const Color(0xFF22A95E)
                                : AppTheme.infoBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Configure',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _currentStep == 1
                                  ? const Color(0xFF22A95E)
                                  : AppTheme.infoBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentStep == 1
                                ? Icons.check_circle_outline
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: _currentStep == 1
                                ? AppTheme.infoBlue
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add Items',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              fontWeight: _currentStep == 1
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _currentStep == 1
                                  ? AppTheme.infoBlue
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Underline indicator for active step
                Row(
                  children: [
                    if (_currentStep == 0)
                      Container(width: 90, height: 2, color: AppTheme.infoBlue)
                    else ...[
                      const SizedBox(width: 110),
                      Container(width: 90, height: 2, color: AppTheme.infoBlue),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Divider Line
          const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),

          // Form Content Section
          Expanded(
            child: _currentStep == 1
                ? _buildAddItemsStep()
                : SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showNameWarning) ...[
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                  top: 24,
                                  bottom: 16,
                                  left: 24,
                                  right: 24,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEEDEE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '• $_primaryCountFieldWarning',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showNameWarning = false;
                                        });
                                      },
                                      child: const Icon(
                                        LucideIcons.x,
                                        size: 18,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_showAssignWarning) ...[
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                  top: 24,
                                  bottom: 16,
                                  left: 24,
                                  right: 24,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEEDEE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        '• Select a user to whom you want to assign the stock count.',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showAssignWarning = false;
                                        });
                                      },
                                      child: const Icon(
                                        LucideIcons.x,
                                        size: 18,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // Conditional First Field
                                if (!_scheduleCounts) ...[
                                  // Stock Count# Row
                                  ZerpaiFormRow(
                                    label: 'Stock Count#',
                                    required: true,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CustomTextField(
                                            controller: _numberController,
                                            suffixWidget: ZTooltip(
                                              message:
                                                  'Click here to change AutoGenerate Number Order',
                                              direction: ZTooltipDirection.bottom,
                                              child: IconButton(
                                                icon: const Icon(
                                                  LucideIcons.settings,
                                                  size: 16,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () =>
                                                    _showPreferencesDialog(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 26),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Stock Count Name* Row
                                  ZerpaiFormRow(
                                    label: 'Stock Count Name',
                                    required: true,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CustomTextField(
                                            controller: _nameController,
                                            hintText:
                                                'Enter a Stock Count Name',
                                            onChanged: (_) {
                                              if (_showNameWarning) {
                                                setState(() {
                                                  _showNameWarning = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 26),
                                      ],
                                    ),
                                  ),
                                ],

                                // Description Row
                                ZerpaiFormRow(
                                  label: 'Description',
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ResizableBox(
                                          initialHeight: _descHeight,
                                          minHeight: 60,
                                          maxHeight: 200,
                                          onResize: (val) {
                                            setState(() => _descHeight = val);
                                          },
                                          child: CustomTextField(
                                            controller: _descController,
                                            maxLines: null,
                                            height: _descHeight,
                                            hintText: 'Max. 500 characters',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 26),
                                    ],
                                  ),
                                ),

                                ZerpaiFormRow(
                                  label: 'Warehouse',
                                  required: true,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: FormDropdown<String>(
                                          value: _selectedLocation,
                                          height: _fieldHeight,
                                          placeholder: 'Select warehouse',
                                          items: _locations,
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _selectedLocation = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 26),
                                    ],
                                  ),
                                ),

                                // Assign To Row
                                ZerpaiFormRow(
                                  label: 'Assign To',
                                  required: true,
                                  tooltipMessage:
                                      'Only users who have permission to count stock and to the selected location will be listed here. You can assign the Count Stock role to other users by configuring their role under Users and Roles in Settings.',
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: FormDropdown<String>(
                                          value: _selectedUser,
                                          height: _fieldHeight,
                                          placeholder: 'Select user',
                                          items: _users,
                                          onChanged: (v) {
                                            setState(() {
                                              _selectedUser = v;
                                              if (v != null) {
                                                _showAssignWarning = false;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 26),
                                    ],
                                  ),
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.space20,
                                    vertical: 8,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppTheme.borderColor,
                                  ),
                                ),

                                // Schedule Counts Checkbox
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space20,
                                    vertical: AppTheme.space12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: _scheduleCounts,
                                          onChanged: (v) => setState(
                                            () => _scheduleCounts = v ?? false,
                                          ),
                                          activeColor: AppTheme.primaryBlueDark,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Schedule Counts',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Conditional Schedule configuration
                                if (_scheduleCounts) ...[
                                  // Schedule Type Row
                                  ZerpaiFormRow(
                                    label: 'Schedule Type',
                                    required: true,
                                    child: Row(
                                      children: [
                                        Radio<String>(
                                          value: 'Periodic',
                                          activeColor: AppTheme.primaryBlueDark,
                                          groupValue: _scheduleType,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (v) => setState(
                                            () => _scheduleType = v!,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Periodic',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(width: 24),
                                        Radio<String>(
                                          value: 'Custom',
                                          activeColor: AppTheme.primaryBlueDark,
                                          groupValue: _scheduleType,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (v) => setState(
                                            () => _scheduleType = v!,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Custom',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (_scheduleType == 'Periodic') ...[
                                    // Frequency Row
                                    ZerpaiFormRow(
                                      label: 'Frequency',
                                      required: true,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: FormDropdown<String>(
                                                  value: _frequency,
                                                  height: _fieldHeight,
                                                  items: _frequencies,
                                                  onChanged: (v) {
                                                    if (v != null) {
                                                      setState(() {
                                                        _frequency = v;
                                                        if (_frequency ==
                                                            'Every Week') {
                                                          _generateCountOnDays
                                                            ..clear()
                                                            ..add(
                                                              _weekdayLabelForDate(
                                                                _startDate,
                                                              ),
                                                            );
                                                        } else if (_frequency ==
                                                            'Every Month') {
                                                          _monthlyDayOfMonthController
                                                                  .text =
                                                              _startDate.day
                                                                  .toString();
                                                          _monthlyWeekday =
                                                              _weekdayLabelForDate(
                                                                _startDate,
                                                              );
                                                        } else if (_frequency ==
                                                            'Every Year') {
                                                          _yearlyDayOfMonthController
                                                                  .text =
                                                              _startDate.day
                                                                  .toString();
                                                          _yearlyWeekday =
                                                              _weekdayLabelForDate(
                                                                _startDate,
                                                              );
                                                          _yearlyMonth =
                                                              _monthsOfYear[
                                                                _startDate
                                                                        .month -
                                                                    1
                                                              ];
                                                        }
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 26),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (_isEditingFrequencyValue)
                                            Row(
                                              children: [
                                                const Icon(
                                                  LucideIcons.info,
                                                  size: 14,
                                                  color: AppTheme.infoBlue,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Stock Count will be generated every ',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                  height: _fieldHeight,
                                                  child: TextField(
                                                    controller:
                                                        _frequencyValueController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                    decoration: const InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 6,
                                                          ),
                                                      border: UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                              .borderColor,
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: AppTheme
                                                                  .borderColor,
                                                            ),
                                                          ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color: AppTheme
                                                                  .primaryBlueDark,
                                                            ),
                                                          ),
                                                    ),
                                                    onChanged: (val) {
                                                      final parsed =
                                                          int.tryParse(val);
                                                      if (parsed != null) {
                                                        setState(
                                                          () =>
                                                              _frequencyValue =
                                                                  parsed,
                                                        );
                                                      }
                                                    },
                                                    onSubmitted: (_) {
                                                      setState(
                                                        () =>
                                                            _isEditingFrequencyValue =
                                                                false,
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Text(
                                                  ' $_frequencyUnit(s)',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Row(
                                              children: [
                                                const Icon(
                                                  LucideIcons.info,
                                                  size: 14,
                                                  color: AppTheme.infoBlue,
                                                ),
                                                const SizedBox(width: 6),
                                                RichText(
                                                  text: TextSpan(
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppTheme
                                                          .textSecondary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                    children: [
                                                      const TextSpan(
                                                        text:
                                                            'Stock Count will be generated every ',
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            '$_frequencyValue $_frequencyUnit(s) ',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                      TextSpan(text: ''),
                                                      WidgetSpan(
                                                        alignment:
                                                            PlaceholderAlignment
                                                                .middle,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            setState(
                                                              () =>
                                                                  _isEditingFrequencyValue =
                                                                      true,
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Change',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: AppTheme
                                                                  .infoBlue,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                              fontFamily:
                                                                  'Inter',
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),

                                    if (_frequency == 'Every Week')
                                      ZerpaiFormRow(
                                        label: 'Generate Count On',
                                        required: true,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: FormDropdown<String>(
                                                key: const ValueKey(
                                                  'weekly-generate-count-on-multi',
                                                ),
                                                value: null,
                                                height: _fieldHeight,
                                                items: _weekdays,
                                                menuMaxHeight: 248,
                                                multiSelect: true,
                                                selectedValues:
                                                    _generateCountOnDays
                                                        .toList(),
                                                allowClear: false,
                                                hideSelectedItemsInMultiSelect:
                                                    true,
                                                onChanged: (_) {},
                                                onSelectedValuesChanged:
                                                    (values) {
                                                  if (values.isEmpty) return;
                                                  setState(() {
                                                    _generateCountOnDays
                                                      ..clear()
                                                      ..addAll(values);
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 26),
                                          ],
                                        ),
                                      ),

                                    if (_frequency == 'Every Month')
                                      ZerpaiFormRow(
                                        label: 'Generate Count On',
                                        required: true,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 154,
                                              child: FormDropdown<String>(
                                                value: _monthlyGenerateCountMode,
                                                height: _fieldHeight,
                                                items: _monthlyGenerateModes,
                                                showSearch: false,
                                                menuMaxHeight: 88,
                                                maxVisibleItems: 2,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(() {
                                                    _monthlyGenerateCountMode =
                                                        value;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (_monthlyGenerateCountMode ==
                                                'A Specific Date') ...[
                                              const Text(
                                                'Day',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 52,
                                                child: CustomTextField(
                                                  controller:
                                                      _monthlyDayOfMonthController,
                                                  height: _fieldHeight,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  onChanged: (_) => setState(() {}),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Flexible(
                                                child: Text(
                                                  'of the month',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ] else ...[
                                              Flexible(
                                                flex: 2,
                                                child: FormDropdown<String>(
                                                  value: _monthlyOrdinal,
                                                  height: _fieldHeight,
                                                  items: _monthlyOrdinals,
                                                  menuMaxHeight: 220,
                                                  onChanged: (value) {
                                                    if (value == null) return;
                                                    setState(() {
                                                      _monthlyOrdinal = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                flex: 3,
                                                child: FormDropdown<String>(
                                                  value: _monthlyWeekday,
                                                  height: _fieldHeight,
                                                  items: _weekdays,
                                                  menuMaxHeight: 248,
                                                  onChanged: (value) {
                                                    if (value == null) return;
                                                    setState(() {
                                                      _monthlyWeekday = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                            const SizedBox(width: 26),
                                          ],
                                        ),
                                      ),

                                    if (_frequency == 'Every Year')
                                      ZerpaiFormRow(
                                        label: 'Generate Count On',
                                        required: true,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 118,
                                              child: FormDropdown<String>(
                                                value: _yearlyGenerateCountMode,
                                                height: _fieldHeight,
                                                items: _monthlyGenerateModes,
                                                showSearch: false,
                                                menuMaxHeight: 88,
                                                maxVisibleItems: 2,
                                                menuWidth: 136,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                iconSize: 14,
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(() {
                                                    _yearlyGenerateCountMode =
                                                        value;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            if (_yearlyGenerateCountMode ==
                                                'A Specific Date') ...[
                                              const Text(
                                                'On',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              SizedBox(
                                                width: 92,
                                                child: FormDropdown<String>(
                                                  value: _yearlyMonth,
                                                  height: _fieldHeight,
                                                  items: _monthsOfYear,
                                                  menuMaxHeight: 248,
                                                  menuWidth: 112,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  iconSize: 14,
                                                  textStyle: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppTheme.textPrimary,
                                                  ),
                                                  onChanged: (value) {
                                                    if (value == null) return;
                                                    setState(() {
                                                      _yearlyMonth = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              SizedBox(
                                                width: 46,
                                                child: CustomTextField(
                                                  controller:
                                                      _yearlyDayOfMonthController,
                                                  height: _fieldHeight,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  onChanged: (_) => setState(
                                                    () {},
                                                  ),
                                                ),
                                              ),
                                            ] else ...[
                                              SizedBox(
                                                width: 56,
                                                child: FormDropdown<String>(
                                                  value: _yearlyOrdinal,
                                                  height: _fieldHeight,
                                                  items: _monthlyOrdinals,
                                                  menuMaxHeight: 220,
                                                  menuWidth: 84,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  iconSize: 14,
                                                  textStyle: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppTheme.textPrimary,
                                                  ),
                                                  onChanged: (value) {
                                                    if (value == null) return;
                                                    setState(() {
                                                      _yearlyOrdinal = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              SizedBox(
                                                width: 84,
                                                child: FormDropdown<String>(
                                                  value: _yearlyWeekday,
                                                  height: _fieldHeight,
                                                  items: _weekdays,
                                                  menuMaxHeight: 248,
                                                  menuWidth: 122,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  iconSize: 14,
                                                  textStyle: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppTheme.textPrimary,
                                                  ),
                                                  onChanged: (value) {
                                                    if (value == null) return;
                                                    setState(() {
                                                      _yearlyWeekday = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'of',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              SizedBox(
                                                width: 92,
                                                child: FormDropdown<String>(
                                                  value: _yearlyMonth,
                                                  height: _fieldHeight,
                                                  items: _monthsOfYear,
                                                  menuMaxHeight: 248,
                                                  menuWidth: 112,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  iconSize: 14,
                                                  textStyle: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppTheme.textPrimary,
                                                  ),
                                                  onChanged: (value) {
                                                    if (value == null) return;
                                                    setState(() {
                                                      _yearlyMonth = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                    // Schedule Starts On Row
                                    ZerpaiFormRow(
                                      label: 'Schedule Starts On',
                                      required: true,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: KeyedSubtree(
                                              key: _startDateKey,
                                              child: CompositedTransformTarget(
                                                link: _startDateLink,
                                                child: CustomTextField(
                                                  controller:
                                                      _startDateController,
                                                  readOnly: true,
                                                  onTap: () async {
                                                    final picked =
                                                        await ZerpaiDatePicker.show(
                                                          context,
                                                          initialDate:
                                                              _startDate,
                                                          firstDate: DateTime(
                                                            2020,
                                                          ),
                                                          lastDate: DateTime(
                                                            2030,
                                                          ),
                                                          targetKey:
                                                              _startDateKey,
                                                        );
                                                    if (picked != null) {
                                                      setState(() {
                                                        _startDate = picked;
                                                        _updateStartDateText();
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 26),
                                        ],
                                      ),
                                    ),

                                    // Generate Count At Row
                                    ZerpaiFormRow(
                                      label: 'Generate Count At',
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: FormDropdown<String>(
                                              value: _generateTime,
                                              height: _fieldHeight,
                                              placeholder: 'Select time',
                                              items: _times,
                                              allowClear: _generateTime != null,
                                              onChanged: (v) {
                                                setState(
                                                  () => _generateTime = v,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 26),
                                        ],
                                      ),
                                    ),

                                    // Schedule Expires After Row
                                    ZerpaiFormRow(
                                      label: 'Schedule Expires After',
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: FormDropdown<String>(
                                              value: _expiresAfter,
                                              height: _fieldHeight,
                                              items: _expiryOptions,
                                              onChanged: (v) {
                                                if (v != null) {
                                                  setState(() {
                                                    _expiresAfter = v;
                                                    if (v != 'Date') {
                                                      _hideExpiryDatePopup();
                                                      _expiryDate = null;
                                                      _updateExpiryDateText();
                                                    }
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          if (_expiresAfter == 'Date') ...[
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 149.67,
                                              child: CompositedTransformTarget(
                                                link: _expiryDateLink,
                                                child: CustomTextField(
                                                  controller:
                                                      _expiryDateController,
                                                  hintText: 'dd-MM-yyyy',
                                                  height: 34,
                                                  readOnly: true,
                                                  onTap: _showExpiryDatePopup,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(width: 26),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    // Date* Row
                                    ZerpaiFormRow(
                                      label: 'Date',
                                      required: true,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ...List.generate(_customDates.length, (
                                            index,
                                          ) {
                                            final key = _customDateKeys[index];
                                            final link =
                                                _customDateLinks[index];
                                            final dateValue =
                                                _customDates[index];
                                            final controller =
                                                _customDateControllers[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: KeyedSubtree(
                                                      key: key,
                                                      child: CompositedTransformTarget(
                                                        link: link,
                                                        child: CustomTextField(
                                                          controller:
                                                              controller,
                                                          hintText:
                                                              'dd-MM-yyyy',
                                                          readOnly: true,
                                                          onTap: () async {
                                                            final picked =
                                                                await ZerpaiDatePicker.show(
                                                                  context,
                                                                  initialDate:
                                                                      dateValue ??
                                                                      DateTime.now(),
                                                                  firstDate:
                                                                      DateTime(
                                                                        2020,
                                                                      ),
                                                                  lastDate:
                                                                      DateTime(
                                                                        2030,
                                                                      ),
                                                                  targetKey:
                                                                      key,
                                                                );
                                                            if (picked !=
                                                                null) {
                                                              setState(() {
                                                                _customDates[index] =
                                                                    picked;
                                                                _syncCustomDateController(
                                                                  index,
                                                                );
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(
                                                      LucideIcons.xCircle,
                                                      color: AppTheme.errorRed,
                                                      size: 16,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () {
                                                      setState(() {
                                                        _removeCustomDateField(
                                                          index,
                                                        );
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _addCustomDateField();
                                                  });
                                                },
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      LucideIcons.plusCircle,
                                                      size: 14,
                                                      color: AppTheme.infoBlue,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Add New Date',
                                                      style: TextStyle(
                                                        color:
                                                            AppTheme.infoBlue,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const ZTooltip(
                                                direction:
                                                    ZTooltipDirection.bottom,
                                                message:
                                                    'You can have up to three stock count dates at a time. I.e., Once a stock count has been generated you can add a new date.',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Execution Time Row
                                    ZerpaiFormRow(
                                      label: 'Execution Time',
                                      required: true,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: FormDropdown<String>(
                                              value: _generateTime,
                                              height: _fieldHeight,
                                              placeholder: 'Select time',
                                              items: _times,
                                              allowClear: _generateTime != null,
                                              onChanged: (v) {
                                                setState(
                                                  () => _generateTime = v,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 26),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Remind Before Row
                                  ZerpaiFormRow(
                                    label: 'Remind Before',
                                    tooltipMessage:
                                        'An email and in-app notifications will be sent to the assignee '
                                        "about the stock count 'n' days before the stock count is generated.",
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CustomTextField(
                                            controller: _remindBeforeController,
                                            suffixWidget: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(
                                                    color: AppTheme.borderColor,
                                                  ),
                                                ),
                                              ),
                                              child: const Text(
                                                'Days',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const ZTooltip(
                                          direction: ZTooltipDirection.bottom,
                                          message:
                                              'An email and in-app notifications will be sent to the assignee '
                                              "about the stock count 'n' days before the stock count is generated.",
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Footer Actions Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                if (_currentStep == 0) ...[
                  ZButton.primary(
                    label: 'Next',
                    onPressed: () {
                      if (_isPrimaryCountFieldEmpty) {
                        setState(() {
                          _showNameWarning = true;
                          _showAssignWarning = false;
                        });
                      } else if (_selectedUser == null ||
                          _selectedUser!.trim().isEmpty) {
                        setState(() {
                          _showNameWarning = false;
                          _showAssignWarning = true;
                        });
                      } else {
                        setState(() {
                          _showNameWarning = false;
                          _showAssignWarning = false;
                          _currentStep = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _onCancel(orgId),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F4F4),
                      foregroundColor: const Color(0xFF4B5563),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F4F4),
                      foregroundColor: const Color(0xFF4B5563),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(LucideIcons.chevronLeft, size: 16),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _saveStockCount(orgId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22A95E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _onCancel(orgId),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F4F4),
                      foregroundColor: const Color(0xFF4B5563),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemsStep() {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showItemsWarning) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    top: 24,
                    bottom: 16,
                    left: 24,
                    right: 24,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEEDEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '• Please select an item',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showItemsWarning = false;
                          });
                        },
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 0,
                  top: 16,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _importItems
                                    ? 'Import Items'
                                    : 'Total Added Items ($_addedItemsCount)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _importItems
                                    ? 'Upload a file to import items into the stock count.'
                                    : 'Select the items you want to add to your count card, to start stock counting.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              if (_importItems) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Item Name is mandatory. If duplicate item names are allowed in settings, SKU is mandatory.*',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Text(
                              'Import Items',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.scale(
                              scale: 0.6,
                              child: Switch(
                                value: _importItems,
                                onChanged: (v) {
                                  setState(() {
                                    _importItems = v;
                                  });
                                },
                                activeThumbColor: const Color(0xFF2563EB),
                                activeTrackColor: const Color(0xFFBFDBFE),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_importItems)
                      _buildImportContainer()
                    else if (_addedItemsCount > 0)
                      _buildAddedItemsTable()
                    else
                      _buildSelectItemsContainer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedItemsTable() {
    final query = _addedItemsSearchController.text.trim().toLowerCase();
    final visibleItems = _selectedItems.where((item) {
      if (query.isEmpty) return true;
      final name = (item['name'] ?? '').toLowerCase();
      final sku = (item['sku'] ?? '').toLowerCase();
      return name.contains(query) || sku.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        left: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                      ),
                    ),
                    height: 38,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _showAddedItemsSearch
                                ? Center(
                                    child: SizedBox(
                                      height: 32,
                                      child: TextField(
                                        controller: _addedItemsSearchController,
                                        autofocus: true,
                                        onChanged: (_) => setState(() {}),
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Search',
                                          hintStyle: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            size: 16,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _showAddedItemsSearch = false;
                                                _addedItemsSearchController
                                                    .clear();
                                              });
                                            },
                                            child: const Icon(
                                              LucideIcons.x,
                                              size: 14,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 0,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6),
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      const Text(
                                        'ITEM NAME',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showAddedItemsSearch = true;
                                          });
                                        },
                                        child: Icon(
                                          Icons.search,
                                          size: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                        const Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'SKU',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                        const Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'RATE',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32), // Spacer matching red x button area
              ],
            ),

            // Data Rows
            ...List.generate(visibleItems.length, (visibleIndex) {
              final item = visibleItems[visibleIndex];
              final index = _selectedItems.indexOf(item);
              bool isHovered = false;
              return StatefulBuilder(
                builder: (context, setStateRow) {
                  return MouseRegion(
                    onEnter: (_) => setStateRow(() => isHovered = true),
                    onExit: (_) => setStateRow(() => isHovered = false),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                                right: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                                bottom: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                            ),
                            height: 40,
                            child: Container(
                              color: isHovered
                                  ? const Color(0xFFF9FAFB)
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1F2937),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item['sku'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1F2937),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item['rate'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1F2937),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          alignment: Alignment.centerRight,
                          child: isHovered
                              ? InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedItems.removeAt(index);
                                      _addedItemsCount = _selectedItems.length;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFEF4444),
                                        width: 1.5,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.x,
                                        size: 10,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _showSelectItemsDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Add Items',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectItemsContainer() {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: const Color(0xFF9CA3AF),
        strokeWidth: 2.0,
        dashWidth: 7,
        dashSpace: 3,
      ),
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            LucideIcons.shoppingBag,
                            size: 34,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select items to be added in the stock count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showSelectItemsDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Select Items',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'tsv', 'xls', 'xlsx'],
    );
    if (result != null && result.files.single.name.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.single;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Widget _buildImportContainer() {
    final bool hasFile = _selectedFileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPaint(
          painter: _DottedBorderPainter(
            color: const Color(0xFF9CA3AF),
            strokeWidth: 2.0,
            dashWidth: 7,
            dashSpace: 3,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hasFile) ...[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.upload,
                          size: 24,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Drag and drop file to import',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22A95E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Choose File',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else ...[
                    // File selected layout
                    const Icon(
                      LucideIcons.file,
                      size: 48,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFileName!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedFileName = null;
                          _selectedFile = null;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            LucideIcons.trash2,
                            size: 14,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22A95E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Replace File',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'You can import up to 1000 items.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Maximum File Size: 10 MB  •  File Format: CSV or TSV or XLS',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
            children: [
              TextSpan(text: 'Download a '),
              TextSpan(
                text: 'sample file',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text:
                    ' and compare it to your import file to ensure you have the file perfect for the import.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSelectItemsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final selectedIndices = <int>{};
        bool showFilters = false;
        bool showSelectedItemsOnly = false;
        String appliedAvailability = 'All Items';
        String draftAvailability = 'All Items';
        final appliedCategoryIds = <String>{};
        final draftCategoryIds = <String>{};
        final appliedManufacturers = <String>{};
        final draftManufacturers = <String>{};
        final appliedBrands = <String>{};
        final draftBrands = <String>{};
        final selectedWarehouseId = _selectedWarehouseId;
        return Consumer(
          builder: (context, ref, child) {
            final productsAsync = ref.watch(
              stockCountProductsProvider(selectedWarehouseId),
            );
            return productsAsync.when(
              loading: () => const Dialog(
                backgroundColor: Colors.white,
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ),
              error: (err, stack) => Dialog(
                backgroundColor: Colors.white,
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
              data: (dbProducts) {
                final items = dbProducts.map((item) {
                  return {
                    'product_id': item.id ?? '',
                    'name': item.productName,
                    'sku': item.sku ?? '',
                    'category_id': item.categoryId ?? '',
                    'category_name': item.categoryName ?? '',
                    'manufacturer_name': item.manufacturerName ?? '',
                    'brand_name': item.brandName ?? '',
                    'rate': '₹${(item.sellingPrice ?? 0.0).toStringAsFixed(2)}',
                    'stock': (item.stockOnHand ?? 0.0).toStringAsFixed(2),
                    'unit': item.unitName ?? '',
                  };
                }).toList();

                if (selectedIndices.isEmpty && _selectedItems.isNotEmpty) {
                  for (var i = 0; i < items.length; i++) {
                    if (_selectedItems.any((sel) => sel['name'] == items[i]['name'])) {
                      selectedIndices.add(i);
                    }
                  }
                }

                return StatefulBuilder(
                  builder: (context, setStateDialog) {
                    final visibleEntries = items
                        .asMap()
                        .entries
                        .where((entry) {
                          if (showSelectedItemsOnly &&
                              !selectedIndices.contains(entry.key)) {
                            return false;
                          }

                          final stockQty =
                              double.tryParse(
                                (entry.value['stock'] ?? '0').toString().trim(),
                              ) ??
                              0.0;
                          switch (appliedAvailability) {
                            case 'In Stock':
                              if (stockQty <= 0) {
                                return false;
                              }
                              break;
                            case 'Negative Stock':
                              if (stockQty >= 0) {
                                return false;
                              }
                              break;
                            case 'Out of Stock':
                              if (stockQty != 0) {
                                return false;
                              }
                              break;
                            case 'All Items':
                            default:
                              break;
                          }

                          final allCategoryIds =
                              _categoryDescendantIds.keys.toSet();
                          final allCategoriesSelected =
                              allCategoryIds.isNotEmpty &&
                              appliedCategoryIds.containsAll(allCategoryIds);

                          if (appliedCategoryIds.isNotEmpty &&
                              !allCategoriesSelected) {
                            final itemCategoryId =
                                (entry.value['category_id'] ?? '')
                                    .toString()
                                    .trim();
                            final allowedCategoryIds = <String>{};
                            for (final categoryId in appliedCategoryIds) {
                              allowedCategoryIds.addAll(
                                _categoryDescendantIds[categoryId] ??
                                    {categoryId},
                              );
                            }
                            if (!allowedCategoryIds.contains(itemCategoryId)) {
                              return false;
                            }
                          }

                          final allManufacturersSelected =
                              _manufacturers.isNotEmpty &&
                              appliedManufacturers.length ==
                                  _manufacturers.length;
                          if (appliedManufacturers.isNotEmpty &&
                              !allManufacturersSelected) {
                            final itemManufacturer =
                                (entry.value['manufacturer_name'] ?? '')
                                    .toString()
                                    .trim();
                            if (!appliedManufacturers.contains(
                              itemManufacturer,
                            )) {
                              return false;
                            }
                          }

                          final allBrandsSelected =
                              _brands.isNotEmpty &&
                              appliedBrands.length == _brands.length;
                          if (appliedBrands.isNotEmpty &&
                              !allBrandsSelected) {
                            final itemBrand =
                                (entry.value['brand_name'] ?? '')
                                    .toString()
                                    .trim();
                            if (!appliedBrands.contains(itemBrand)) {
                              return false;
                            }
                          }

                          return true;
                        })
                        .toList();
                    return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.only(top: 0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1000,
                  maxHeight: MediaQuery.of(context).size.height - 24,
                ),
                child: SizedBox(
                  width: 1000,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Select Items for Stock Counting',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.x,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Controls Row
                        Row(
                          children: [
                            SizedBox(
                              width: 440,
                              height: 44,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: TextField(
                                  textAlignVertical:
                                      TextAlignVertical.center,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Enter an item name or SKU',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setStateDialog(() {
                                  showFilters = !showFilters;
                                });
                              },
                              child: Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: const Color(0xFFEFF6FF),
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.filter,
                                    size: 16,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.home,
                                  size: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedWarehouseDisplayLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (showFilters) ...[
                          const SizedBox(height: 8),
                          // Caret pointer pointing up to the filter icon
                          Row(
                            children: [
                              const SizedBox(
                                width: 460,
                              ), // Approx offset to align below filter icon
                              CustomPaint(
                                size: const Size(12, 6),
                                painter: _CaretPainter(),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF2F6FC),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const Text(
                                    'Availability:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    height: 32,
                                    width: 150,
                                    child: FormDropdown<String>(
                                      value: draftAvailability,
                                      height: _fieldHeight,
                                      items: const [
                                        'All Items',
                                        'In Stock',
                                        'Negative Stock',
                                        'Out of Stock',
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setStateDialog(() {
                                            draftAvailability = v;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 220,
                                    child: CategoryPicker(
                                      nodes: _categoryNodes,
                                      value: null,
                                      hintText: 'Category',
                                      multiSelect: true,
                                      selectedValues:
                                          draftCategoryIds.toList(),
                                      fieldHeight: 32,
                                      selectedBackgroundColor:
                                          const Color(0xFFE5E7EB),
                                      hoverBackgroundColor:
                                          const Color(0xFF2563EB),
                                      rowBorderRadius: 6,
                                      onChanged: (_) {},
                                      onSelectedValuesChanged: (values) {
                                        setStateDialog(() {
                                          draftCategoryIds
                                            ..clear()
                                            ..addAll(values);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildFilterDropdownWidget(
                                    hint: 'Manufacturer',
                                    items: _manufacturers,
                                    selectedValues: draftManufacturers,
                                    onSelectedValuesChanged: (values) {
                                      setStateDialog(() {
                                        draftManufacturers
                                          ..clear()
                                          ..addAll(values);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildFilterDropdownWidget(
                                    hint: 'Brand',
                                    items: _brands,
                                    selectedValues: draftBrands,
                                    onSelectedValuesChanged: (values) {
                                      setStateDialog(() {
                                        draftBrands
                                          ..clear()
                                          ..addAll(values);
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 32,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setStateDialog(() {
                                          appliedAvailability =
                                              draftAvailability;
                                          appliedCategoryIds
                                            ..clear()
                                            ..addAll(draftCategoryIds);
                                          appliedManufacturers
                                            ..clear()
                                            ..addAll(draftManufacturers);
                                          appliedBrands
                                            ..clear()
                                            ..addAll(draftBrands);
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF2563EB,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFBFDBFE),
                                        ),
                                        backgroundColor: const Color(
                                          0xFFEFF6FF,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Apply',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ZTooltip(
                                    message: 'Reset filter',
                                    direction: ZTooltipDirection.bottom,
                                    child: IconButton(
                                      icon: const Icon(
                                        LucideIcons.rotateCcw,
                                        size: 16,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      onPressed: () {
                                        setStateDialog(() {
                                          draftAvailability = 'All Items';
                                          draftCategoryIds.clear();
                                          draftManufacturers.clear();
                                          draftBrands.clear();
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 16,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () {
                                      setStateDialog(() {
                                        showFilters = false;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Tabs
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setStateDialog(() {
                                  showSelectedItemsOnly = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: showSelectedItemsOnly
                                          ? Colors.transparent
                                          : const Color(0xFF2563EB),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'All Items(${items.length})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: showSelectedItemsOnly
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    color: showSelectedItemsOnly
                                        ? const Color(0xFF4B5563)
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                setStateDialog(() {
                                  showSelectedItemsOnly = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: showSelectedItemsOnly
                                          ? const Color(0xFF2563EB)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Selected Items(${selectedIndices.length})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: showSelectedItemsOnly
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: showSelectedItemsOnly
                                        ? const Color(0xFF111827)
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (showFilters)
                              Row(
                                children: [
                                  const Text(
                                    'Group By: ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    height: 32,
                                    width: 100,
                                    child: FormDropdown<String>(
                                      value: 'None',
                                      height: _fieldHeight,
                                      items: const [
                                        'None',
                                        'Category',
                                        'Brand',
                                      ],
                                      border: Border.all(
                                        color: Colors.transparent,
                                        style: BorderStyle.none,
                                      ),
                                      fillColor: Colors.transparent,
                                      hideBorderDefault: true,
                                      onChanged: (v) {},
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),

                        // Table
                        Expanded(
                          child: ClipRect(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Header Row
                                  Container(
                                    color: const Color(0xFFF9FAFB),
                                    height: 38,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 64,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 24,
                                            ),
                                            child: _buildUniformDialogCheckbox(
                                              value:
                                                  visibleEntries.isNotEmpty &&
                                                  visibleEntries.every(
                                                    (entry) => selectedIndices
                                                        .contains(entry.key),
                                                  ),
                                              onChanged: (v) {
                                                setStateDialog(() {
                                                  final allVisibleSelected =
                                                      visibleEntries
                                                          .isNotEmpty &&
                                                      visibleEntries.every(
                                                        (entry) =>
                                                            selectedIndices
                                                                .contains(
                                                                  entry.key,
                                                                ),
                                                      );
                                                  if (allVisibleSelected) {
                                                    for (final entry
                                                        in visibleEntries) {
                                                      selectedIndices.remove(
                                                        entry.key,
                                                      );
                                                    }
                                                  } else {
                                                    for (final entry
                                                        in visibleEntries) {
                                                      selectedIndices.add(
                                                        entry.key,
                                                      );
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: _buildDlgHeaderCell(
                                            'ITEM NAME',
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _buildDlgHeaderCell('SKU'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _buildDlgHeaderCell('RATE'),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _buildDlgHeaderCell(
                                            'STOCK ON HAND',
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: _buildDlgHeaderCell(
                                            'UNIT',
                                            isRightmost: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),

                                  // Data Rows
                                  ...visibleEntries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    bool isRowHovered = false;
                                    return StatefulBuilder(
                                      builder: (context, setStateRow) {
                                        final bool showRemoveAction =
                                            showSelectedItemsOnly &&
                                            isRowHovered;
                                        return MouseRegion(
                                          onEnter: (_) => setStateRow(
                                            () => isRowHovered = true,
                                          ),
                                          onExit: (_) => setStateRow(
                                            () => isRowHovered = false,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              setStateDialog(() {
                                                if (selectedIndices.contains(
                                                  index,
                                                )) {
                                                  selectedIndices.remove(index);
                                                } else {
                                                  selectedIndices.add(index);
                                                }
                                              });
                                            },
                                            child: Container(
                                              color: isRowHovered
                                                  ? const Color(0xFFF2F6FC)
                                                  : Colors.transparent,
                                              height: 38,
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 64,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 24,
                                                          ),
                                                      child:
                                                          _buildUniformDialogCheckbox(
                                                            value:
                                                                selectedIndices
                                                                    .contains(
                                                                      index,
                                                                    ),
                                                            onChanged: (v) {
                                                              setStateDialog(() {
                                                                if (selectedIndices
                                                                    .contains(
                                                                      index,
                                                                    )) {
                                                                  selectedIndices
                                                                      .remove(
                                                                        index,
                                                                      );
                                                                } else {
                                                                  selectedIndices
                                                                      .add(
                                                                        index,
                                                                      );
                                                                }
                                                              });
                                                            },
                                                          ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 4,
                                                    child: _buildDlgCell(
                                                      item['name']!,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: _buildDlgCell(
                                                      item['sku']!,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: _buildDlgCell(
                                                            item['rate']!,
                                                          ),
                                                        ),
                                                        if (showRemoveAction)
                                                          InkWell(
                                                            onTap: () {
                                                              setStateDialog(() {
                                                                selectedIndices
                                                                    .remove(
                                                                      index,
                                                                    );
                                                              });
                                                            },
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                            child: Container(
                                                              width: 16,
                                                              height: 16,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color: const Color(
                                                                    0xFFEF4444,
                                                                  ),
                                                                  width: 1.2,
                                                                ),
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              child: const Center(
                                                                child: Icon(
                                                                  LucideIcons.x,
                                                                  size: 10,
                                                                  color: Color(
                                                                    0xFFEF4444,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        if (showRemoveAction)
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: _buildDlgCell(
                                                      item['stock']!,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: _buildDlgCell(
                                                      item['unit']!,
                                                      isRightmost: true,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer Buttons
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedItems = selectedIndices
                                      .map((idx) => items[idx])
                                      .toList();
                                  _addedItemsCount = _selectedItems.length;
                                  if (_selectedItems.isNotEmpty) {
                                    _showItemsWarning = false;
                                  }
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22A95E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Add Items',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF4B5563),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDlgHeaderCell(String label, {bool isRightmost = false}) {
    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 12,
        left: 8,
        right: isRightmost ? 24 : 8,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildDlgCell(String text, {bool isRightmost = false}) {
    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 12,
        left: 8,
        right: isRightmost ? 24 : 8,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
      ),
    );
  }

  Widget _buildFilterDropdownWidget({
    required String hint,
    required List<String> items,
    required Set<String> selectedValues,
    required ValueChanged<List<String>> onSelectedValuesChanged,
  }) {
    final double fieldWidth = switch (hint) {
      'Manufacturer' => 150,
      'Category' => 140,
      'Brand' => 135,
      _ => 120,
    };
    final actualItems =
        items
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final displayItems = <String>['All', ...actualItems];
    final allSelected =
        actualItems.isNotEmpty && selectedValues.length == actualItems.length;
    final dropdownSelectedValues = <String>[
      if (allSelected) 'All',
      ...selectedValues,
    ];

    return CustomPaint(
      painter: _DottedBorderPainter(color: const Color(0xFFD1D5DB)),
      child: SizedBox(
        height: 32,
        width: fieldWidth,
        child: FormDropdown<String>(
          value: null,
          height: _fieldHeight,
          items: displayItems,
          hint: hint,
          multiSelect: true,
          selectedValues: dropdownSelectedValues,
          allowClear: selectedValues.isNotEmpty,
          menuWidth: 180,
          border: Border.all(
            color: Colors.transparent,
            style: BorderStyle.none,
          ),
          fillColor: Colors.white,
          hideBorderDefault: true,
          compactMultiSelectSummary: true,
          compactMultiSelectLabel: hint,
          compactMultiSelectLabelYOffset: -1,
          multiSelectAllValue: 'All',
          alwaysShowClear: true,
          showClearDivider: true,
          onChanged: (v) {},
          onSelectedValuesChanged: (values) {
            final nextActualValues =
                values
                    .where((value) => value.trim().isNotEmpty && value != 'All')
                    .toSet()
                    .toList()
                  ..sort();

            if (values.contains('All')) {
              if (allSelected && nextActualValues.length < actualItems.length) {
                onSelectedValuesChanged(nextActualValues);
                return;
              }
              onSelectedValuesChanged(actualItems);
              return;
            }

            if (allSelected && nextActualValues.length == actualItems.length) {
              onSelectedValuesChanged(const <String>[]);
              return;
            }

            onSelectedValuesChanged(nextActualValues);
          },
          itemBuilder: (item, isSelected, isHovered) {
            final checked = item == 'All'
                ? allSelected
                : selectedValues.contains(item);
            final rowBackground = isHovered
                ? const Color(0xFF2563EB)
                : checked
                ? const Color(0xFFE5E7EB)
                : Colors.transparent;
            final textColor = isHovered
                ? Colors.white
                : const Color(0xFF1F2937);
            final checkboxBorderColor = isHovered
                ? Colors.white70
                : checked
                ? const Color(0xFF2563EB)
                : const Color(0xFFD1D5DB);
            final checkboxFillColor = isHovered
                ? Colors.transparent
                : checked
                ? const Color(0xFF2563EB)
                : Colors.white;
            return Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: rowBackground,
                borderRadius: BorderRadius.circular(6),
                border: item == 'All'
                    ? const Border(
                        bottom: BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: checkboxFillColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: checkboxBorderColor),
                    ),
                    child: checked
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: item == 'All'
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const _DottedBorderPainter({
    required this.color,
    this.dashWidth = 7,
    this.dashSpace = 3,
    this.strokeWidth = 2.0,
  }) : borderRadius = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final r = borderRadius;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashSpace;
        if (draw) {
          final extracted = metric.extractPath(
            distance,
            (distance + len).clamp(0, metric.length),
          );
          canvas.drawPath(extracted, paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.dashWidth != dashWidth ||
      old.dashSpace != dashSpace ||
      old.strokeWidth != strokeWidth;
}

class _CaretPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF2F6FC)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

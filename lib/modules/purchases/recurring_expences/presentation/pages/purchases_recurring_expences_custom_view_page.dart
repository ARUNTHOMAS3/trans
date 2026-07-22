import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_search_field.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class CriterionModel {
  String? field;
  String? comparator;
  final TextEditingController valueCtrl = TextEditingController();

  CriterionModel({this.field, this.comparator});

  void dispose() {
    valueCtrl.dispose();
  }
}

class PurchasesRecurringExpensesCustomViewPage extends StatefulWidget {
  const PurchasesRecurringExpensesCustomViewPage({super.key});

  @override
  State<PurchasesRecurringExpensesCustomViewPage> createState() =>
      _PurchasesRecurringExpensesCustomViewPageState();
}

class _PurchasesRecurringExpensesCustomViewPageState
    extends State<PurchasesRecurringExpensesCustomViewPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _isFavorite = false;

  final List<CriterionModel> _criteria = [];

  // Columns lists
  final List<String> _availableColumns = [
    'Vendor Name',
    'Last Expense Date',
    'Customer Name',
  ];

  final List<String> _selectedColumns = [
    'Profile Name',
    'Expense Account',
    'Frequency',
    'Next Expense Date',
    'Status',
    'Amount',
  ];

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedVisibility = 'me'; // 'me', 'selected', 'everyone'

  @override
  void initState() {
    super.initState();
    AppLogger.info(
      'Navigated to PurchasesRecurringExpensesCustomViewPage',
      module: 'purchases_recurring_expenses',
    );
    // Start with 1 default criterion row as shown in Screenshot 1
    _criteria.add(CriterionModel());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    for (final criterion in _criteria) {
      criterion.dispose();
    }
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      AppLogger.info(
        'Saving custom view settings',
        data: {
          'name': _nameCtrl.text,
          'favorite': _isFavorite,
          'criteriaCount': _criteria.length,
          'selectedColumns': _selectedColumns,
          'visibility': _selectedVisibility,
        },
        module: 'purchases_recurring_expenses',
      );
      ZerpaiToast.success(context, 'Custom view saved successfully.');
      context.pop();
    }
  }

  void _onCancel() {
    AppLogger.info(
      'Cancelled custom view settings editing',
      module: 'purchases_recurring_expenses',
    );
    context.pop();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildVisibilityOption({
    required String id,
    required String label,
    required IconData icon,
    required bool active,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVisibility = id;
        });
        AppLogger.info(
          'Changed custom view visibility preference',
          data: {'visibility': id},
          module: 'purchases_recurring_expenses',
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border.all(
              color: active ? AppTheme.infoBlue : AppTheme.borderLight,
              width: active ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.radio_button_checked : Icons.radio_button_off,
                color: active ? AppTheme.infoBlue : AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? AppTheme.infoBlue : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                color: active ? AppTheme.infoBlue : AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAvailable = _availableColumns.where((col) {
      return col.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return ZerpaiLayout(
      pageTitle: '', // Custom title widget used
      titleWidget: Text(
        'New Custom View',
        style: AppTextStyles.title.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.close,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          onPressed: _onCancel,
          tooltip: 'Close',
        ),
      ],
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            ZButton.primary(label: 'Save', onPressed: _onSave),
            const SizedBox(width: 12),
            ZButton.secondary(label: 'Cancel', onPressed: _onCancel),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: AppTheme.bgLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 24,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 486,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name*',
                            style: AppTextStyles.labelRequired.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          CustomTextField(
                            controller: _nameCtrl,
                            hintText: '',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          AppLogger.info(
                            'Toggled custom view favorite status',
                            data: {'favorite': _isFavorite},
                            module: 'purchases_recurring_expenses',
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFavorite ? Icons.star : Icons.star_border,
                                color: _isFavorite
                                    ? AppTheme.warningOrange
                                    : AppTheme.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Mark as Favorite',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
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
              const SizedBox(height: 16),

              // Row 2: Criteria
              _buildSectionHeader('Define the criteria ( if any )'),
              if (_criteria.isEmpty)
                const SizedBox(height: 8)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _criteria.length,
                  itemBuilder: (context, index) {
                    final item = _criteria[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          // Index Badge Box
                          Container(
                            width: 36,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.bgLight,
                              border: Border.all(color: AppTheme.borderLight),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: AppTextStyles.body.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dropdown 1: Field Selection
                          SizedBox(
                            width: 180,
                            height: 32,
                            child: FormDropdown<String>(
                              height: 32,
                              value: item.field,
                              hint: 'Select a field',
                              items: const [
                                'Profile Name',
                                'Expense Account',
                                'Vendor Name',
                                'Frequency',
                                'Last Expense Date',
                                'Next Expense Date',
                                'Status',
                                'Amount',
                              ],
                              onChanged: (val) {
                                setState(() {
                                  item.field = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dropdown 2: Comparator Selection
                          SizedBox(
                            width: 180,
                            height: 32,
                            child: FormDropdown<String>(
                              height: 32,
                              value: item.comparator,
                              hint: 'Select a comparator',
                              items: const [
                                'is',
                                'isn\'t',
                                'contains',
                                'starts with',
                                'ends with',
                                'is empty',
                                'is not empty',
                              ],
                              onChanged: (val) {
                                setState(() {
                                  item.comparator = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Input Value Box
                          SizedBox(
                            width: 260,
                            height: 32,
                            child: CustomTextField(
                              controller: item.valueCtrl,
                              hintText: '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Add Row Button
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _criteria.insert(index + 1, CriterionModel());
                                AppLogger.info(
                                  'Inserted custom view criterion row',
                                  data: {'index': index + 1},
                                  module: 'purchases_recurring_expenses',
                                );
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          // Delete Row Button
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                final removed = _criteria.removeAt(index);
                                removed.dispose();
                                AppLogger.info(
                                  'Removed custom view criterion row',
                                  data: {'index': index},
                                  module: 'purchases_recurring_expenses',
                                );
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              // Add Criterion Link Button
              InkWell(
                onTap: () {
                  setState(() {
                    _criteria.add(CriterionModel());
                    AppLogger.info(
                      'Added custom view criterion row',
                      data: {'index': _criteria.length - 1},
                      module: 'purchases_recurring_expenses',
                    );
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle,
                        color: AppTheme.primaryBlueDark,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Criterion',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Row 3: Columns Preference
              _buildSectionHeader('Columns Preference:'),
              SizedBox(
                width: 984,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column Box: Available Columns
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              color: AppTheme.bgLight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                'AVAILABLE COLUMNS',
                                style: AppTextStyles.helper.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: ZSearchField(
                                controller: _searchCtrl,
                                hintText: 'Search',
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            Container(
                              height: 200,
                              color: AppTheme.backgroundColor,
                              child: filteredAvailable.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No columns found',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: filteredAvailable.length,
                                      itemBuilder: (context, index) {
                                        final colName =
                                            filteredAvailable[index];
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              _availableColumns.remove(colName);
                                              _selectedColumns.add(colName);
                                              AppLogger.info(
                                                'Moved column from available to selected',
                                                data: {'column': colName},
                                                module:
                                                    'purchases_recurring_expenses',
                                              );
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  LucideIcons.gripVertical,
                                                  color: AppTheme.textMuted,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  colName,
                                                  style: AppTextStyles.body
                                                      .copyWith(
                                                        color: AppTheme
                                                            .textPrimary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      // Vertical Separator
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppTheme.borderLight,
                      ),
                      // Right Column Box: Selected Columns
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              color: AppTheme.bgLight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: AppTheme.successDark,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SELECTED COLUMNS',
                                    style: AppTextStyles.helper.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            Container(
                              height: 260, // Sized to match available height
                              color: AppTheme.backgroundColor,
                              child: _selectedColumns.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Select columns from available list',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    )
                                  : Theme(
                                      data: Theme.of(context).copyWith(
                                        canvasColor: AppTheme.backgroundColor,
                                        shadowColor: AppTheme.textPrimary
                                            .withValues(alpha: 0.05),
                                      ),
                                      child: ReorderableListView.builder(
                                        buildDefaultDragHandles: false,
                                        itemCount: _selectedColumns.length,
                                        onReorder: (oldIndex, newIndex) {
                                          setState(() {
                                            if (newIndex > oldIndex) {
                                              newIndex -= 1;
                                            }
                                            final item = _selectedColumns
                                                .removeAt(oldIndex);
                                            _selectedColumns.insert(
                                              newIndex,
                                              item,
                                            );
                                            AppLogger.info(
                                              'Reordered custom view selected columns',
                                              data: {
                                                'item': item,
                                                'oldIndex': oldIndex,
                                                'newIndex': newIndex,
                                              },
                                              module:
                                                  'purchases_recurring_expenses',
                                            );
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          final colName =
                                              _selectedColumns[index];
                                          return ReorderableDragStartListener(
                                            key: ValueKey(colName),
                                            index: index,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedColumns.removeAt(
                                                    index,
                                                  );
                                                  _availableColumns.add(
                                                    colName,
                                                  );
                                                  AppLogger.info(
                                                    'Moved column from selected to available',
                                                    data: {'column': colName},
                                                    module:
                                                        'purchases_recurring_expenses',
                                                  );
                                                });
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    const MouseRegion(
                                                      cursor: SystemMouseCursors
                                                          .grab,
                                                      child: Icon(
                                                        LucideIcons
                                                            .gripVertical,
                                                        color:
                                                            AppTheme.textMuted,
                                                        size: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      colName,
                                                      style: AppTextStyles.body
                                                          .copyWith(
                                                            color: AppTheme
                                                                .textPrimary,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '*',
                                                      style: AppTextStyles.body
                                                          .copyWith(
                                                            color: AppTheme
                                                                .errorRed,
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Row 4: Visibility Preference
              _buildSectionHeader('Visibility Preference'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share With',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildVisibilityOption(
                          id: 'me',
                          label: 'Only Me',
                          icon: Icons.lock_outline,
                          active: _selectedVisibility == 'me',
                        ),
                        _buildVisibilityOption(
                          id: 'selected',
                          label: 'Only Selected Users & Roles',
                          icon: Icons.person_outline,
                          active: _selectedVisibility == 'selected',
                        ),
                        _buildVisibilityOption(
                          id: 'everyone',
                          label: 'Everyone',
                          icon: Icons.public,
                          active: _selectedVisibility == 'everyone',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// PATH: lib/modules/printing/presentation/print_templates_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import '../../data/models/print_template.dart';
import '../../data/repositories/print_template_repository.dart';
import '../widgets/template_editor.dart';

class PrintTemplatesPage extends ConsumerStatefulWidget {
  const PrintTemplatesPage({super.key});

  @override
  ConsumerState<PrintTemplatesPage> createState() => _PrintTemplatesPageState();
}

class _PrintTemplatesPageState extends ConsumerState<PrintTemplatesPage> {
  List<PrintTemplate> _templates = [];
  List<PrintTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedType = 'all';
  late final PrintTemplateRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = PrintTemplateRepository(apiClient: ApiClient());
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final templates = await _repository.getTemplates();

      setState(() {
        _templates = templates;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ZerpaiToast.error(context, 'Failed to load templates: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTemplates = _templates.where((template) {
        // Type filter
        bool typeMatch =
            _selectedType == 'all' || template.type == _selectedType;

        // Search filter
        bool searchMatch =
            _searchQuery.isEmpty ||
            template.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            template.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ==
                true;

        return typeMatch && searchMatch;
      }).toList();
    });
  }

  void _showTemplateEditor([PrintTemplate? template]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (dialogContext, animation, secondaryAnimation) =>
          TemplateEditor(
            template: template,
            onSave: (savedTemplate) {
              setState(() {
                if (template == null) {
                  _templates.add(savedTemplate);
                } else {
                  final index = _templates.indexWhere(
                    (t) => t.id == savedTemplate.id,
                  );
                  if (index != -1) {
                    _templates[index] = savedTemplate;
                  }
                }
                _applyFilters();
              });
              if (mounted) {
                ZerpaiToast.saved(context, 'Template');
              }
            },
          ),
    );
  }

  void _duplicateTemplate(PrintTemplate template) {
    final duplicatedTemplate = template.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${template.name} (Copy)',
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _templates.add(duplicatedTemplate);
      _applyFilters();
    });

    ZerpaiToast.success(context, 'Template duplicated successfully');
  }

  Future<void> _deleteTemplate(PrintTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _templates.removeWhere((t) => t.id == template.id);
        _applyFilters();
      });
      if (!mounted) return;
      ZerpaiToast.deleted(context, 'Template');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final orgName = ref.watch(authUserProvider)?.orgName;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          SettingsPageHeader(
            orgName: orgName,
            searchItems: const <SettingsSearchItem>[],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsNavigationSidebar(currentPath: currentPath),
                Expanded(child: _buildTemplatesContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Text('Print Templates', style: AppTheme.pageTitle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    prefixIcon: Icon(LucideIcons.search),
                    filled: true,
                    fillColor: AppTheme.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 220,
                child: FormDropdown<String>(
                  value: _selectedType,
                  hint: 'Filter by type',
                  items: <String>['all', ...TemplateType.all],
                  displayStringForValue: _formatTemplateType,
                  onChanged: (value) {
                    if (value == null) return;
                    _selectedType = value;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 16),
              ZButton.primary(
                label: 'New Template',
                icon: LucideIcons.plus,
                onPressed: () => _showTemplateEditor(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: ZListSkeleton(itemCount: 5),
                )
              : _filteredTemplates.isEmpty
              ? _buildEmptyTemplatesState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filteredTemplates.length,
                  itemBuilder: (context, index) =>
                      _buildTemplateCard(_filteredTemplates[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyTemplatesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 56,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No templates found', style: AppTheme.sectionHeader),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _selectedType == 'all'
                ? 'Create your first print template'
                : 'No templates match your filters',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(PrintTemplate template) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getIconForType(template.type),
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (template.isDefault)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatTemplateType(template.type),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showTemplateEditor(template);
                        break;
                      case 'duplicate':
                        _duplicateTemplate(template);
                        break;
                      case 'delete':
                        _deleteTemplate(template);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: AppTheme.errorRed,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // Description
            if (template.description != null &&
                template.description!.isNotEmpty)
              Text(
                template.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

            SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${_formatDate(template.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'By: ${template.createdBy}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case TemplateType.invoice:
        return Icons.receipt_long;
      case TemplateType.receipt:
        return Icons.receipt;
      case TemplateType.purchaseOrder:
        return Icons.shopping_cart;
      case TemplateType.deliveryNote:
        return Icons.local_shipping;
      case TemplateType.quotation:
        return Icons.request_quote;
      default:
        return Icons.description;
    }
  }

  String _formatTemplateType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

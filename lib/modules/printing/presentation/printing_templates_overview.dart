// PATH: lib/modules/printing/presentation/print_templates_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import '../models/print_template.dart';
import '../repositories/print_template_repository.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Print Templates'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filters and Search
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                SizedBox(height: 16),

                // Type Filter
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Filter by Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All Types')),
                    ...TemplateType.all.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_formatTemplateType(type)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showTemplateEditor(),
                  icon: Icon(Icons.add),
                  label: Text('New Template'),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Templates List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredTemplates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No templates found',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty && _selectedType == 'all'
                              ? 'Create your first print template'
                              : 'No templates match your filters',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = _filteredTemplates[index];
                      return _buildTemplateCard(template);
                    },
                  ),
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
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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

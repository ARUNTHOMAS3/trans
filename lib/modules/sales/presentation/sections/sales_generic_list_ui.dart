part of '../sales_generic_list.dart';

extension _SalesGenericListUI on _SalesGenericListScreenState {
  Widget _buildResizeBanner() {
    return Container(
      width: double.infinity,
      color: AppTheme.infoBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.info, size: 16, color: AppTheme.primaryBlueDark),
          const SizedBox(width: 8),
          const Text(
            'You have resized the columns. Would you like to save the changes?',
            style: TextStyle(fontSize: 13, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _saveColumnPreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successDark,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 28),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _resetColumnPreferences,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textBody,
              side: const BorderSide(color: AppTheme.borderColor),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 28),
              backgroundColor: Colors.white,
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // View Switcher Trigger
          if (widget.title == 'Customers')
            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                onTap: _toggleFilterMenu,
                hoverColor: Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedFilter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          const Spacer(),
          // Advanced Search Button
          InkWell(
            onTap: _openAdvancedSearchDialog,
            child: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: AppTheme.infoBg, // Light blue background
                border: Border.all(color: AppTheme.primaryBlueDark),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                LucideIcons.search,
                size: 16,
                color: AppTheme.primaryBlueDark, // Primary blue
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right side Green Button
          Tooltip(
            message: 'New (Alt+N)',
            child: ElevatedButton(
              onPressed: () => context.go(widget.createRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen, // Zerpai Green
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.plus, size: 18),
                  const SizedBox(width: 4),
                  const Text(
                    'New',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildMoreActionsMenu(),
        ],
      ),
    );
  }

  Widget _buildMoreActionsMenu() {
    return MenuAnchor(
      builder: (context, controller, child) {
        return Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(
              LucideIcons.moreHorizontal,
              size: 18,
              color: AppTheme.textBody,
            ),
            padding: EdgeInsets.zero,
          ),
        );
      },
      menuChildren: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () => _onSort('name'),
              child: const Text('Name'),
            ),
            MenuItemButton(
              onPressed: () => _onSort('company_name'),
              child: const Text('Company Name'),
            ),
            MenuItemButton(
              onPressed: () => _onSort('email'),
              child: const Text('Email'),
            ),
            MenuItemButton(
              onPressed: () => _onSort('receivables'),
              child: const Text('Receivables (BCY)'),
            ),
            MenuItemButton(
              onPressed: () => _onSort('created_at'),
              child: const Text('Created Time'),
            ),
            MenuItemButton(
              onPressed: () => _onSort('updated_at'),
              child: const Text('Last Modified Time'),
            ),
          ],
          leadingIcon: const Icon(
            LucideIcons.arrowUpDown,
            size: 18,
            color: AppTheme.primaryBlueDark,
          ),
          child: const Text('Sort by'),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: _showImportDialog,
              child: Text('Import ${widget.title}'),
            ),
          ],
          leadingIcon: const Icon(
            LucideIcons.download,
            size: 18,
            color: AppTheme.primaryBlueDark,
          ),
          child: const Text('Import'),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: _showExportDialog,
              child: Text('Export ${widget.title}'),
            ),
            MenuItemButton(
              onPressed: () {
                // TODO: Implement Export Current View
              },
              child: const Text('Export Current View'),
            ),
          ],
          leadingIcon: const Icon(
            LucideIcons.upload,
            size: 18,
            color: AppTheme.primaryBlueDark,
          ),
          child: const Text('Export'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(
            LucideIcons.settings,
            size: 18,
            color: AppTheme.primaryBlueDark,
          ),
          onPressed: () {
            // TODO: Open Preferences
          },
          child: const Text('Preferences'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(
            LucideIcons.refreshCw,
            size: 18,
            color: AppTheme.primaryBlueDark,
          ),
          onPressed: () {
            // TODO: Refresh List
          },
          child: const Text('Refresh List'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(
            LucideIcons.history,
            size: 18,
            color: AppTheme.primaryBlueDark,
          ),
          onPressed: _resetColumnPreferences,
          child: const Text('Reset Column Width'),
        ),
      ],
    );
  }

  Widget _buildBulkActionsToolbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Selection count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueDark,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_selectedIds.length} Selected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Action buttons
          _buildActionButton('Bulk Update', LucideIcons.edit2, () {
            // TODO: Implement bulk update
          }),
          _buildActionButton('Mark as Active', LucideIcons.checkCircle, () {
            // TODO: Implement mark as active
          }),
          _buildActionButton('Mark as Inactive', LucideIcons.xCircle, () {
            // TODO: Implement mark as inactive
          }),
          _buildActionButton('Merge', LucideIcons.merge, () {
            // TODO: Implement merge
          }),
          _buildActionButton('Associate Templates', LucideIcons.fileText, () {
            // TODO: Implement associate templates
          }),

          MenuAnchor(
            builder: (context, controller, child) {
              return InkWell(
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.moreHorizontal,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(
                  LucideIcons.receipt,
                  size: 18,
                  color: AppTheme.textBody,
                ),
                onPressed: () {
                  // TODO: Implement request GST
                },
                child: const Text('Request GST Information'),
              ),
              MenuItemButton(
                leadingIcon: const Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: AppTheme.errorRed,
                ),
                onPressed: () {
                  // TODO: Implement delete
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Close button
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            color: AppTheme.textSecondary,
            onPressed: () {
              _state(() {
                _selectedIds.clear();
                _selectAll = false;
              });
            },
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textBody,
          side: const BorderSide(color: AppTheme.borderColor),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileText, size: 64, color: AppTheme.borderColor),
          const SizedBox(height: 16),
          Text(
            'No ${widget.title} found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new ${widget.title} to get started.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(widget.createRoute),
            icon: const Icon(LucideIcons.plus),
            label: Text('New ${widget.title}'),
          ),
        ],
      ),
    );
  }
}

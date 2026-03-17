part of '../items_item_detail.dart';

extension _ItemDetailMenus on _ItemDetailScreenState {
  void _toggleMoreMenu() {
    if (_moreMenuEntry != null) {
      _closeMoreMenu();
    } else {
      _openMoreMenu();
    }
  }

  void _closeMoreMenu() {
    _closeMenus();
  }

  void _openMoreMenu() {
    if (_moreMenuEntry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);

    final RenderBox buttonBox =
        _moreButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset buttonOffset = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;

    final double left = buttonOffset.dx + buttonSize.width - 260;
    final double top = buttonOffset.dy + buttonSize.height + 4;

    _moreMenuTopLeft = Offset(left, top);

    _moreMenuEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMoreMenu,
                child: const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: 260,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          return MouseRegion(
                            onEnter: (_) {
                              _isHoveringSortRow = true;
                              _openSortMenu();
                            },
                            onExit: (_) {
                              _isHoveringSortRow = false;
                              _scheduleCloseSortMenu();
                            },
                            child: InkWell(
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: _toggleSortMenu,
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (_isHoveringSortRow ||
                                          _isHoveringSortMenu)
                                      ? const Color(0xFF2563EB)
                                      : Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.swap_vert,
                                      size: 18,
                                      color:
                                          (_isHoveringSortRow ||
                                              _isHoveringSortMenu)
                                          ? Colors.white
                                          : const Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Sort By',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              (_isHoveringSortRow ||
                                                  _isHoveringSortMenu)
                                              ? Colors.white
                                              : const Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color:
                                          (_isHoveringSortRow ||
                                              _isHoveringSortMenu)
                                          ? Colors.white
                                          : const Color(0xFF2563EB),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      Builder(
                        builder: (importRowContext) => _buildMoreMenuItem(
                          action: _ItemsMoreAction.importItems,
                          onTapOverride: () {
                            updateState(() => _isHoveringImportRow = true);
                            _openImportMenu(importRowContext);
                          },
                          onHover: (isHovered) {
                            updateState(() => _isHoveringImportRow = isHovered);
                            if (isHovered) {
                              _openImportMenu(importRowContext);
                            } else {
                              _scheduleCloseImportMenu();
                            }
                          },
                          child: const _MenuRow(
                            icon: Icons.file_upload_outlined,
                            label: 'Import',
                            trailingIcon: Icons.chevron_right,
                          ),
                        ),
                      ),
                      Builder(
                        builder: (exportRowContext) => _buildMoreMenuItem(
                          action: _ItemsMoreAction.exportItems,
                          onTapOverride: () {
                            updateState(() => _isHoveringExportRow = true);
                            _openExportMenu(exportRowContext);
                          },
                          onHover: (isHovered) {
                            updateState(() => _isHoveringExportRow = isHovered);
                            if (isHovered) {
                              _openExportMenu(exportRowContext);
                            } else {
                              _scheduleCloseExportMenu();
                            }
                          },
                          child: const _MenuRow(
                            icon: Icons.file_download_outlined,
                            label: 'Export',
                            trailingIcon: Icons.chevron_right,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _buildMoreMenuItem(
                        action: _ItemsMoreAction.preferences,
                        child: const _MenuRow(
                          icon: Icons.settings_outlined,
                          label: 'Preferences',
                        ),
                      ),
                      _buildMoreMenuItem(
                        action: _ItemsMoreAction.refreshList,
                        child: const _MenuRow(
                          icon: Icons.refresh_outlined,
                          label: 'Refresh List',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_moreMenuEntry!);
  }

  Widget _buildMoreMenuItem({
    required _ItemsMoreAction action,
    required Widget child,
    ValueChanged<bool>? onHover,
    VoidCallback? onTapOverride,
  }) {
    final ValueNotifier<bool> hover = ValueNotifier(false);

    void updateHover(bool v) {
      hover.value = v;
      onHover?.call(v);
    }

    return MouseRegion(
      onEnter: (_) => updateHover(true),
      onExit: (_) => updateHover(false),
      child: ValueListenableBuilder<bool>(
        valueListenable: hover,
        builder: (context, isHovered, _) {
          final bool stickyImport =
              action == _ItemsMoreAction.importItems &&
              (_isHoveringImportRow || _isHoveringImportMenu);
          final bool stickyExport =
              action == _ItemsMoreAction.exportItems &&
              (_isHoveringExportRow || _isHoveringExportMenu);
          final bool effectiveHover = isHovered || stickyImport || stickyExport;

          final Color bg = effectiveHover
              ? const Color(0xFF2563EB)
              : Colors.white;
          final Color textColor = effectiveHover
              ? Colors.white
              : const Color(0xFF111827);
          final Color iconColor = effectiveHover
              ? Colors.white
              : const Color(0xFF4B5563);

          return InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            onHover: updateHover,
            onTap:
                onTapOverride ??
                () async {
                  _closeMenus();
                  await _handleMoreAction(context, action);
                },
            child: Container(
              color: bg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: IconTheme.merge(
                data: IconThemeData(color: iconColor),
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 13, color: textColor),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _closeMenus() {
    _closeImportMenu();
    _closeExportMenu();
    _closeSortMenu();
    _sortMenuEntry?.remove();
    _sortMenuEntry = null;
    _moreMenuEntry?.remove();
    _moreMenuEntry = null;
    _moreMenuTopLeft = null;
  }

  void _closeImportMenu() {
    _importMenuEntry?.remove();
    _importMenuEntry = null;
    _isHoveringImportRow = false;
    _isHoveringImportMenu = false;
  }

  void _scheduleCloseImportMenu() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!_isHoveringImportRow && !_isHoveringImportMenu) {
        _closeImportMenu();
      }
    });
  }

  void _closeExportMenu() {
    _exportMenuEntry?.remove();
    _exportMenuEntry = null;
    _isHoveringExportRow = false;
    _isHoveringExportMenu = false;
  }

  void _scheduleCloseExportMenu() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!_isHoveringExportRow && !_isHoveringExportMenu) {
        _closeExportMenu();
      }
    });
  }

  void _closeSortMenu() {
    _sortMenuEntry?.remove();
    _sortMenuEntry = null;
    _isHoveringSortRow = false;
    _isHoveringSortMenu = false;
  }

  void _scheduleCloseSortMenu() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!_isHoveringSortRow && !_isHoveringSortMenu) {
        _closeSortMenu();
      }
    });
  }

  void _toggleSortMenu() {
    if (_sortMenuEntry != null) {
      _closeSortMenu();
    } else {
      _openSortMenu();
    }
  }

  void _openSortMenu() {
    if (_sortMenuEntry != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    if (_moreMenuTopLeft == null) return;

    final double left = _moreMenuTopLeft!.dx - 220 - 8;
    final double top = _moreMenuTopLeft!.dy;

    _sortMenuEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: 220,
              child: MouseRegion(
                onEnter: (_) {
                  _isHoveringSortMenu = true;
                },
                onExit: (_) {
                  _isHoveringSortMenu = false;
                  _scheduleCloseSortMenu();
                },
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSortRow(_ItemsSortField.name, "Name"),
                        _buildSortRow(
                          _ItemsSortField.reorderLevel,
                          "Reorder Level",
                        ),
                        _buildSortRow(_ItemsSortField.sku, "SKU"),
                        _buildSortRow(
                          _ItemsSortField.stockOnHand,
                          "Stock On Hand",
                        ),
                        _buildSortRow(_ItemsSortField.hsnSacRate, "HSN/SAC"),
                        _buildSortRow(
                          _ItemsSortField.createdTime,
                          "Created Time",
                        ),
                        _buildSortRow(
                          _ItemsSortField.lastModifiedTime,
                          "Last Modified Time",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_sortMenuEntry!);
  }

  void _openImportMenu(BuildContext rowContext) {
    final overlay = Overlay.of(context, rootOverlay: true);
 
    final RenderBox? box = rowContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset offset = box.localToGlobal(Offset.zero);

    final double left = offset.dx - 200 - 8;
    final double top = offset.dy;

    _importMenuEntry?.remove();
    _importMenuEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        width: 200,
        child: _buildImportMenu(),
      ),
    );

    overlay.insert(_importMenuEntry!);
  }

  Widget _buildImportMenu() {
    return MouseRegion(
      onEnter: (_) {
        updateState(() => _isHoveringImportMenu = true);
      },
      onExit: (_) {
        updateState(() => _isHoveringImportMenu = false);
        _scheduleCloseImportMenu();
      },
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubmenuItem('Import Items', _ItemsMoreAction.importItems),
              _buildSubmenuItem(
                'Import Items Images',
                _ItemsMoreAction.importItemImages,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExportMenu(BuildContext rowContext) {
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
 
    final RenderBox? box = rowContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset offset = box.localToGlobal(Offset.zero);

    final double left = offset.dx - 200 - 8;
    final double top = offset.dy;

    _exportMenuEntry?.remove();
    _exportMenuEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        width: 200,
        child: _buildExportMenu(),
      ),
    );

    overlay.insert(_exportMenuEntry!);
  }

  Widget _buildExportMenu() {
    return MouseRegion(
      onEnter: (_) {
        updateState(() => _isHoveringExportMenu = true);
      },
      onExit: (_) {
        updateState(() => _isHoveringExportMenu = false);
        _scheduleCloseExportMenu();
      },
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubmenuItem('Export Items', _ItemsMoreAction.exportItems),
              _buildSubmenuItem(
                'Export Current View',
                _ItemsMoreAction.exportCurrentItem,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmenuItem(String label, _ItemsMoreAction action) {
    final ValueNotifier<bool> hover = ValueNotifier(false);

    return MouseRegion(
      onEnter: (_) => hover.value = true,
      onExit: (_) => hover.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: hover,
        builder: (context, isHovered, _) {
          final Color bg = isHovered ? const Color(0xFF2563EB) : Colors.white;
          final Color textColor = isHovered
              ? Colors.white
              : const Color(0xFF111827);

          return InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            onHover: (v) => hover.value = v,
            onTap: () {
              _closeMenus();
              _handleMoreAction(context, action);
            },
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(isHovered ? 6 : 0),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHovered ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortRow(_ItemsSortField field, String label) {
    final bool isSelected = field == _currentSortField;
    final IconData arrowIcon = _isAscending
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    final ValueNotifier<bool> hover = ValueNotifier(false);

    return MouseRegion(
      onEnter: (_) => hover.value = true,
      onExit: (_) => hover.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: hover,
        builder: (context, isHovered, _) {
          final bool highlight = isSelected || isHovered;
          final Color bg = isHovered
              ? const Color(0xFF2563EB)
              : isSelected
              ? const Color(0xFFF3F4F6)
              : Colors.white;
          final Color textColor = isHovered
              ? Colors.white
              : const Color(0xFF111827);
          final Color arrowColor = isHovered
              ? Colors.white
              : const Color(0xFF2563EB);

          return InkWell(
            onTap: () {
              updateState(() {
                if (isSelected) {
                  _isAscending = !_isAscending;
                } else {
                  _currentSortField = field;
                  _isAscending = true;
                }
              });
              _closeMenus();
              _handleSortField(context, _currentSortField, _isAscending);
            },
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(highlight ? 4 : 0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected || isHovered)
                    Icon(arrowIcon, size: 16, color: arrowColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

part of '../items_item_create.dart';

extension _ItemCreateSettings on _ItemCreateScreenState {
  void _openUnitConfigDialog() async {
    int? hoveredRowIndex;
    final itemsState = ref.read(itemsControllerProvider);

    final List<_UnitRow> rows = itemsState.units
        .map<_UnitRow>(
          (u) => _UnitRow(u.unitName, u.uqcId, unitId: u.id, isInUse: false),
        )
        .toList();

    try {
      final List<String> unitIds = rows
          .where((r) => r.unitId != null && r.unitId!.isNotEmpty)
          .map<String>((r) => r.unitId!)
          .toList();

      if (unitIds.isNotEmpty) {
        final controller = ref.read(itemsControllerProvider.notifier);
        final response = await controller.checkUnitUsage(unitIds);

        for (var row in rows) {
          if (row.unitId != null && response.contains(row.unitId)) {
            row.isInUse = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking unit usage: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool isSaving = false;
        final scrollController = ScrollController();
        final List<_UnitRow> deletedRows = [];
        final uqcOptions = itemsState.uqcList.map((u) => u.id).toList();
        final Map<String, String> uqcFallbacks = {
          'BAG': 'Bags',
          'BAL': 'Bale',
          'BDL': 'Bundles',
          'BKL': 'Buckles',
          'BOU': 'Billion Of Units',
          'BOX': 'Box',
          'BTL': 'Bottles',
          'BUN': 'Bunches',
          'CAN': 'Cans',
          'CBM': 'Cubic Meters',
          'CCM': 'Cubic Centimeters',
          'CMS': 'Centimeters',
          'CTN': 'Cartons',
          'DOZ': 'Dozen',
          'DRM': 'Drums',
          'FTS': 'Feet',
          'GMS': 'Grammes',
          'GRS': 'Gross',
          'GYD': 'Yards',
          'KGS': 'Kilograms',
          'KLR': 'Kilolitre',
          'KME': 'Kilometre',
          'MLT': 'Mililitre',
          'MTR': 'Meters',
          'MTS': 'Metric Ton',
          'NOS': 'Numbers',
          'PAC': 'Packs',
          'PCS': 'Pieces',
          'PRS': 'Pairs',
          'QTL': 'Quintal',
          'ROL': 'Rolls',
          'SET': 'Sets',
          'SQF': 'Square Feet',
          'SQM': 'Square Meters',
          'SQY': 'Square Yards',
          'TBS': 'Tablets',
          'TBP': 'Tab with Punch',
          'THD': 'Thousands',
          'TON': 'Tonne (Metric Ton)',
          'TUB': 'Tubes',
          'UGS': 'US Gallons',
          'UNT': 'Units',
          'YDS': 'Yards',
        };
        if (uqcOptions.isEmpty) {
          uqcOptions.addAll(uqcFallbacks.keys);
        }

        String? errorMessage;
        return Dialog(
          backgroundColor: Colors.white,
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(
            top: 0,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                  maxHeight: 520,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 18, 16, 12),
                      child: Row(
                        children: [
                          const Text(
                            'Manage Units',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            splashRadius: 18,
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    if (errorMessage != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setDialogState(() => errorMessage = null),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            child: Text(
                              'Unit*',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Unique Quantity Code (UQC)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          return MouseRegion(
                            onEnter: (_) =>
                                setDialogState(() => hoveredRowIndex = index),
                            onExit: (_) =>
                                setDialogState(() => hoveredRowIndex = null),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: CustomTextField(
                                        controller: row.unitCtrl,
                                        focusNode: row.focusNode,
                                        height: 40,
                                        hintText: '',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: FormDropdown<String>(
                                      value: row.uqcId,
                                      items: uqcOptions,
                                      hint: 'Select UQC',
                                      displayStringForValue: (val) {
                                        if (itemsState.uqcList.isNotEmpty) {
                                          try {
                                            final uqc = itemsState.uqcList
                                                .firstWhere((u) => u.id == val);
                                            return uqc.displayName;
                                          } catch (e) {}
                                        }
                                        if (uqcFallbacks.containsKey(val)) {
                                          return '$val (${uqcFallbacks[val]})';
                                        }
                                        return val;
                                      },
                                      itemBuilder:
                                          (val, isSelected, isHovered) {
                                            String display = val;
                                            if (itemsState.uqcList.isNotEmpty) {
                                              try {
                                                final uqc = itemsState.uqcList
                                                    .firstWhere(
                                                      (u) => u.id == val,
                                                    );
                                                display = uqc.displayName;
                                              } catch (e) {}
                                            } else if (uqcFallbacks.containsKey(
                                              val,
                                            )) {
                                              display =
                                                  '$val (${uqcFallbacks[val]})';
                                            }
                                            return Container(
                                              height: 36,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              alignment: Alignment.centerLeft,
                                              decoration: BoxDecoration(
                                                color: isHovered
                                                    ? const Color(0xFF2563EB)
                                                    : isSelected
                                                    ? const Color(0xFFEFF6FF)
                                                    : Colors.transparent,
                                              ),
                                              child: Text(
                                                display,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isHovered
                                                      ? Colors.white
                                                      : isSelected
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFF111827),
                                                ),
                                              ),
                                            );
                                          },
                                      onChanged: (v) {
                                        setDialogState(() {
                                          row.uqcId = v;
                                        });
                                      },
                                      allowClear: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 40,
                                    child: AnimatedOpacity(
                                      opacity: hoveredRowIndex == index ? 1 : 0,
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Tooltip(
                                        message: 'Delete unit',
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Color(0xFFEF4444),
                                          ),
                                          splashRadius: 16,
                                          onPressed: () {
                                            if (ctx.mounted) {
                                              setDialogState(() {
                                                if (row.unitId != null &&
                                                    row.unitId!.isNotEmpty) {
                                                  deletedRows.add(row);
                                                }
                                                rows.removeAt(index);
                                                errorMessage = null;
                                              });
                                            }
                                          },
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
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                      child: StatefulBuilder(
                        builder: (ctx, setFooterState) {
                          return Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  final newRow = _UnitRow('', null);
                                  setDialogState(() {
                                    rows.add(newRow);
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    Future.delayed(
                                      const Duration(milliseconds: 50),
                                      () {
                                        if (scrollController.hasClients) {
                                          scrollController.animateTo(
                                            scrollController
                                                .position
                                                .maxScrollExtent,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                        newRow.focusNode.requestFocus();
                                      },
                                    );
                                  });
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                                label: const Text(
                                  'Add New',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final seenUnitNames = <String>{};
                                        for (var row in rows) {
                                          final name = row.unitCtrl.text.trim();
                                          if (name.isEmpty) {
                                            setDialogState(() {
                                              errorMessage =
                                                  'Please fill in all unit names';
                                            });
                                            return;
                                          }
                                          if (seenUnitNames.contains(
                                            name.toLowerCase(),
                                          )) {
                                            setDialogState(() {
                                              errorMessage =
                                                  'The unit "$name" already exists.';
                                            });
                                            return;
                                          }
                                          seenUnitNames.add(name.toLowerCase());
                                        }

                                        setDialogState(() {
                                          isSaving = true;
                                          errorMessage = null;
                                        });
                                        setFooterState(() => {});

                                        try {
                                          // 2. Reconcile with deletedRows to avoid duplicates and resurrection issues
                                          final List<Unit> syncingUnits = [];
                                          final Set<String>
                                          processedDeletedIds = {};

                                          // First, identify truly deleted units (not being resurrected) to check their usage
                                          final List<String> unitsToCheckUsage =
                                              [];
                                          for (var dr in deletedRows) {
                                            final isResurrected = rows.any(
                                              (r) =>
                                                  r.unitCtrl.text
                                                      .trim()
                                                      .toLowerCase() ==
                                                  dr.unitCtrl.text
                                                      .trim()
                                                      .toLowerCase(),
                                            );
                                            if (!isResurrected &&
                                                dr.unitId != null &&
                                                dr.unitId!.isNotEmpty) {
                                              unitsToCheckUsage.add(dr.unitId!);
                                            }
                                          }

                                          if (unitsToCheckUsage.isNotEmpty) {
                                            final controller = ref.read(
                                              itemsControllerProvider.notifier,
                                            );
                                            final inUseIds = await controller
                                                .checkUnitUsage(
                                                  unitsToCheckUsage,
                                                );

                                            if (inUseIds.isNotEmpty) {
                                              final firstInUseId =
                                                  inUseIds.first;
                                              final inUseRow = deletedRows
                                                  .firstWhere(
                                                    (r) =>
                                                        r.unitId ==
                                                        firstInUseId,
                                                  );

                                              if (ctx.mounted) {
                                                setDialogState(() {
                                                  errorMessage =
                                                      'You cannot delete the unit ${inUseRow.unitCtrl.text} as it is associated with items. Dissociate the unit from all items and try again.';
                                                  // Restore ONLY the ones that are in use and not already in rows
                                                  for (var id in inUseIds) {
                                                    final rowToRestore =
                                                        deletedRows.firstWhere(
                                                          (r) => r.unitId == id,
                                                        );
                                                    if (!rows.any(
                                                      (r) => r.unitId == id,
                                                    )) {
                                                      rows.add(rowToRestore);
                                                    }
                                                  }
                                                  deletedRows.removeWhere(
                                                    (r) => inUseIds.contains(
                                                      r.unitId,
                                                    ),
                                                  );
                                                  isSaving = false;
                                                });
                                                setFooterState(() => {});
                                              }
                                              return;
                                            }
                                          }

                                          for (var row in rows) {
                                            final name = row.unitCtrl.text
                                                .trim();
                                            String? id = row.unitId;

                                            // If it's a new row, check if we have it in deletedRows (resurrection)
                                            if (id == null || id.isEmpty) {
                                              final deletedIdx = deletedRows
                                                  .indexWhere(
                                                    (dr) =>
                                                        dr.unitCtrl.text
                                                            .trim()
                                                            .toLowerCase() ==
                                                        name.toLowerCase(),
                                                  );
                                              if (deletedIdx != -1) {
                                                id = deletedRows[deletedIdx]
                                                    .unitId;
                                                processedDeletedIds.add(id!);
                                              }
                                            }

                                            syncingUnits.add(
                                              Unit(
                                                id: id ?? '',
                                                unitName: name,
                                                uqcId: row.uqcId,
                                                isActive: true,
                                              ),
                                            );
                                          }

                                          // Get controller reference (needed for validation)
                                          final controller = ref.read(
                                            itemsControllerProvider.notifier,
                                          );

                                          // Add remaining truly deleted units
                                          // BUT FIRST: Check if any are in use
                                          final unitsToDelete = <_UnitRow>[];
                                          for (var dr in deletedRows) {
                                            if (dr.unitId != null &&
                                                dr.unitId!.isNotEmpty &&
                                                !processedDeletedIds.contains(
                                                  dr.unitId,
                                                )) {
                                              unitsToDelete.add(dr);
                                            }
                                          }

                                          // Check usage for units to delete
                                          if (unitsToDelete.isNotEmpty) {
                                            final unitIdsToCheck = unitsToDelete
                                                .map((u) => u.unitId!)
                                                .toList();
                                            final inUseIds = await controller
                                                .checkUnitUsage(unitIdsToCheck);

                                            if (inUseIds.isNotEmpty) {
                                              // Find the first unit that's in use
                                              final firstInUseUnit =
                                                  unitsToDelete.firstWhere(
                                                    (u) => inUseIds.contains(
                                                      u.unitId,
                                                    ),
                                                  );

                                              if (ctx.mounted) {
                                                setDialogState(() {
                                                  isSaving = false;
                                                  errorMessage =
                                                      'You cannot delete the unit ${firstInUseUnit.unitCtrl.text} as it is associated with items. Dissociate the unit from all items and try again.';
                                                });
                                                setFooterState(() => {});
                                              }
                                              return;
                                            }

                                            // All units are safe to delete
                                            for (var dr in unitsToDelete) {
                                              syncingUnits.add(
                                                Unit(
                                                  id: dr.unitId!,
                                                  unitName: dr.unitCtrl.text
                                                      .trim(),
                                                  uqcId: dr.uqcId,
                                                  isActive: false,
                                                ),
                                              );
                                            }
                                          }

                                          // Sync units with the server
                                          final results = await controller
                                              .syncUnits(syncingUnits);

                                          if (results.isEmpty) {
                                            // syncUnits already handled the error state in the controller
                                            if (ctx.mounted) {
                                              setDialogState(() {
                                                isSaving = false;
                                                // message is already in controller.state.error but we can show it here
                                                errorMessage =
                                                    ref
                                                        .read(
                                                          itemsControllerProvider,
                                                        )
                                                        .error ??
                                                    'Failed to sync units. Please try again.';
                                              });
                                              setFooterState(() => {});
                                            }
                                            return;
                                          }

                                          if (!mounted) return;

                                          // Wait for the controller to reload fresh data
                                          await controller.loadLookupData();

                                          if (!mounted) return;
                                          ZerpaiBuilders.showSuccessToast(
                                            context,
                                            'Item details have been saved.',
                                          );

                                          if (ctx.mounted) {
                                            Navigator.of(ctx).pop();
                                          }

                                          // Refresh parent screen state
                                          if (mounted) {
                                            updateState(() {});
                                          }
                                        } catch (e) {
                                          if (!mounted) return;
                                          String msg = e.toString();
                                          if (msg.contains(
                                                'units_unit_name_unique',
                                              ) ||
                                              msg.contains('duplicate key')) {
                                            msg =
                                                'A unit with this name already exists.';
                                          } else if (msg.contains(
                                            'deactivated widget',
                                          )) {
                                            // Suppress this specific internal flutter error from showing to user
                                            return;
                                          } else {
                                            msg = 'Error saving units: $e';
                                          }

                                          if (ctx.mounted) {
                                            setDialogState(() {
                                              errorMessage = msg;
                                              isSaving = false;
                                            });
                                            setFooterState(() => {});
                                          }
                                        }
                                      },
                                child: isSaving
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: Skeleton(
                                          width: 16,
                                          height: 16,
                                          borderRadius: 8,
                                          baseColor: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          highlightColor: Colors.white
                                              .withValues(alpha: 0.8),
                                        ),
                                      )
                                    : const Text('Save'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

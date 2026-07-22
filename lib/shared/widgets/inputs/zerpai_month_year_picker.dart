import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ZerpaiMonthYearPicker {
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
  }) async {
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    DateTime? result;
    final years = List<int>.generate(31, (i) => DateTime.now().year - 10 + i);
    const months = <String>[
      '01',
      '02',
      '03',
      '04',
      '05',
      '06',
      '07',
      '08',
      '09',
      '10',
      '11',
      '12',
    ];

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Month & Year',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FormDropdown<String>(
                              value: months[selectedMonth - 1],
                              items: months,
                              hint: 'MM',
                              showSearch: false,
                              onChanged: (v) {
                                if (v == null) return;
                                setLocalState(
                                  () => selectedMonth = int.parse(v),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormDropdown<int>(
                              value: selectedYear,
                              items: years,
                              hint: 'YYYY',
                              showSearch: true,
                              onChanged: (v) {
                                if (v == null) return;
                                setLocalState(() => selectedYear = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ZButton.secondary(
                            label: 'Cancel',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          const SizedBox(width: 8),
                          ZButton.primary(
                            label: 'OK',
                            onPressed: () {
                              result = DateTime(selectedYear, selectedMonth, 1);
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result;
  }
}

// // FILE: lib/modules/items/presentation/sections/formulation_extra_details.dart
// import 'package:flutter/material.dart';
// import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
// import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';

// class FormulationExtraDetails extends StatelessWidget {
//   final TextEditingController dimXCtrl;
//   final TextEditingController dimYCtrl;
//   final TextEditingController dimZCtrl;

//   final String dimUnit;
//   final ValueChanged<String?> onDimUnitChange;

//   final TextEditingController weightCtrl;
//   final String weightUnit;
//   final ValueChanged<String?> onWeightUnitChange;

//   final String? manufacturer;
//   final ValueChanged<String?> onManufacturerChange;

//   final String? brand;
//   final ValueChanged<String?> onBrandChange;

//   final TextEditingController upcCtrl;
//   final TextEditingController mpnCtrl;
//   final TextEditingController eanCtrl;
//   final TextEditingController isbnCtrl;

//   /// Zerpai field wrapper
//   final ZerpaiFieldBuilder zerpaiField;
//   final ZerpaiTextFieldBuilder zerpaiTextField;
//   final ZerpaiDropdownBuilder<String> zerpaiDropdown;

//   const FormulationExtraDetails({
//     super.key,
//     required this.dimXCtrl,
//     required this.dimYCtrl,
//     required this.dimZCtrl,
//     required this.dimUnit,
//     required this.onDimUnitChange,
//     required this.weightCtrl,
//     required this.weightUnit,
//     required this.onWeightUnitChange,
//     required this.manufacturer,
//     required this.onManufacturerChange,
//     required this.brand,
//     required this.onBrandChange,
//     required this.upcCtrl,
//     required this.mpnCtrl,
//     required this.eanCtrl,
//     required this.isbnCtrl,
//     required this.zerpaiField,
//     required this.zerpaiTextField,
//     required this.zerpaiDropdown,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ---------------- Dimensions + Weight ----------------
//           Row(
//             children: [
//               Expanded(
//                 flex: 2,
//                 child: zerpaiField(
//                   label: "Dimensions",
//                   tooltip: "Specify product dimensions accurately.",
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _colBox(138, dimXCtrl, "Length"),
//                       const SizedBox(width: 12),
//                       _colBox(135, dimYCtrl, "Width"),
//                       const SizedBox(width: 12),
//                       _colBox(135, dimZCtrl, "Height"),
//                       const SizedBox(width: 12),
//                       SizedBox(
//                         width: 70,
//                         child: FormDropdown<String>(
//                           value: dimUnit,
//                           items: const ["cm", "mm", "in"],
//                           onChanged: onDimUnitChange,
//                           showSearch: false,
//                           itemBuilder: (id, isSelected, isHovered) {
//                             return Container(
//                               height: 36,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                               ),
//                               alignment: Alignment.centerLeft,
//                               decoration: BoxDecoration(
//                                 color: isHovered
//                                     ? const Color(0xFF2563EB)
//                                     : isSelected
//                                     ? const Color(0xFFEFF6FF)
//                                     : Colors.transparent,
//                               ),
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       id,
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         color: isHovered
//                                             ? Colors.white
//                                             : isSelected
//                                             ? const Color(0xFF2563EB)
//                                             : const Color(0xFF111827),
//                                       ),
//                                     ),
//                                   ),
//                                   if (isSelected)
//                                     Icon(
//                                       Icons.check,
//                                       size: 16,
//                                       color: isHovered
//                                           ? Colors.white
//                                           : const Color(0xFF2563EB),
//                                     ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 24),

//               Expanded(
//                 flex: 1,
//                 child: zerpaiField(
//                   label: "Weight",
//                   tooltip: "Enter weight with correct unit.",
//                   child: Row(
//                     children: [
//                       SizedBox(
//                         width: 138,
//                         child: zerpaiTextField(
//                           controller: weightCtrl,
//                           hint: null,
//                           keyboardType: TextInputType.number,
//                           maxLines: 1,
//                           height: 44,
//                           enabled: true,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       SizedBox(
//                         width: 70,
//                         child: FormDropdown<String>(
//                           value: weightUnit,
//                           items: const ["kg", "g", "lb"],
//                           onChanged: onWeightUnitChange,
//                           showSearch: false,
//                           itemBuilder: (id, isSelected, isHovered) {
//                             return Container(
//                               height: 36,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                               ),
//                               alignment: Alignment.centerLeft,
//                               decoration: BoxDecoration(
//                                 color: isHovered
//                                     ? const Color(0xFF2563EB)
//                                     : isSelected
//                                     ? const Color(0xFFEFF6FF)
//                                     : Colors.transparent,
//                               ),
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       id,
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         color: isHovered
//                                             ? Colors.white
//                                             : isSelected
//                                             ? const Color(0xFF2563EB)
//                                             : const Color(0xFF111827),
//                                       ),
//                                     ),
//                                   ),
//                                   if (isSelected)
//                                     Icon(
//                                       Icons.check,
//                                       size: 16,
//                                       color: isHovered
//                                           ? Colors.white
//                                           : const Color(0xFF2563EB),
//                                     ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           // ---------------- Manufacturer / Brand ----------------
//           Row(
//             children: [
//               Expanded(
//                 child: zerpaiField(
//                   label: "Manufacturer",
//                   tooltip: "Select or add manufacturer name.",
//                   child: FormDropdown<String>(
//                     value: manufacturer,
//                     items: const ["Cipla", "Sun Pharma", "Dr. Reddy's"],
//                     hint: "Select or Add Manufacturer",
//                     onChanged: onManufacturerChange,
//                     itemBuilder: (id, isSelected, isHovered) {
//                       return Container(
//                         height: 36,
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         alignment: Alignment.centerLeft,
//                         decoration: BoxDecoration(
//                           color: isHovered
//                               ? const Color(0xFF2563EB)
//                               : isSelected
//                               ? const Color(0xFFEFF6FF)
//                               : Colors.transparent,
//                         ),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 id,
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: isHovered
//                                       ? Colors.white
//                                       : isSelected
//                                       ? const Color(0xFF2563EB)
//                                       : const Color(0xFF111827),
//                                 ),
//                               ),
//                             ),
//                             if (isSelected)
//                               Icon(
//                                 Icons.check,
//                                 size: 16,
//                                 color: isHovered
//                                     ? Colors.white
//                                     : const Color(0xFF2563EB),
//                               ),
//                           ],
//                         ),
//                       );
//                     },
//                     showSettings: true,
//                     settingsLabel: "Manage Manufacturers...",
//                     allowClear: true,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 24),
//               Expanded(
//                 child: zerpaiField(
//                   label: "Brand",
//                   tooltip: "Brand name of the product.",
//                   child: FormDropdown<String>(
//                     value: brand,
//                     items: const ["Brand A", "Brand B"],
//                     hint: "Select or Add Brand",
//                     onChanged: onBrandChange,
//                     itemBuilder: (id, isSelected, isHovered) {
//                       return Container(
//                         height: 36,
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         alignment: Alignment.centerLeft,
//                         decoration: BoxDecoration(
//                           color: isHovered
//                               ? const Color(0xFF2563EB)
//                               : isSelected
//                               ? const Color(0xFFEFF6FF)
//                               : Colors.transparent,
//                         ),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 id,
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: isHovered
//                                       ? Colors.white
//                                       : isSelected
//                                       ? const Color(0xFF2563EB)
//                                       : const Color(0xFF111827),
//                                 ),
//                               ),
//                             ),
//                             if (isSelected)
//                               Icon(
//                                 Icons.check,
//                                 size: 16,
//                                 color: isHovered
//                                     ? Colors.white
//                                     : const Color(0xFF2563EB),
//                               ),
//                           ],
//                         ),
//                       );
//                     },
//                     showSettings: true,
//                     settingsLabel: "Manage Brands...",
//                     allowClear: true,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           // ---------------- MPN / UPC ----------------
//           Row(
//             children: [
//               Expanded(
//                 child: zerpaiField(
//                   label: "MPN",
//                   tooltip: "Manufacturer Part Number.",
//                   child: zerpaiTextField(
//                     controller: mpnCtrl,
//                     hint: "Enter MPN",
//                     height: 44,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 24),
//               Expanded(
//                 child: zerpaiField(
//                   label: "UPC",
//                   tooltip: "12-digit Universal Product Code.",
//                   child: zerpaiTextField(
//                     controller: upcCtrl,
//                     hint: "Enter UPC",
//                     height: 44,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           // ---------------- ISBN / EAN ----------------
//           Row(
//             children: [
//               Expanded(
//                 child: zerpaiField(
//                   label: "ISBN",
//                   tooltip: "13-digit International Standard Book Number.",
//                   child: zerpaiTextField(
//                     controller: isbnCtrl,
//                     hint: "Enter ISBN",
//                     height: 44,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 24),
//               Expanded(
//                 child: zerpaiField(
//                   label: "EAN",
//                   tooltip: "13-digit European Article Number.",
//                   child: zerpaiTextField(
//                     controller: eanCtrl,
//                     hint: "Enter EAN",
//                     height: 44,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _colBox(double width, TextEditingController c, String label) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(
//           width: width,
//           child: zerpaiTextField(
//             controller: c,
//             hint: null,
//             keyboardType: TextInputType.number,
//             maxLines: 1,
//             height: 44,
//             enabled: true,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
//         ),
//       ],
//     );
//   }
// }
// FILE: lib/modules/items/presentation/sections/formulation_extra_details.dart
import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class FormulationExtraDetails extends StatelessWidget {
  final TextEditingController dimXCtrl;
  final TextEditingController dimYCtrl;
  final TextEditingController dimZCtrl;

  final String dimUnit;
  final ValueChanged<String?> onDimUnitChange;

  final TextEditingController weightCtrl;
  final String weightUnit;
  final ValueChanged<String?> onWeightUnitChange;

  final String? manufacturer;
  final ValueChanged<String?> onManufacturerChange;

  final String? brand;
  final ValueChanged<String?> onBrandChange;

  final TextEditingController upcCtrl;
  final TextEditingController mpnCtrl;
  final TextEditingController eanCtrl;
  final TextEditingController isbnCtrl;

  /// Zerpai field wrapper
  final Widget Function({
    required String label,
    bool required,
    String? helper,
    String? tooltip,
    required Widget child,
    Color? labelColor,
  })
  zerpaiField;

  final Widget Function({
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType,
    int maxLines,
    double height,
    bool enabled,
  })
  zerpaiTextField;

  final Widget Function<T>({
    required T? value,
    required List<T> items,
    String? hint,
    required ValueChanged<T?> onChanged,
  })
  zerpaiDropdown;

  const FormulationExtraDetails({
    super.key,
    required this.dimXCtrl,
    required this.dimYCtrl,
    required this.dimZCtrl,
    required this.dimUnit,
    required this.onDimUnitChange,
    required this.weightCtrl,
    required this.weightUnit,
    required this.onWeightUnitChange,
    required this.manufacturer,
    required this.onManufacturerChange,
    required this.brand,
    required this.onBrandChange,
    required this.upcCtrl,
    required this.mpnCtrl,
    required this.eanCtrl,
    required this.isbnCtrl,
    required this.zerpaiField,
    required this.zerpaiTextField,
    required this.zerpaiDropdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- Dimensions + Weight ----------------
          Row(
            children: [
              Expanded(
                flex: 2,
                child: zerpaiField(
                  label: "Dimensions",
                  tooltip: "Specify product dimensions accurately.",
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _colBox(138, dimXCtrl, "Length"),
                      const SizedBox(width: 12),
                      _colBox(135, dimYCtrl, "Width"),
                      const SizedBox(width: 12),
                      _colBox(135, dimZCtrl, "Height"),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 70,
                        child: FormDropdown<String>(
                          value: dimUnit,
                          items: const ["cm", "mm", "in"],
                          onChanged: onDimUnitChange,
                          showSearch: false,
                          itemBuilder: (id, isSelected, isHovered) {
                            return Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      id,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isHovered
                                            ? Colors.white
                                            : isSelected
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: isHovered
                                          ? Colors.white
                                          : const Color(0xFF2563EB),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              Expanded(
                flex: 1,
                child: zerpaiField(
                  label: "Weight",
                  tooltip: "Enter weight with correct unit.",
                  child: Row(
                    children: [
                      SizedBox(
                        width: 138,
                        child: zerpaiTextField(
                          controller: weightCtrl,
                          hint: null,
                          keyboardType: TextInputType.number,
                          maxLines: 1,
                          height: 44,
                          enabled: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 70,
                        child: FormDropdown<String>(
                          value: weightUnit,
                          items: const ["kg", "g", "lb"],
                          onChanged: onWeightUnitChange,
                          showSearch: false,
                          itemBuilder: (id, isSelected, isHovered) {
                            return Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      id,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isHovered
                                            ? Colors.white
                                            : isSelected
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: isHovered
                                          ? Colors.white
                                          : const Color(0xFF2563EB),
                                    ),
                                ],
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

          const SizedBox(height: 20),

          // ---------------- Manufacturer / Brand ----------------
          Row(
            children: [
              Expanded(
                child: zerpaiField(
                  label: "Manufacturer/Patent",
                  tooltip: "Select or add manufacturer/patent name.",
                  child: FormDropdown<String>(
                    value: manufacturer,
                    items: const ["Cipla", "Sun Pharma", "Dr. Reddy's"],
                    hint: "Select or Add Manufacturer/Patent",
                    onChanged: onManufacturerChange,
                    itemBuilder: (id, isSelected, isHovered) {
                      return Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: isHovered
                              ? const Color(0xFF2563EB)
                              : isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                id,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHovered
                                      ? Colors.white
                                      : isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF111827),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: isHovered
                                    ? Colors.white
                                    : const Color(0xFF2563EB),
                              ),
                          ],
                        ),
                      );
                    },
                    showSettings: true,
                    settingsLabel: "Manage Manufacturer/Patents...",
                    allowClear: true,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: zerpaiField(
                  label: "Brand",
                  tooltip: "Brand name of the product.",
                  child: FormDropdown<String>(
                    value: brand,
                    items: const ["Brand A", "Brand B"],
                    hint: "Select or Add Brand",
                    onChanged: onBrandChange,
                    itemBuilder: (id, isSelected, isHovered) {
                      return Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: isHovered
                              ? const Color(0xFF2563EB)
                              : isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                id,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHovered
                                      ? Colors.white
                                      : isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF111827),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: isHovered
                                    ? Colors.white
                                    : const Color(0xFF2563EB),
                              ),
                          ],
                        ),
                      );
                    },
                    showSettings: true,
                    settingsLabel: "Manage Brands...",
                    allowClear: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------- MPN / UPC ----------------
          Row(
            children: [
              Expanded(
                child: zerpaiField(
                  label: "MPN",
                  tooltip: "Manufacturer/Patent Part Number.",
                  child: zerpaiTextField(
                    controller: mpnCtrl,
                    hint: "Enter MPN",
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: zerpaiField(
                  label: "UPC",
                  tooltip: "12-digit Universal Product Code.",
                  child: zerpaiTextField(
                    controller: upcCtrl,
                    hint: "Enter UPC",
                    height: 44,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------- ISBN / EAN ----------------
          Row(
            children: [
              Expanded(
                child: zerpaiField(
                  label: "ISBN",
                  tooltip: "13-digit International Standard Book Number.",
                  child: zerpaiTextField(
                    controller: isbnCtrl,
                    hint: "Enter ISBN",
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: zerpaiField(
                  label: "EAN",
                  tooltip: "13-digit European Article Number.",
                  child: zerpaiTextField(
                    controller: eanCtrl,
                    hint: "Enter EAN",
                    height: 44,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colBox(double width, TextEditingController c, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width,
          child: zerpaiTextField(
            controller: c,
            hint: null,
            keyboardType: TextInputType.number,
            maxLines: 1,
            height: 44,
            enabled: true,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}

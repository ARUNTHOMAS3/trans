import 'package:flutter/material.dart';

class FontFamilyOption {
  const FontFamilyOption(this.label, this.family);

  final String label;
  final String family;

  String get editorFontFamily => family;
}

const List<FontFamilyOption> kDefaultFontFamilyOptions = <FontFamilyOption>[
  FontFamilyOption('Arial', 'Arial'),
  FontFamilyOption('Inter', 'Inter'),
  FontFamilyOption('Roboto', 'Roboto'),
];

class FontFamilyDropdown extends StatelessWidget {
  const FontFamilyDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.isActive = false,
    this.width = 128,
    this.menuWidth = 172,
    this.onMenuStateChanged,
  });

  final List<FontFamilyOption> options;
  final FontFamilyOption value;
  final ValueChanged<FontFamilyOption> onChanged;
  final bool isActive;
  final double width;
  final double menuWidth;
  final ValueChanged<bool>? onMenuStateChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FontFamilyOption>(
          value: value,
          isExpanded: true,
          menuWidth: menuWidth,
          onTap: () => onMenuStateChanged?.call(true),
          onChanged: (next) {
            if (next != null) onChanged(next);
            onMenuStateChanged?.call(false);
          },
          items: options
              .map(
                (option) => DropdownMenuItem<FontFamilyOption>(
                  value: option,
                  child: Text(option.label),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

part of '../items_item_create.dart';

extension _ItemCreateWidgets on _ItemCreateScreenState {
  Widget _zerpaiField({
    required String label,
    bool? required = false,
    String? helper,
    String? tooltip,
    double? maxWidth,
    double? labelWidth,
    required Widget child,
    Color? labelColor,
  }) {
    return SharedFieldLayout(
      label: label,
      required: required ?? false,
      helper: helper,
      tooltip: tooltip,
      labelColor: labelColor,
      maxWidth: maxWidth,
      labelWidth: labelWidth ?? 150,
      child: child,
    );
  }

  Widget _zerpaiTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType = TextInputType.text,
    int? maxLines = 1,
    double? height = 44,
    bool? enabled = true,
    String? errorText,
  }) {
    return CustomTextField(
      controller: controller,
      hintText: hint,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLines: maxLines ?? 1,
      height: height ?? 44,
      enabled: enabled ?? true,
      errorText: errorText,
    );
  }

  Widget _zerpaiDropdown<T>({
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    Widget Function(T item, bool isSelected, bool isHovered)? itemBuilder,
    String Function(T value)? displayStringForValue,
    bool? showSettings = false,
    String? settingsLabel = 'Manage...',
    VoidCallback? onSettingsTap,
    bool? allowClear = false,
    String? errorText,
    bool? enabled = true,
    bool? showSearch = true,
    bool? showSearchIcon = true,
    Future<List<T>> Function(String query)? onSearch,
  }) {
    return FormDropdown<T>(
      value: value,
      items: items,
      hint: hint,
      onChanged: (enabled ?? true) ? onChanged : (_) {},
      itemBuilder: itemBuilder,
      displayStringForValue: displayStringForValue,
      showSettings: showSettings ?? false,
      settingsLabel: settingsLabel ?? 'Manage...',
      onSettingsTap: onSettingsTap,
      allowClear: allowClear ?? false,
      enabled: enabled ?? true,
      errorText: errorText,
      showSearch: showSearch ?? true,
      onSearch: onSearch,
    );
  }
}

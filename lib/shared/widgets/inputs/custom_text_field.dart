import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

enum ContentCase { none, uppercase, sentence }

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final bool autoFocus;
  final TextAlign textAlign;
  final double? height;
  final FocusNode? focusNode;
  final bool showLeftBorder;
  final bool showRightBorder;
  final bool forceUppercase;
  final ContentCase? contentCase;
  final bool hideBorderDefault;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final bool prefixBox;
  final EdgeInsets? padding;
  final bool suffixSeparator;
  final Iterable<String>? autofillHints;
  final bool isHovered;
  final TextStyle? textStyle;
  final Widget? suffixWidget;
  final bool resizable;
  final double? minHeight;
  final ValueChanged<double>? onHeightChanged;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.autoFocus = false,
    this.textAlign = TextAlign.start,
    this.height,
    this.focusNode,
    this.showLeftBorder = true,
    this.showRightBorder = true,
    this.forceUppercase = false,
    this.contentCase,
    this.hideBorderDefault = false,
    this.fillColor,
    this.borderRadius,
    this.border,
    this.prefixIcon,
    this.prefixWidget,
    this.prefixBox = false,
    this.padding,
    this.suffixSeparator = false,
    this.autofillHints,
    this.isHovered = false,
    this.textStyle,
    this.resizable = false,
    this.minHeight,
    this.onHeightChanged,
    Widget? suffixWidget,
    @Deprecated('Use suffixWidget instead') Widget? suffix,
  }) : suffixWidget = suffixWidget ?? suffix;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _internalFocusNode;
  bool _isHovered = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fieldHeight = widget.height ?? 38.0;
    final bool isMultiline =
        (widget.maxLines == null || widget.maxLines! > 1) || fieldHeight > 60;
    final bool hasError = widget.errorText != null;

    _effectiveFocusNode.canRequestFocus = widget.enabled;

    /// Border color logic
    Color borderColor;
    if (hasError) {
      borderColor = AppTheme.errorRed;
    } else if (!widget.enabled) {
      borderColor = AppTheme.borderColor;
    } else if (_effectiveFocusNode.hasFocus) {
      borderColor = AppTheme.primaryBlueDark;
    } else {
      borderColor = AppTheme.borderColor;
    }

    final bool shouldShowBorder =
        !widget.hideBorderDefault ||
        _effectiveFocusNode.hasFocus ||
        _isHovered ||
        widget.isHovered ||
        hasError;
    final Color effectiveBorderColor = shouldShowBorder
        ? borderColor
        : Colors.transparent;

    List<TextInputFormatter> formatters = List.from(
      widget.inputFormatters ?? [],
    );

    if (widget.keyboardType == TextInputType.number ||
        widget.keyboardType ==
            const TextInputType.numberWithOptions(decimal: true)) {
      formatters.add(
        NumericOnlyFormatter(
          allowDecimal:
              widget.keyboardType ==
              const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }

    ContentCase effectiveCase = widget.contentCase ?? ContentCase.none;

    if (widget.contentCase == null) {
      if (widget.keyboardType == TextInputType.number ||
          widget.keyboardType ==
              const TextInputType.numberWithOptions(decimal: true) ||
          widget.keyboardType == TextInputType.emailAddress ||
          widget.keyboardType == TextInputType.phone ||
          widget.keyboardType == TextInputType.url) {
        effectiveCase = ContentCase.none;
      } else if (widget.maxLines == null ||
          widget.maxLines! > 1 ||
          fieldHeight > 60) {
        effectiveCase = ContentCase.sentence;
      } else {
        effectiveCase = ContentCase.uppercase;
      }
    }

    if (widget.forceUppercase == true) {
      effectiveCase = ContentCase.uppercase;
    } else if (widget.forceUppercase == false && widget.contentCase == null) {
      if (effectiveCase == ContentCase.uppercase) {
        effectiveCase = ContentCase.none;
      }
    }

    if (effectiveCase == ContentCase.uppercase) {
      formatters.add(UpperCaseTextFormatter());
    } else if (effectiveCase == ContentCase.sentence) {
      formatters.add(SentenceCaseTextFormatter());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textBody,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (widget.resizable)
          _ResizableFieldWrapper(
            minHeight: widget.minHeight ?? widget.height ?? 38.0,
            onHeightChanged: widget.onHeightChanged,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color:
                    widget.fillColor ??
                    (widget.enabled ? Colors.white : const Color(0xFFF3F4F6)),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
                border: widget.border ??
                    Border(
                      top: BorderSide(color: effectiveBorderColor, width: 1),
                      bottom: BorderSide(color: effectiveBorderColor, width: 1),
                      left: widget.showLeftBorder
                          ? BorderSide(color: effectiveBorderColor, width: 1)
                          : BorderSide.none,
                      right: widget.showRightBorder
                          ? BorderSide(color: effectiveBorderColor, width: 1)
                          : BorderSide.none,
                    ),
              ),
              padding:
                  widget.padding ??
                  EdgeInsets.only(
                    left:
                        (widget.prefixWidget != null ||
                                widget.prefixIcon != null) &&
                            widget.prefixBox
                        ? 0
                        : 10,
                    right: 10,
                  ),
              alignment: isMultiline ? Alignment.topLeft : Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: isMultiline
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (widget.prefixWidget != null ||
                      widget.prefixIcon != null) ...[
                    if (widget.prefixBox)
                      Container(
                        height: fieldHeight,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppTheme.borderColor),
                          ),
                          color: Colors.transparent,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        margin: const EdgeInsets.only(right: 10),
                        alignment: Alignment.center,
                        child: widget.prefixWidget ??
                            Icon(
                              widget.prefixIcon,
                              size: 18,
                              color: widget.enabled
                                  ? AppTheme.textSecondary
                                  : AppTheme.textMuted,
                            ),
                      )
                    else ...[
                      widget.prefixWidget ??
                          Icon(
                            widget.prefixIcon,
                            size: 18,
                            color: widget.enabled
                                ? AppTheme.textSecondary
                                : AppTheme.textMuted,
                          ),
                      const SizedBox(width: 8),
                    ],
                  ],
                  Expanded(
                    child: TextFormField(
                      focusNode: _effectiveFocusNode,
                      controller: widget.controller,
                      autofocus: widget.autoFocus,
                      enabled: widget.enabled,
                      keyboardType: widget.keyboardType,
                      readOnly: widget.readOnly,
                      onChanged: widget.onChanged,
                      onFieldSubmitted: widget.onSubmitted,
                      validator: widget.validator,
                      textAlign: widget.textAlign,
                      obscureText: widget.obscureText,
                      autofillHints: widget.autofillHints,
                      inputFormatters: formatters,
                      maxLines: isMultiline ? widget.maxLines : 1,
                      textCapitalization: effectiveCase == ContentCase.uppercase
                          ? TextCapitalization.characters
                          : (effectiveCase == ContentCase.sentence
                              ? TextCapitalization.sentences
                              : TextCapitalization.none),
                      style: widget.textStyle ??
                          TextStyle(
                            fontSize: 13,
                            color: widget.enabled
                                ? AppTheme.textPrimary
                                : AppTheme.textMuted,
                          ),
                      decoration: InputDecoration(
                        filled: false,
                        hoverColor: Colors.transparent,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                        errorStyle: const TextStyle(
                          height: 0,
                          fontSize: 0,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: widget.onTap,
                    ),
                  ),
                  if (widget.suffixWidget != null) ...[
                    if (widget.suffixSeparator)
                      Container(
                        width: 1,
                        height: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: AppTheme.borderColor,
                      ),
                    const SizedBox(width: 8),
                    widget.suffixWidget!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!widget.resizable)
          SizedBox(
            height: fieldHeight,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: widget.fillColor ??
                      (widget.enabled ? Colors.white : const Color(0xFFF3F4F6)),
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
                  border: widget.border ??
                      Border(
                        top: BorderSide(color: effectiveBorderColor, width: 1),
                        bottom: BorderSide(color: effectiveBorderColor, width: 1),
                        left: widget.showLeftBorder
                            ? BorderSide(color: effectiveBorderColor, width: 1)
                            : BorderSide.none,
                        right: widget.showRightBorder
                            ? BorderSide(color: effectiveBorderColor, width: 1)
                            : BorderSide.none,
                      ),
                ),
                padding: widget.padding ??
                    EdgeInsets.only(
                      left: (widget.prefixWidget != null ||
                                  widget.prefixIcon != null) &&
                              widget.prefixBox
                          ? 0
                          : 10,
                      right: 10,
                    ),
                alignment: isMultiline ? Alignment.topLeft : Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: isMultiline
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (widget.prefixWidget != null ||
                        widget.prefixIcon != null) ...[
                      if (widget.prefixBox)
                        Container(
                          height: fieldHeight,
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: AppTheme.borderColor),
                            ),
                            color: Colors.transparent,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          margin: const EdgeInsets.only(right: 10),
                          alignment: Alignment.center,
                          child: widget.prefixWidget ??
                              Icon(widget.prefixIcon, size: 18,
                                  color: widget.enabled
                                      ? AppTheme.textSecondary
                                      : AppTheme.textMuted),
                        )
                      else ...[
                        widget.prefixWidget ??
                            Icon(widget.prefixIcon, size: 18,
                                color: widget.enabled
                                    ? AppTheme.textSecondary
                                    : AppTheme.textMuted),
                        const SizedBox(width: 8),
                      ],
                    ],
                    Expanded(
                      child: TextFormField(
                        focusNode: _effectiveFocusNode,
                        controller: widget.controller,
                        autofocus: widget.autoFocus,
                        enabled: widget.enabled,
                        keyboardType: widget.keyboardType,
                        readOnly: widget.readOnly,
                        onChanged: widget.onChanged,
                        onFieldSubmitted: widget.onSubmitted,
                        validator: widget.validator,
                        textAlign: widget.textAlign,
                        obscureText: widget.obscureText,
                        autofillHints: widget.autofillHints,
                        inputFormatters: formatters,
                        maxLines: isMultiline ? widget.maxLines : 1,
                        textCapitalization: effectiveCase == ContentCase.uppercase
                            ? TextCapitalization.characters
                            : (effectiveCase == ContentCase.sentence
                                ? TextCapitalization.sentences
                                : TextCapitalization.none),
                        style: widget.textStyle ??
                            TextStyle(
                              fontSize: 13,
                              color: widget.enabled
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                            ),
                        decoration: InputDecoration(
                          filled: false,
                          hoverColor: Colors.transparent,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: widget.hintText,
                          hintStyle: const TextStyle(
                              fontSize: 13, color: AppTheme.textMuted),
                          errorStyle:
                              const TextStyle(height: 0, fontSize: 0),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: widget.onTap,
                      ),
                    ),
                    if (widget.suffixWidget != null) ...[
                      if (widget.suffixSeparator)
                        Container(
                          width: 1,
                          height: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: AppTheme.borderColor,
                        ),
                      const SizedBox(width: 8),
                      widget.suffixWidget!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: AppTheme.errorRed,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ResizableFieldWrapper extends StatefulWidget {
  final Widget child;
  final double minHeight;
  final ValueChanged<double>? onHeightChanged;

  const _ResizableFieldWrapper({
    required this.child,
    required this.minHeight,
    this.onHeightChanged,
  });

  @override
  State<_ResizableFieldWrapper> createState() => _ResizableFieldWrapperState();
}

class _ResizableFieldWrapperState extends State<_ResizableFieldWrapper> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.onHeightChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reportHeight());
    }
  }

  void _reportHeight() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) widget.onHeightChanged?.call(box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _reportHeight());
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: ConstrainedBox(
          key: _key,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          child: widget.child,
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String newText = newValue.text.toUpperCase();
    if (newText == newValue.text) return newValue;

    return newValue.copyWith(
      text: newText,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

class SentenceCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String text = newValue.text;
    String newText = "";
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (capitalizeNext && RegExp(r'[a-zA-Z]').hasMatch(char)) {
        newText += char.toUpperCase();
        capitalizeNext = false;
      } else {
        newText += char;
      }

      if (char == '.' || char == '!' || char == '?') {
        capitalizeNext = true;
      } else if (char.trim().isNotEmpty && !capitalizeNext) {
      }
    }

    return TextEditingValue(text: newText, selection: newValue.selection);
  }
}

class NumericOnlyFormatter extends TextInputFormatter {
  final bool allowDecimal;
  final bool allowNegative;

  NumericOnlyFormatter({this.allowDecimal = true, this.allowNegative = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String pattern = r'^';
    if (allowNegative) pattern += r'-?';
    pattern += r'\d*';
    if (allowDecimal) pattern += r'\.?\d*';
    pattern += r'$';

    final regex = RegExp(pattern);

    if (regex.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}

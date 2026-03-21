// FILE: lib/core/widgets/forms/custom_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Zerpai-style Text Field:
/// - Default height = 44 (matches dropdown)
/// - Blue border when focused
/// - Grey border normally
/// - Supports prefix icon (
/// - Disabled state styling
enum ContentCase { none, uppercase, sentence }

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? label;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final IconData? prefixIcon;
  final double? height;
  final String? errorText;
  final Widget? prefixWidget;
  final bool prefixBox;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final bool? forceUppercase;
  final ContentCase? contentCase;
  final BorderRadius? borderRadius;
  final Widget? suffixWidget;
  final FocusNode? focusNode;
  final bool showLeftBorder;
  final bool showRightBorder;
  final Color? fillColor;
  final bool hideBorderDefault;
  final EdgeInsets? padding;
  final bool suffixSeparator;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.label,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.height,
    this.enabled = true,
    this.prefixIcon,
    this.prefixWidget,
    this.prefixBox = false,
    this.errorText,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.validator,
    this.forceUppercase,
    this.contentCase,
    this.borderRadius,
    this.focusNode,
    Widget? suffixWidget,
    Widget? suffix,
    this.showLeftBorder = true,
    this.showRightBorder = true,
    this.fillColor,
    this.hideBorderDefault = false,
    this.padding,
    this.suffixSeparator = false,
  }) : suffixWidget = suffixWidget ?? suffix;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  FocusNode? _internalFocusNode;
  late FocusNode _effectiveFocusNode;
  bool _isHovered = false;

  static const double _defaultHeight = 44;

  @override
  void initState() {
    super.initState();

    // Use external focusNode if provided, otherwise create internal one
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _effectiveFocusNode = widget.focusNode ?? _internalFocusNode!;

    _effectiveFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // Only dispose internal focus node
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fieldHeight = widget.height ?? _defaultHeight;
    final bool isMultiline = widget.maxLines > 1 || fieldHeight > 60;
    final bool hasError = widget.errorText != null;

    _effectiveFocusNode.canRequestFocus = widget.enabled;

    /// Border color logic
    Color borderColor;
    if (hasError) {
      borderColor = const Color(0xFFEF4444); // Red on error
    } else if (!widget.enabled) {
      borderColor = const Color(0xFFE5E7EB);
    } else if (_effectiveFocusNode.hasFocus) {
      borderColor = const Color(0xFF2563EB); // Blue on focus
    } else {
      borderColor = const Color(0xFFD1D5DB); // Default grey
    }

    final bool shouldShowBorder =
        !widget.hideBorderDefault ||
        _effectiveFocusNode.hasFocus ||
        _isHovered ||
        hasError;

    final effectiveBorderColor = shouldShowBorder
        ? borderColor
        : Colors.transparent;

    // Handle input formatters
    List<TextInputFormatter> formatters = widget.inputFormatters ?? [];

    // Auto-apply numeric formatter for number fields
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

    // Determine effective content case
    ContentCase effectiveCase = widget.contentCase ?? ContentCase.none;

    // If not explicitly set, determine based on widget type
    if (widget.contentCase == null) {
      if (widget.keyboardType == TextInputType.number ||
          widget.keyboardType ==
              const TextInputType.numberWithOptions(decimal: true) ||
          widget.keyboardType == TextInputType.emailAddress ||
          widget.keyboardType == TextInputType.phone ||
          widget.keyboardType == TextInputType.url) {
        effectiveCase = ContentCase.none;
      } else if (widget.maxLines > 1 || fieldHeight > 60) {
        effectiveCase = ContentCase.sentence;
      } else {
        effectiveCase = ContentCase.uppercase;
      }
    }

    // Support legacy forceUppercase flag
    if (widget.forceUppercase == true) {
      effectiveCase = ContentCase.uppercase;
    } else if (widget.forceUppercase == false && widget.contentCase == null) {
      // If explicitly set to false, don't auto-uppercase
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
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
        ],
        SizedBox(
          height: fieldHeight,
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
                border: Border(
                  top: BorderSide(color: effectiveBorderColor),
                  bottom: BorderSide(color: effectiveBorderColor),
                  left: widget.showLeftBorder
                      ? BorderSide(color: effectiveBorderColor)
                      : BorderSide.none,
                  right: widget.showRightBorder
                      ? BorderSide(color: effectiveBorderColor)
                      : BorderSide.none,
                ),
              ),
              padding:
                  widget.padding ??
                  EdgeInsets.only(left: widget.prefixBox ? 0 : 10, right: 10),
              alignment: isMultiline ? Alignment.topLeft : Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: isMultiline
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  /// PREFIX ICON / WIDGET
                  if (widget.prefixWidget != null ||
                      widget.prefixIcon != null) ...[
                    if (widget.prefixBox)
                      Container(
                        height: fieldHeight,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          color: Color(0xFFF9FAFB),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        margin: const EdgeInsets.only(right: 10),
                        alignment: Alignment.center,
                        child:
                            widget.prefixWidget ??
                            Icon(
                              widget.prefixIcon,
                              size: 18,
                              color: widget.enabled
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                            ),
                      )
                    else ...[
                      widget.prefixWidget ??
                          Icon(
                            widget.prefixIcon,
                            size: 18,
                            color: widget.enabled
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                          ),
                      const SizedBox(width: 8),
                    ],
                  ],

                  /// TEXT FIELD
                  Expanded(
                    child: TextFormField(
                      focusNode: _effectiveFocusNode,
                      controller: widget.controller,
                      enabled: widget.enabled,
                      keyboardType: widget.keyboardType,
                      readOnly: widget.readOnly,
                      onChanged: widget.onChanged,
                      validator: widget.validator,
                      textAlign: widget.textAlign,
                      inputFormatters: formatters,
                      maxLines: isMultiline ? widget.maxLines : 1,
                      textCapitalization: effectiveCase == ContentCase.uppercase
                          ? TextCapitalization.characters
                          : (effectiveCase == ContentCase.sentence
                                ? TextCapitalization.sentences
                                : TextCapitalization.none),
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.enabled
                            ? const Color(0xFF111827)
                            : const Color(0xFF9CA3AF),
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        contentPadding: EdgeInsets.zero,
                        errorStyle: const TextStyle(
                          height: 0,
                          fontSize: 0,
                        ), // Hide default error text as we show it below
                      ),
                    ),
                  ),

                  /// SUFFIX WIDGET
                  if (widget.suffixWidget != null) ...[
                    if (widget.suffixSeparator)
                      Container(
                        width: 1,
                        height: fieldHeight,
                        color: effectiveBorderColor,
                      ),
                    const SizedBox(width: 4),
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
              color: Color(0xFFEF4444),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
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
        // We only forcefully lowercase if we want strict sentence case.
        // However, usually people might want to keep some acronyms.
        // For simple "Sentence Case" as requested:
        newText += char;
      }

      if (char == '.' || char == '!' || char == '?') {
        capitalizeNext = true;
      } else if (char.trim().isNotEmpty && !capitalizeNext) {
        // If we found a character and we were looking to capitalize, we've done it.
        // If we are just mid-sentence, we keep looking for sentence enders.
      }
    }

    return TextEditingValue(text: newText, selection: newValue.selection);
  }
}

/// Numeric-only formatter - allows digits, one decimal point, and optionally minus sign
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

    // Build regex pattern based on options
    String pattern = r'^';
    if (allowNegative) pattern += r'-?';
    pattern += r'\d*';
    if (allowDecimal) pattern += r'\.?\d*';
    pattern += r'$';

    final regex = RegExp(pattern);

    if (regex.hasMatch(newValue.text)) {
      return newValue;
    }

    // Invalid input - return old value
    return oldValue;
  }
}

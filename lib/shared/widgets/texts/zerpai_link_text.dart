import 'package:flutter/material.dart';

class ZerpaiLinkText extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final TextStyle? style;

  const ZerpaiLinkText({
    super.key,
    required this.text,
    required this.onTap,
    this.style,
  });

  @override
  State<ZerpaiLinkText> createState() => _ZerpaiLinkTextState();
}

class _ZerpaiLinkTextState extends State<ZerpaiLinkText> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Default Zoho-blue #2563EB and Inter font
    final baseStyle =
        widget.style ?? const TextStyle(fontSize: 14, fontFamily: 'Inter');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: baseStyle.copyWith(
            color: const Color(0xFF2563EB),
            decoration: _isHovering
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: const Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }
}

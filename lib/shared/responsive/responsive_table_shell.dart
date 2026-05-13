import 'package:flutter/material.dart';

class ResponsiveTableShell extends StatefulWidget {
  final Widget child;
  final double minWidth;
  final bool thumbVisibility;
  final EdgeInsetsGeometry? padding;

  const ResponsiveTableShell({
    super.key,
    required this.child,
    required this.minWidth,
    this.thumbVisibility = true,
    this.padding,
  });

  @override
  State<ResponsiveTableShell> createState() => _ResponsiveTableShellState();
}

class _ResponsiveTableShellState extends State<ResponsiveTableShell> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: widget.thumbVisibility,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth),
          child: widget.child,
        ),
      ),
    );
  }
}

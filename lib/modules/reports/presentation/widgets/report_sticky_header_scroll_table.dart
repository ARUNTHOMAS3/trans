import 'package:flutter/material.dart';

class ReportStickyHeaderScrollTable extends StatefulWidget {
  final Widget header;
  final List<Widget> children;
  final Widget emptyBody;
  final bool isEmpty;
  final EdgeInsetsGeometry padding;

  const ReportStickyHeaderScrollTable({
    super.key,
    required this.header,
    required this.children,
    required this.emptyBody,
    this.isEmpty = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<ReportStickyHeaderScrollTable> createState() =>
      _ReportStickyHeaderScrollTableState();
}

class _ReportStickyHeaderScrollTableState
    extends State<ReportStickyHeaderScrollTable> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRows = !widget.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(child: widget.header),
        Expanded(
          child: RepaintBoundary(
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: hasRows,
              child: hasRows
                  ? ListView(
                      controller: _verticalController,
                      primary: false,
                      physics: const ClampingScrollPhysics(),
                      padding: widget.padding,
                      children: widget.children,
                    )
                  : SingleChildScrollView(
                      controller: _verticalController,
                      primary: false,
                      physics: const ClampingScrollPhysics(),
                      padding: widget.padding,
                      child: widget.emptyBody,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

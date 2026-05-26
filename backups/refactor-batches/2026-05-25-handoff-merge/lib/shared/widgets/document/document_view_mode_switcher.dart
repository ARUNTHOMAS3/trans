import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/document/document_view_toggle.dart';

class DocumentViewModeSwitcher extends StatelessWidget {
  const DocumentViewModeSwitcher({
    super.key,
    required this.showPdfView,
    required this.onChanged,
    required this.normalView,
    required this.pdfView,
    this.toggleLabel = 'Show PDF View',
  });

  final bool showPdfView;
  final ValueChanged<bool> onChanged;
  final Widget normalView;
  final Widget pdfView;
  final String toggleLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DocumentViewToggle(
          showPdfView: showPdfView,
          onChanged: onChanged,
          label: toggleLabel,
        ),
        Expanded(child: showPdfView ? pdfView : normalView),
      ],
    );
  }
}

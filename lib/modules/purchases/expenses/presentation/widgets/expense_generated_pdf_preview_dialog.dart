import 'dart:convert';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

final Set<String> _registeredExpenseGeneratedPdfFrames = <String>{};

class ExpenseGeneratedPdfPreviewDialog extends StatelessWidget {
  const ExpenseGeneratedPdfPreviewDialog({
    super.key,
    required this.title,
    required this.pdfBytes,
    required this.onPrint,
  });

  final String title;
  final Uint8List pdfBytes;
  final Future<void> Function() onPrint;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFF5F6F8),
      child: Material(
        color: const Color(0xFFF5F6F8),
        child: Column(
          children: [
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Text(
                    'Preview',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 86,
                    child: ZButton.primary(
                      label: 'Print',
                      onPressed: () async {
                        await onPrint();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.borderMid),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(84, 36),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFF2D2D2D),
                child: _ExpenseGeneratedPdfFrame(
                  title: title,
                  pdfBytes: pdfBytes,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseGeneratedPdfFrame extends StatefulWidget {
  const _ExpenseGeneratedPdfFrame({
    required this.title,
    required this.pdfBytes,
  });

  final String title;
  final Uint8List pdfBytes;

  @override
  State<_ExpenseGeneratedPdfFrame> createState() =>
      _ExpenseGeneratedPdfFrameState();
}

class _ExpenseGeneratedPdfFrameState extends State<_ExpenseGeneratedPdfFrame> {
  bool _showLoading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showLoading = false);
    });
  }

  String get _viewerUrl {
    final encoded = base64Encode(widget.pdfBytes);
    return 'data:application/pdf;base64,$encoded#toolbar=1&navpanes=1&view=FitH';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || widget.pdfBytes.isEmpty) {
      return const _GeneratedPdfPreviewError();
    }

    final viewType =
        'expense-generated-pdf-${widget.title.hashCode}-${widget.pdfBytes.length}';
    if (_registeredExpenseGeneratedPdfFrames.add(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = _viewerUrl
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
        return iframe;
      });
    }

    return Stack(
      children: [
        Positioned.fill(child: HtmlElementView(viewType: viewType)),
        if (_showLoading)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF2D2D2D),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ZBone(
                    width: 30,
                    height: 30,
                    borderRadius: 15,
                    color: Color(0x33FFFFFF),
                  ),
                  const SizedBox(height: 14),
                  const ZBone(width: 136, height: 12, color: Color(0x33FFFFFF)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GeneratedPdfPreviewError extends StatelessWidget {
  const _GeneratedPdfPreviewError();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        'Preview unavailable for this document.',
        style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

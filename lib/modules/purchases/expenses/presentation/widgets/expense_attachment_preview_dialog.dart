import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

final Set<String> _registeredExpenseAttachmentPreviewFrames = <String>{};

class ExpenseAttachmentPreviewDialog extends StatelessWidget {
  const ExpenseAttachmentPreviewDialog({
    super.key,
    required this.title,
    required this.fileUrl,
    required this.isPdf,
    this.uploadedBy,
  });

  final String title;
  final String fileUrl;
  final bool isPdf;
  final String? uploadedBy;

  @override
  Widget build(BuildContext context) {
    if (isPdf) {
      return Dialog.fullscreen(
        backgroundColor: const Color(0xFF1F2433),
        child: _ExpenseAttachmentPdfViewer(
          title: title,
          fileUrl: fileUrl,
          uploadedBy: uploadedBy,
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 760),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        fileUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const _PreviewError(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseAttachmentPdfViewer extends StatelessWidget {
  const _ExpenseAttachmentPdfViewer({
    required this.title,
    required this.fileUrl,
    required this.uploadedBy,
  });

  final String title;
  final String fileUrl;
  final String? uploadedBy;

  String? get _uploadedByLabel {
    final value = uploadedBy?.trim();
    if (value == null || value.isEmpty) return null;
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (uuidPattern.hasMatch(value)) return null;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1F2433),
      child: Column(
        children: [
          Container(
            height: 84,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFF1A2032),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (_uploadedByLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Uploaded By: $_uploadedByLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: Color(0xFFFF6B57),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF2D2D2D),
              child: _ExpenseAttachmentPdfFrame(url: fileUrl),
            ),
          ),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: const Color(0xFF1A2032),
            alignment: Alignment.centerLeft,
            child: Text(
              '1 of 1 Files',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseAttachmentPdfFrame extends StatefulWidget {
  const _ExpenseAttachmentPdfFrame({required this.url});

  final String url;

  @override
  State<_ExpenseAttachmentPdfFrame> createState() =>
      _ExpenseAttachmentPdfFrameState();
}

class _ExpenseAttachmentPdfFrameState
    extends State<_ExpenseAttachmentPdfFrame> {
  bool _showLoading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _showLoading = false;
      });
    });
  }

  String get _viewerUrl {
    if (widget.url.contains('#')) {
      return widget.url;
    }
    return '${widget.url}#toolbar=1&navpanes=1&view=FitH';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || widget.url.trim().isEmpty) {
      return const _PreviewError();
    }

    final viewType = 'expense-attachment-pdf-${_viewerUrl.hashCode}';
    if (_registeredExpenseAttachmentPreviewFrames.add(viewType)) {
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
                      width: 28,
                      height: 28,
                      borderRadius: 14,
                      color: Color(0x33FFFFFF),
                    ),
                    const SizedBox(height: 14),
                    const ZBone(
                      width: 136,
                      height: 12,
                      color: Color(0x33FFFFFF),
                    ),
                  ],
                ),
            ),
          ),
      ],
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Text(
        'Preview unavailable for this attachment.',
        style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

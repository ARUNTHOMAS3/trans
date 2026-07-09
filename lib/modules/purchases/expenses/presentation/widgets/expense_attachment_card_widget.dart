import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_attachment_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expense_attachment_preview_dialog.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class ExpenseAttachmentCardWidget extends StatefulWidget {
  const ExpenseAttachmentCardWidget({
    super.key,
    required this.attachments,
    this.onDelete,
    this.onUploadTap,
    this.enableHeaderUpload = false,
    this.width = 246,
    this.height = 330,
  });

  final List<ExpenseAttachmentModel> attachments;
  final Future<void> Function(ExpenseAttachmentModel attachment)? onDelete;
  final VoidCallback? onUploadTap;
  final bool enableHeaderUpload;
  final double width;
  final double height;

  @override
  State<ExpenseAttachmentCardWidget> createState() =>
      _ExpenseAttachmentCardWidgetState();
}

class _ExpenseAttachmentCardWidgetState
    extends State<ExpenseAttachmentCardWidget> {
  bool _attachmentsCollapsed = false;
  int _currentAttachmentIndex = 0;

  Widget _buildPdfPreviewBadge() {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD32F2F), width: 4),
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
              ),
              alignment: Alignment.center,
              child: const Text(
                'PDF',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD32F2F),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          Positioned(
            top: -1,
            right: -1,
            child: CustomPaint(
              size: const Size(28, 28),
              painter: _PdfFoldPainter(),
            ),
          ),
        ],
      ),
    );
  }

  String _attachmentDisplayName(ExpenseAttachmentModel attachment) {
    final original = attachment.originalFileName?.trim() ?? '';
    if (original.isNotEmpty) {
      return original;
    }
    return attachment.fileName.trim().isNotEmpty
        ? attachment.fileName.trim()
        : 'Attachment';
  }

  bool _isPdfAttachment(ExpenseAttachmentModel attachment) {
    final type = (attachment.fileType ?? '').toLowerCase();
    final name = _attachmentDisplayName(attachment).toLowerCase();
    final url = attachment.fileUrl.toLowerCase();
    return type.contains('pdf') ||
        name.endsWith('.pdf') ||
        url.endsWith('.pdf');
  }

  bool _isImageAttachment(ExpenseAttachmentModel attachment) {
    final type = (attachment.fileType ?? '').toLowerCase();
    final name = _attachmentDisplayName(attachment).toLowerCase();
    final url = attachment.fileUrl.toLowerCase();
    return type.startsWith('image/') ||
        name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }

  Future<void> _openAttachmentPreview(ExpenseAttachmentModel attachment) async {
    final fileUrl = attachment.fileUrl.trim();
    if (fileUrl.isEmpty) {
      ZerpaiToast.error(context, 'Preview is unavailable for this attachment.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => ExpenseAttachmentPreviewDialog(
        title: _attachmentDisplayName(attachment),
        fileUrl: fileUrl,
        isPdf: _isPdfAttachment(attachment),
        uploadedBy: attachment.uploadedBy,
      ),
    );
  }

  Widget _buildAttachmentPreviewArea(ExpenseAttachmentModel attachment) {
    if (_isImageAttachment(attachment) &&
        attachment.fileUrl.trim().isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 164, maxHeight: 164),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  attachment.fileUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    LucideIcons.image,
                    size: 72,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 164),
              child: Text(
                _attachmentDisplayName(attachment),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isPdf = _isPdfAttachment(attachment);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 116,
            child: Center(
              child: isPdf
                  ? _buildPdfPreviewBadge()
                  : const Icon(
                      LucideIcons.fileText,
                      size: 76,
                      color: AppTheme.textMuted,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 164),
            child: Text(
              _attachmentDisplayName(attachment),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadLabel() {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.upload, size: 15, color: AppTheme.textBody),
        const SizedBox(width: 7),
        Text(
          'Upload your Files',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textBody,
          ),
        ),
      ],
    );

    if (widget.onUploadTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        bottomLeft: Radius.circular(12),
      ),
      onTap: widget.onUploadTap,
      child: content,
    );
  }

  Widget _buildUploadCard() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: DottedBorder(
        color: AppTheme.borderLight,
        strokeWidth: 1,
        dashPattern: const [4, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 22),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.image,
                  size: 22,
                  color: AppTheme.backgroundColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Drag or Drop your Receipts',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Maximum file size allowed is 10MB',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 160,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.bgDisabled,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildUploadLabel()),
                    Container(
                      width: 1,
                      height: 22,
                      color: AppTheme.borderLight,
                    ),
                    const SizedBox(
                      width: 34,
                      child: Center(
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionLabel() {
    final content = Row(
      children: [
        const Icon(LucideIcons.upload, size: 15, color: AppTheme.textSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Upload your Files',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textBody,
            ),
          ),
        ),
      ],
    );

    if (!widget.enableHeaderUpload || widget.onUploadTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: widget.onUploadTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachments = widget.attachments;
    if (attachments.isEmpty) {
      return _buildUploadCard();
    }

    final safeIndex = _currentAttachmentIndex.clamp(0, attachments.length - 1);
    final attachment = attachments[safeIndex];
    final canGoPrev = safeIndex > 0;
    final canGoNext = safeIndex < attachments.length - 1;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildHeaderActionLabel()),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(
                      () => _attachmentsCollapsed = !_attachmentsCollapsed,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _attachmentsCollapsed
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppTheme.borderLight),
            Expanded(
              child: _attachmentsCollapsed
                  ? const SizedBox.shrink()
                  : InkWell(
                      onTap: () => _openAttachmentPreview(attachment),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: _buildAttachmentPreviewArea(attachment),
                      ),
                    ),
            ),
            Container(height: 1, color: AppTheme.borderLight),
            SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    if (attachments.length > 1) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: canGoPrev
                            ? () => setState(() => _currentAttachmentIndex -= 1)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: canGoPrev
                                ? AppTheme.textSecondary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                    Expanded(
                      child: Text(
                        '${safeIndex + 1} of ${attachments.length} Files',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textBody,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (attachments.length > 1) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: canGoNext
                            ? () => setState(() => _currentAttachmentIndex += 1)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: canGoNext
                                ? AppTheme.textSecondary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.onDelete != null)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => widget.onDelete!(attachment),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.trash2,
                            size: 15,
                            color: Color(0xFFFF6B57),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfFoldPainter extends CustomPainter {
  const _PdfFoldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

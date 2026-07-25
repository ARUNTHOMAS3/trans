import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Approval flow side panel — shared by the Approvals overview and the Purchase
/// Request overview ("View approval flow"). Owned by the approvals submodule.

enum ApprovalFlowStatus { approved, pending, rejected }

/// One approver's decision on a document.
class ApprovalFlowEntry {
  const ApprovalFlowEntry({
    required this.approver,
    required this.status,
    required this.submittedOn,
    this.approverEmail,
    this.decidedOn,
  });

  final String approver;
  final String? approverEmail;
  final ApprovalFlowStatus status;

  /// Display date (DD-MM-YYYY).
  final String submittedOn;

  /// Date the approver approved/rejected (DD-MM-YYYY). Falls back to
  /// [submittedOn] when the backend has not recorded a decision timestamp.
  final String? decidedOn;
}

/// Right-anchored drawer with a scrim. Insert as an [OverlayEntry].
class ApprovalFlowPanel extends StatelessWidget {
  const ApprovalFlowPanel({
    super.key,
    required this.entry,
    required this.onClose,
  });

  final ApprovalFlowEntry entry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 460,
          child: Material(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
                  child: Row(
                    children: [
                      const Text(
                        'Approval Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppTheme.bgDisabled,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x,
                                size: 16, color: AppTheme.textBody),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: ApprovalFlowCard(entry: entry),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The approver card: status pill straddling the top border, approver identity,
/// and the submitted/decided dates. The bottom edge tapers into a downward
/// chevron marking the flow to the next stage.
class ApprovalFlowCard extends StatelessWidget {
  const ApprovalFlowCard({super.key, required this.entry});

  final ApprovalFlowEntry entry;

  // Height of the chevron tail below the card body.
  static const double _tailHeight = 26;

  // The pill sits centred on the top border, so half of it overhangs the card.
  static const double _pillHeight = 24;

  Color _accent(ApprovalFlowStatus s) => switch (s) {
        ApprovalFlowStatus.approved => AppTheme.successGreen,
        ApprovalFlowStatus.rejected => AppTheme.errorRed,
        ApprovalFlowStatus.pending => AppTheme.warningOrange,
      };

  Color _pillBg(ApprovalFlowStatus s) => switch (s) {
        ApprovalFlowStatus.approved => AppTheme.successBg,
        ApprovalFlowStatus.rejected => AppTheme.errorBg,
        ApprovalFlowStatus.pending => AppTheme.warningBg,
      };

  Color _pillText(ApprovalFlowStatus s) => switch (s) {
        ApprovalFlowStatus.approved => AppTheme.successTextDark,
        ApprovalFlowStatus.rejected => AppTheme.errorTextDark,
        ApprovalFlowStatus.pending => AppTheme.warningTextDark,
      };

  String _label(ApprovalFlowStatus s) => switch (s) {
        ApprovalFlowStatus.approved => 'APPROVED',
        ApprovalFlowStatus.rejected => 'REJECTED',
        ApprovalFlowStatus.pending => 'PENDING',
      };

  String _decisionLabel(ApprovalFlowStatus s) => switch (s) {
        ApprovalFlowStatus.approved => 'Approved On:',
        ApprovalFlowStatus.rejected => 'Rejected On:',
        ApprovalFlowStatus.pending => 'Pending Since:',
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent(entry.status);
    final name = entry.approver.trim();
    final initial = name.isEmpty ? '—' : name[0].toUpperCase();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _pillHeight / 2),
          child: CustomPaint(
            painter: _FlowCardPainter(
              borderColor: accent,
              tailHeight: _tailHeight,
            ),
            child: Padding(
              // Bottom padding clears the chevron tail.
              padding: const EdgeInsets.fromLTRB(
                  20, 28, 20, 20 + _tailHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          border: Border.all(color: accent, width: 1.5),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? '—' : name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (entry.approverEmail != null &&
                                entry.approverEmail!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                entry.approverEmail!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  const SizedBox(height: 14),
                  _DateRow(label: 'Submitted On:', date: entry.submittedOn),
                  const SizedBox(height: 6),
                  _DateRow(
                    label: _decisionLabel(entry.status),
                    date: entry.decidedOn ?? entry.submittedOn,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Status pill, centred on the card's top border.
        Container(
          height: _pillHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: _pillBg(entry.status),
            borderRadius: BorderRadius.circular(_pillHeight / 2),
          ),
          child: Text(
            _label(entry.status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _pillText(entry.status),
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded card whose bottom edge slopes into a centred downward point.
class _FlowCardPainter extends CustomPainter {
  const _FlowCardPainter({required this.borderColor, required this.tailHeight});

  final Color borderColor;
  final double tailHeight;

  static const double _radius = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shoulderY = h - tailHeight; // where the side edges stop

    final path = Path()
      ..moveTo(0, _radius)
      ..quadraticBezierTo(0, 0, _radius, 0)
      ..lineTo(w - _radius, 0)
      ..quadraticBezierTo(w, 0, w, _radius)
      ..lineTo(w, shoulderY)
      ..lineTo(w / 2, h)
      ..lineTo(0, shoulderY)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = borderColor.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_FlowCardPainter old) =>
      old.borderColor != borderColor || old.tailHeight != tailHeight;
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.date});

  final String label;
  final String date;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
          TextSpan(
            text: date,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

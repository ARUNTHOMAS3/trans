import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// ZerpaiDocumentView
//
// Usage:
//   ZerpaiDocumentView(
//     documentType:   'PICKLIST',
//     documentNumber: 'Picklist# PL-00007',
//     status:         'COMPLETED',
//     statusColor:    Color(0xFF1E8E3E),
//     child: Column(children: [
//       ZerpaiDocumentMetaRow(children: [...]),
//       SizedBox(height: 24),
//       ZerpaiDocumentTableHeader(children: [...]),
//       ZerpaiDocumentTableRow(children: [...]),
//     ]),
//   )
// ---------------------------------------------------------------------------

/// Page-style document viewer: gray canvas, white card, diagonal ribbon,
/// auto-populated company header from [orgSettingsProvider].
/// Pass the document body (meta row, table, etc.) via [child].
class ZerpaiDocumentView extends ConsumerWidget {
  const ZerpaiDocumentView({
    super.key,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.statusColor,
    required this.child,
    this.aspectRatio = 1.2,
    this.padding = const EdgeInsets.all(32),
  });

  final String documentType;
  final String documentNumber;
  final String status;
  final Color statusColor;

  /// Document body — meta row, table header, rows, totals, etc.
  final Widget child;

  final double aspectRatio;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgAddress = orgSettings?.resolvedPaymentStubAddress?.trim();

    return Container(
      color: const Color(0xFFF0F0F0),
      padding: padding,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRect(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 100, 48, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DocumentLogo(orgSettings: orgSettings),
                                  const SizedBox(height: 14),
                                  Text(
                                    orgSettings?.name.trim().isNotEmpty == true
                                        ? orgSettings!.name.trim().toUpperCase()
                                        : 'YOUR COMPANY NAME',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (orgAddress?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        orgAddress!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  if (orgSettings
                                          ?.companyIdentityLine
                                          ?.isNotEmpty ==
                                      true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        orgSettings!.companyIdentityLine!,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  documentType,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  documentNumber,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ZerpaiDocumentCornerRibbon(
                      label: status,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ZerpaiDocumentCornerRibbon
// ---------------------------------------------------------------------------

/// Diagonal status ribbon in the top-left corner of the document card.
class ZerpaiDocumentCornerRibbon extends StatelessWidget {
  const ZerpaiDocumentCornerRibbon({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const double size = 110;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _CornerFoldPainter(color: color),
          ),
          Positioned(
            top: 24,
            left: -46,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: -46,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      HSLColor.fromColor(color)
                          .withLightness(
                            (HSLColor.fromColor(color).lightness * 0.85).clamp(
                              0.0,
                              1.0,
                            ),
                          )
                          .toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 95,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFoldPainter extends CustomPainter {
  const _CornerFoldPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.45).clamp(0.0, 1.0),
        )
        .toColor();

    final paint = Paint()..color = darkColor;

    final path = Path()
      ..moveTo(72, 0)
      ..lineTo(84, 0)
      ..lineTo(72, 12)
      ..close()
      ..moveTo(0, 72)
      ..lineTo(0, 84)
      ..lineTo(12, 72)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// ZerpaiDocumentMetaRow
// ---------------------------------------------------------------------------

/// Horizontal strip with top/bottom borders containing info blocks and totals.
/// Children should be [ZerpaiDocumentInfoBlock] and/or [ZerpaiDocumentTotalBlock].
class ZerpaiDocumentMetaRow extends StatelessWidget {
  const ZerpaiDocumentMetaRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: children),
    );
  }
}

// ---------------------------------------------------------------------------
// ZerpaiDocumentInfoBlock
// ---------------------------------------------------------------------------

/// Label + bold value column, flex-expanded. Use inside [ZerpaiDocumentMetaRow].
class ZerpaiDocumentInfoBlock extends StatelessWidget {
  const ZerpaiDocumentInfoBlock({
    super.key,
    required this.label,
    required this.value,
    this.flex = 2,
  });

  final String label;
  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ZerpaiDocumentTotalBlock
// ---------------------------------------------------------------------------

/// Highlighted grey box showing a summary total. Use inside [ZerpaiDocumentMetaRow].
class ZerpaiDocumentTotalBlock extends StatelessWidget {
  const ZerpaiDocumentTotalBlock({
    super.key,
    required this.label,
    required this.value,
    this.width = 100,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFF1F3F4),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ZerpaiDocumentTableHeader
// ---------------------------------------------------------------------------

/// Dark (#333) header bar for the document table.
/// Children should be [ZerpaiDocumentHeaderCell].
class ZerpaiDocumentTableHeader extends StatelessWidget {
  const ZerpaiDocumentTableHeader({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF333333),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(children: children),
    );
  }
}

// ---------------------------------------------------------------------------
// ZerpaiDocumentHeaderCell
// ---------------------------------------------------------------------------

/// White bold cell for use inside [ZerpaiDocumentTableHeader].
/// Provide either [flex] or [width], not both.
class ZerpaiDocumentHeaderCell extends StatelessWidget {
  const ZerpaiDocumentHeaderCell(
    this.text, {
    super.key,
    this.flex,
    this.width,
    this.align = TextAlign.left,
  }) : assert(flex != null || width != null, 'Provide flex or width');

  final String text;
  final int? flex;
  final double? width;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      textAlign: align,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex!, child: child);
  }
}

// ---------------------------------------------------------------------------
// ZerpaiDocumentTableRow
// ---------------------------------------------------------------------------

/// Single data row in the document table with a bottom border.
/// Children should be [ZerpaiDocumentDataCell].
class ZerpaiDocumentTableRow extends StatelessWidget {
  const ZerpaiDocumentTableRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ZerpaiDocumentDataCell
// ---------------------------------------------------------------------------

/// Data cell for use inside [ZerpaiDocumentTableRow].
/// Provide either [flex] or [width], not both.
class ZerpaiDocumentDataCell extends StatelessWidget {
  const ZerpaiDocumentDataCell(
    this.text, {
    super.key,
    this.flex,
    this.width,
    this.align = TextAlign.left,
    this.fontWeight,
  }) : assert(flex != null || width != null, 'Provide flex or width');

  final String text;
  final int? flex;
  final double? width;
  final TextAlign align;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      textAlign: align,
      style: TextStyle(fontSize: 10, fontWeight: fontWeight),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex!, child: child);
  }
}

// ---------------------------------------------------------------------------
// _DocumentLogo (private)
// ---------------------------------------------------------------------------

class _DocumentLogo extends StatelessWidget {
  const _DocumentLogo({required this.orgSettings});

  final dynamic orgSettings;

  @override
  Widget build(BuildContext context) {
    final logoUrl = orgSettings?.logoUrl as String?;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 140,
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 140,
      height: 60,
      color: const Color(0xFF101820),
      child: const Center(
        child: Text(
          'LOGO',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

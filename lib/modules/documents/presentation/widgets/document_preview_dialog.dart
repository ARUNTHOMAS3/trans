import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/documents/presentation/widgets/new_folder_dialog.dart';
import 'package:zerpai_erp/modules/documents/presentation/pages/documents_report_page.dart';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isHighlighter;

  Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.isHighlighter = false,
  });
}

class DocumentPreviewDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> doc;

  const DocumentPreviewDialog({super.key, required this.doc});

  static void show(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF0F1115),
        child: DocumentPreviewDialog(doc: doc),
      ),
    );
  }

  @override
  ConsumerState<DocumentPreviewDialog> createState() => _DocumentPreviewDialogState();
}

class _DocumentPreviewDialogState extends ConsumerState<DocumentPreviewDialog> {
  double _zoom = 0.9; 
  int _rotation = 0; 
  bool _penActive = false;
  bool _sidebarVisible = true;
  
  // Drawing configuration
  String _activeTool = 'pen'; 
  double _strokeWidth = 4.0;
  Color _strokeColor = Colors.black;

  final List<Stroke> _strokes = [];
  List<Offset> _currentPoints = [];

  // Color Grid Palette matching the screenshot
  final List<List<Color>> _colorPalette = [
    [
      Colors.black,
      const Color(0xFF5A5A5A),
      const Color(0xFF9E9E9E),
      Colors.white,
      const Color(0xFFFFDAB9),
    ],
    [
      const Color(0xFFFFA07A),
      const Color(0xFFFFFACD),
      const Color(0xFF98FB98),
      const Color(0xFF87CEEB),
      const Color(0xFFFFF8DC),
    ],
    [
      Colors.red,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      const Color(0xFFD2B48C),
    ],
    [
      const Color(0xFF8B0000),
      Colors.orange,
      const Color(0xFF006400),
      const Color(0xFF00008B),
      const Color(0xFF8B4513),
    ],
  ];

  Future<pw.Document> _generatePdf(Map<String, dynamic> doc) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 100,
                          height: 40,
                          color: PdfColor.fromHex('#1A1D24'),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'LOGO',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'YOUR COMPANY',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'QUOTATION',
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Quote# QT-000003',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                // Info block
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pwInfoRow('Date:', '20-04-2026'),
                        _pwInfoRow('Status:', 'Accepted'),
                        _pwInfoRow('Salesperson:', 'ALTHAF'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _pwInfoRow('Customer:', 'CUS-1'),
                        _pwInfoRow('Email:', 'zabnixprivatelimited@gmail.com'),
                        _pwInfoRow('Location:', 'ZABNIX PRIVATE LIMITED'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                // Table
                pw.Table(
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                    bottom: pw.BorderSide(color: PdfColors.grey400),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Item & Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BATCH TARCK ITEM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('sales description demo txt', style: const pw.TextStyle(color: PdfColors.grey)),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('10 pcs'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rs. 199.00'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rs. 1,990.00'),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                // Totals
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.SizedBox(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _pwTotalRow('Sub Total', 'Rs. 1,990.00'),
                        _pwTotalRow('CGST', 'Rs. 49.75'),
                        _pwTotalRow('SGST', 'Rs. 49.75'),
                        _pwTotalRow('Round Off', 'Rs. 0.50'),
                        pw.Divider(color: PdfColors.grey),
                        _pwTotalRow('Total', 'Rs. 2,090.00', isBold: true),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey)),
                pw.SizedBox(height: 4),
                pw.Text('Looking forward for your business.', style: const pw.TextStyle(color: PdfColors.grey)),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  pw.Widget _pwInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey)),
          pw.SizedBox(width: 6),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _pwTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> _handlePrint(Map<String, dynamic> doc) async {
    final pdf = await _generatePdf(doc);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: doc['fileName'] ?? 'document.pdf',
    );
  }

  Future<void> _handleDownload(Map<String, dynamic> doc) async {
    final pdf = await _generatePdf(doc);
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: doc['fileName'] ?? 'document.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fileName = widget.doc['fileName'] as String? ?? 'Document';
    final String uploadedOn = widget.doc['uploadedOn'] as String? ?? '28-07-2026 11:21 AM';
    final String uploadedBy = widget.doc['uploadedBy'] as String? ?? 'zabnixprivatelimited';

    return Column(
      children: [
        // ── 1. Top dark bar (Enlarged) ───────────────────────────────────────
        Container(
          height: 64,
          color: const Color(0xFF1E222B),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$uploadedOn  •  Uploaded By: $uploadedBy',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 3-dots button
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  color: Colors.white,
                  elevation: 6,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 180, maxWidth: 180),
                  icon: const Icon(LucideIcons.moreVertical, color: Colors.white, size: 22),
                  itemBuilder: (ctx) => [
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'Download',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _handleDownload(widget.doc);
                        },
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'Open in new tab',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opened $fileName in a new tab'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'Delete',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop(); // Closes preview dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted $fileName'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Move to dropdown (Wired to MoveToDropdownContent from main page)
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  color: Colors.white,
                  elevation: 6,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFF2C313C),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Move to',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.chevronDown, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: MoveToDropdownContent(
                        ref: ref,
                        onNewFolderTap: () {
                          Navigator.of(ctx).pop();
                          NewFolderDialog.show(context);
                        },
                        onSelectFolder: (folderName) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Moved document to $folderName'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Add to green button (Wired to UploadMenuItems from main page)
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  color: Colors.white,
                  elevation: 6,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Add to',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.chevronDown, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'New Bill',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'New Purchase Order',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'New Vendor Credits',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'Customer',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'Vendor',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'New Sales Order',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'New Invoice',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      height: 32,
                      child: UploadMenuItem(
                        label: 'New Bill Of Supply',
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Close X button
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        // ── 2. Secondary toolbar (Enlarged + Wired Zoom & Rotate) ────────────
        Container(
          height: 50,
          color: const Color(0xFF2A2E39),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.menu, color: Colors.white70, size: 20),
                onPressed: () => setState(() {
                  _sidebarVisible = !_sidebarVisible;
                }),
              ),
              const SizedBox(width: 14),
              const Text(
                '2161563000002352006',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              // Page index
              const Text('1  /  1', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(width: 20),
              // Fit tools (Zoom Out)
              IconButton(
                icon: const Icon(LucideIcons.minus, color: Colors.white70, size: 18),
                onPressed: () => setState(() {
                  if (_zoom > 0.4) _zoom -= 0.1;
                }),
              ),
              const SizedBox(width: 6),
              Text(
                '${(_zoom * 100).round()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 6),
              // Zoom In
              IconButton(
                icon: const Icon(LucideIcons.plus, color: Colors.white70, size: 18),
                onPressed: () => setState(() {
                  if (_zoom < 2.5) _zoom += 0.1;
                }),
              ),
              const SizedBox(width: 14),
              // Fit width / Reset Zoom
              IconButton(
                icon: const Icon(LucideIcons.maximize2, color: Colors.white70, size: 18),
                onPressed: () => setState(() {
                  _zoom = 1.0;
                }),
              ),
              const SizedBox(width: 14),
              // Rotate CW
              IconButton(
                icon: const Icon(LucideIcons.rotateCw, color: Colors.white70, size: 18),
                onPressed: () => setState(() {
                  _rotation = (_rotation + 90) % 360;
                }),
              ),
              const SizedBox(width: 14),
              // Pen tool
              IconButton(
                icon: Icon(
                  LucideIcons.penTool,
                  color: _penActive ? AppTheme.primaryBlue : Colors.white70,
                  size: 18,
                ),
                onPressed: () => setState(() {
                  _penActive = !_penActive;
                }),
              ),
              const SizedBox(width: 14),
              // Undo last stroke
              IconButton(
                icon: Icon(
                  LucideIcons.undo2,
                  color: _strokes.isNotEmpty ? Colors.white70 : Colors.white38,
                  size: 18,
                ),
                onPressed: () => setState(() {
                  if (_strokes.isNotEmpty) {
                    _strokes.removeLast();
                  }
                }),
              ),
              const SizedBox(width: 20),
              // Summarize
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.sparkles, color: Colors.yellow, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'Summarize',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.printer, color: Colors.white70, size: 20),
                onPressed: () => _handlePrint(widget.doc),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(LucideIcons.download, color: Colors.white70, size: 20),
                onPressed: () => _handleDownload(widget.doc),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(LucideIcons.share2, color: Colors.white70, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // ── 3. Main Workspace (Enlarged components) ──────────────────────────
        Expanded(
          child: Row(
            children: [
              // Left thumbnail list
              if (_sidebarVisible)
                Container(
                  width: 220,
                  color: const Color(0xFF1E222B),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          height: 160,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Text(
                            'Quotation',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('1', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              // Right scrollable quotation render sheet
              Expanded(
                child: Container(
                  color: const Color(0xFF0F1115),
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: Center(
                      child: Transform.rotate(
                        angle: _rotation * math.pi / 180,
                        child: Transform.scale(
                          scale: _zoom,
                          child: GestureDetector(
                            onPanStart: (details) {
                              if (_penActive) {
                                final localPos = details.localPosition;
                                setState(() {
                                  _currentPoints = [localPos];
                                  _strokes.add(Stroke(
                                    points: _currentPoints,
                                    color: _activeTool == 'eraser' ? Colors.white : _strokeColor,
                                    width: _strokeWidth,
                                    isHighlighter: _activeTool == 'highlighter',
                                  ));
                                });
                              }
                            },
                            onPanUpdate: (details) {
                              if (_penActive) {
                                final localPos = details.localPosition;
                                setState(() {
                                  _currentPoints.add(localPos);
                                });
                              }
                            },
                            child: CustomPaint(
                              foregroundPainter: _SignaturePainter(_strokes),
                              child: Container(
                                width: 860,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                                  ],
                                ),
                                padding: const EdgeInsets.all(50),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Invoice Sheet Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 140,
                                              height: 60,
                                              color: const Color(0xFF1A1D24),
                                              alignment: Alignment.center,
                                              child: const Text(
                                                'LOGO',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            const Text(
                                              'YOUR COMPANY',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: const [
                                            Text(
                                              'QUOTATION',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Quote# QT-000003',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 50),
                                    // Details block
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _infoRow('Date:', '20-04-2026'),
                                            _infoRow('Status:', 'Accepted'),
                                            _infoRow('Salesperson:', 'ALTHAF'),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            _infoRowRight('Customer:', 'CUS-1'),
                                            _infoRowRight('Email:', 'zabnixprivatelimited@gmail.com'),
                                            _infoRowRight('Location:', 'ZABNIX PRIVATE LIMITED'),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                    // Items table
                                    Table(
                                      border: const TableBorder(
                                        horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
                                        bottom: BorderSide(color: Color(0xFFD1D5DB)),
                                      ),
                                      columnWidths: const {
                                        0: FlexColumnWidth(4),
                                        1: FlexColumnWidth(1),
                                        2: FlexColumnWidth(1.5),
                                        3: FlexColumnWidth(1.5),
                                      },
                                      children: [
                                        // Table Header
                                        const TableRow(
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF9FAFB),
                                            border: Border(
                                              top: BorderSide(color: Color(0xFFD1D5DB)),
                                              bottom: BorderSide(color: Color(0xFFD1D5DB)),
                                            ),
                                          ),
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                              child: Text(
                                                'Item & Description',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                              child: Text(
                                                'Qty',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                              child: Text(
                                                'Rate',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                              child: Text(
                                                'Amount',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Table Row 1
                                        TableRow(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'BATCH TARCK ITEM',
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'sales description demo txt',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                              child: Text('10 pcs', style: TextStyle(fontSize: 14)),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                              child: Text('₹199.00', style: TextStyle(fontSize: 14)),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                              child: Text('₹1,990.00', style: TextStyle(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    // Totals right aligned block
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                        width: 300,
                                        child: Column(
                                          children: [
                                            _totalRow('Sub Total', '₹1,990.00'),
                                            _totalRow('CGST', '₹49.75'),
                                            _totalRow('SGST', '₹49.75'),
                                            _totalRow('Round Off', '₹0.50'),
                                            const Divider(color: Colors.grey),
                                            _totalRow('Total', '₹2,090.00', isBold: true),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 60),
                                    // Notes
                                    const Text(
                                      'Notes:',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Looking forward for your business.',
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Right Draw Settings Sidebar (Matching screenshot layout)
              if (_penActive)
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E222B),
                    border: Border(left: BorderSide(color: Colors.black26)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Draw Tools (Pen, Highlighter, Eraser)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildToolButton('pen', LucideIcons.penTool),
                            _buildToolButton('highlighter', LucideIcons.edit3),
                            _buildToolButton('eraser', LucideIcons.eraser),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      // Size Label & Diagonal Stroke Options
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Size',
                              style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStrokeWidthButton(1.0),
                                _buildStrokeWidthButton(2.0),
                                _buildStrokeWidthButton(4.0),
                                _buildStrokeWidthButton(8.0),
                                _buildStrokeWidthButton(12.0),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      // Color Label & Color circles grid
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Color',
                                style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: 20,
                                  itemBuilder: (context, index) {
                                    final row = index ~/ 5;
                                    final col = index % 5;
                                    final Color colValue = _colorPalette[row][col];
                                    final bool isSelected = _strokeColor == colValue;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _strokeColor = colValue;
                                          if (_activeTool == 'eraser') {
                                            _activeTool = 'pen';
                                          }
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colValue,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryBlue
                                                : (colValue == Colors.white ? Colors.white30 : Colors.transparent),
                                            width: isSelected ? 3.0 : 1.0,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton(String toolName, IconData icon) {
    final bool isSelected = _activeTool == toolName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTool = toolName;
        });
      },
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildStrokeWidthButton(double width) {
    final bool isSelected = _strokeWidth == width;
    return GestureDetector(
      onTap: () {
        setState(() {
          _strokeWidth = width;
        });
      },
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: -math.pi / 4,
          child: Container(
            width: 18,
            height: width.clamp(1.5, 6.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoRowRight(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: label.startsWith('Email') || label.startsWith('Location')
                  ? AppTheme.primaryBlue
                  : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.textPrimary : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Stroke> strokes;

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.isHighlighter ? stroke.color.withValues(alpha: 0.35) : stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

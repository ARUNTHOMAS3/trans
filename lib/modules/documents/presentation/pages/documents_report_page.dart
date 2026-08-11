import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/documents/documents_providers.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/documents/presentation/widgets/new_folder_dialog.dart';
import 'package:zerpai_erp/modules/documents/presentation/widgets/email_receipts_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/modules/documents/presentation/widgets/document_preview_dialog.dart';
import 'package:zerpai_erp/shared/widgets/tables/zerpai_pagination_widget.dart';

class DocumentsOverviewPage extends ConsumerStatefulWidget {
  const DocumentsOverviewPage({super.key});

  @override
  ConsumerState<DocumentsOverviewPage> createState() => _DocumentsOverviewPageState();
}

class _DocumentsOverviewPageState extends ConsumerState<DocumentsOverviewPage> {
  // Mock data for All Documents
  final List<Map<String, dynamic>> _allDocuments = [
    {
      'fileName': 'QT-000003.pdf',
      'fileType': 'pdf',
      'uploadedBy': 'Me',
      'uploadedOn': '28-07-2026 11:21 AM',
      'associatedType': 'Quote',
      'associatedNumber': 'QT-000003',
      'status': null,
    },
    {
      'fileName': 'EXPENSE-00002 (1).pdf',
      'fileType': 'pdf',
      'uploadedBy': 'Me',
      'uploadedOn': '04-07-2026 12:29 PM',
      'associatedType': null,
      'associatedNumber': null,
      'status': 'Processed',
    },
    {
      'fileName': 'EXPENSE-00012.pdf',
      'fileType': 'pdf',
      'uploadedBy': 'Me',
      'uploadedOn': '04-07-2026 12:27 PM',
      'associatedType': null,
      'associatedNumber': null,
      'status': 'Processed',
    },
    {
      'fileName': 'customerpayments.pdf',
      'fileType': 'pdf',
      'uploadedBy': 'Me',
      'uploadedOn': '10-06-2026 05:28 PM',
      'associatedType': 'Customer Payment',
      'associatedNumber': '306',
      'status': null,
    },
    {
      'fileName': 'Screenshot 2026-06-03 150023.png',
      'fileType': 'image',
      'uploadedBy': 'Me',
      'uploadedOn': '06-06-2026 01:51 PM',
      'associatedType': null,
      'associatedNumber': null,
      'status': 'Unreadable',
    },
    {
      'fileName': 'WhatsApp Image 2026-08-05 at 3.37.57.png',
      'fileType': 'image',
      'uploadedBy': 'Me',
      'uploadedOn': '05-08-2026 08:14 PM',
      'associatedType': 'Customer Payment',
      'associatedNumber': '300',
      'status': null,
    },
  ];

  // Mock data for Inbox (Files with extracted autoscan Details)
  final List<Map<String, dynamic>> _inboxDocuments = [
    {
      'fileName': 'EXPENSE-00002 (1).pdf',
      'fileType': 'pdf',
      'uploadedBy': 'Me',
      'uploadedOn': '04-07-2026 12:29 PM',
      'status': 'Processed',
      'amount': '₹120.00',
      'vendor': 'STARLEX HEALTHCARE PVT. LTD.',
      'date': '25-06-2026',
      'ref': null,
    },
    {
      'fileName': 'EXPENSE-00012.pdf',
      'fileType': 'pdf',
      'uploadedBy': 'Me',
      'uploadedOn': '04-07-2026 12:27 PM',
      'status': 'Processed',
      'amount': '₹200.00',
      'vendor': 'STARLEX HEALTHCARE PVT. LTD.',
      'date': '02-07-2026',
      'ref': null,
    },
    {
      'fileName': 'Screenshot 2026-06-03 150023.png',
      'fileType': 'image',
      'uploadedBy': 'Me',
      'uploadedOn': '06-06-2026 01:51 PM',
      'status': 'Unreadable',
      'amount': null,
      'vendor': null,
      'date': null,
      'ref': null,
    },
    {
      'fileName': 'Screenshot 2025-11-12 213929.png',
      'fileType': 'image',
      'uploadedBy': 'Me',
      'uploadedOn': '16-01-2026 02:49 PM',
      'status': null,
      'amount': null,
      'vendor': null,
      'date': null,
      'ref': null,
    },
    {
      'fileName': '226490.pdf',
      'fileType': 'pdf',
      'uploadedBy': 'Me',
      'uploadedOn': '06-05-2025 05:35 PM',
      'status': 'Processed',
      'amount': '₹277.68',
      'vendor': 'STARLEX HEALTH SERVICES AND PRODUCTS PVT LTD',
      'date': '17-02-2025',
      'ref': 'S/24-25/226490',
    },
    {
      'fileName': 'sample_bills.csv',
      'fileType': 'csv',
      'uploadedBy': 'Me',
      'uploadedOn': '02-05-2025 12:16 PM',
      'status': null,
      'amount': null,
      'vendor': null,
      'date': null,
      'ref': null,
    },
  ];

  // Mock data for Trash
  final List<Map<String, dynamic>> _trashDocuments = [
    {
      'fileName': 'sample_bills.csv',
      'fileType': 'csv',
      'uploadedBy': 'Me',
      'uploadedOn': '02-05-2025 11:33 AM',
    },
    {
      'fileName': '29-04-2025.xlsx',
      'fileType': 'excel',
      'uploadedBy': 'Me',
      'uploadedOn': '02-05-2025 11:18 AM',
    },
    {
      'fileName': 'WhatsApp Image 2023-12-27 at 11.48.53 AM.jpeg',
      'fileType': 'image',
      'uploadedBy': 'Me',
      'uploadedOn': '28-02-2025 06:56 PM',
    },
    {
      'fileName': 'WhatsApp Image 2024-04-19 at 10.16.33 AM (2).jpeg',
      'fileType': 'image',
      'uploadedBy': 'Me',
      'uploadedOn': '28-02-2025 06:54 PM',
    },
  ];

  String _selectedFileType = 'All';
  String _selectedStatus = 'All';
  bool _selectAll = false;
  final Set<int> _selectedRows = {};
  String _sortBy = 'Uploaded On';
  String _sortColumn = 'uploadedOn';
  bool _sortAscending = false;
  String? _hoveredHeaderColumn;
  Map<String, dynamic>? _selectedDocument;
  int? _hoveredRowIndex;
  int? _openMenuRowIndex;
  int _currentPage = 1;
  int _pageSize = 10;





  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    if (status == 'Processed') {
      bg = const Color(0xFFE6F4EA);
      fg = const Color(0xFF137333);
    } else if (status == 'Unreadable') {
      bg = const Color(0xFFFCE8E6);
      fg = const Color(0xFFC5221F);
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read filter route parameter from URL
    final state = GoRouterState.of(context);
    final String filter = state.uri.queryParameters['filter'] ?? 'all';
    final bool isInbox = filter == 'inbox';
    final bool isFolder = filter == 'folder';
    final bool isTrash = filter == 'trash';
    final String folderName = state.uri.queryParameters['name'] ?? 'Folder';

    var documentsList = isInbox
        ? _inboxDocuments
        : (isFolder
            ? <Map<String, dynamic>>[]
            : (isTrash ? _trashDocuments : _allDocuments));

    // Apply Status Filter (for Inbox)
    if (isInbox && _selectedStatus != 'All') {
      documentsList = documentsList.where((doc) {
        final status = doc['status'];
        if (_selectedStatus == 'Scan Completed') {
          return status == 'Processed';
        } else if (_selectedStatus == 'Scan Failed') {
          return status == 'Unreadable';
        } else if (_selectedStatus == 'Scan In Progress') {
          return status == 'Scan In Progress';
        }
        return true;
      }).toList();
    }

    // Apply File Type Filter (for All Documents)
    if (!isInbox && _selectedFileType != 'All') {
      documentsList = documentsList.where((doc) {
        final name = (doc['fileName'] as String).toLowerCase();
        if (_selectedFileType == 'PDF') {
          return name.endsWith('.pdf');
        } else if (_selectedFileType == 'Images') {
          return name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg');
        } else if (_selectedFileType == 'Docs') {
          return name.endsWith('.docx') || name.endsWith('.doc') || name.endsWith('.txt');
        } else if (_selectedFileType == 'Sheets') {
          return name.endsWith('.xlsx') || name.endsWith('.xls') || name.endsWith('.csv');
        }
        return true;
      }).toList();
    }

    // Sort documentsList by active column
    documentsList = List<Map<String, dynamic>>.from(documentsList);
    documentsList.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'fileName':
          cmp = (a['fileName'] as String).toLowerCase()
              .compareTo((b['fileName'] as String).toLowerCase());
          break;
        case 'uploadedBy':
          cmp = (a['uploadedBy'] as String? ?? '').toLowerCase()
              .compareTo((b['uploadedBy'] as String? ?? '').toLowerCase());
          break;
        case 'folder':
          cmp = (a['folderName'] as String? ?? '').toLowerCase()
              .compareTo((b['folderName'] as String? ?? '').toLowerCase());
          break;
        case 'uploadedOn':
        default:
          cmp = (a['uploadedOn'] as String? ?? '')
               .compareTo(b['uploadedOn'] as String? ?? '');
      }
      return _sortAscending ? cmp : -cmp;
    });

    final totalItems = documentsList.length;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize) > totalItems ? totalItems : (startIndex + _pageSize);
    final paginatedDocuments = totalItems == 0 ? <Map<String, dynamic>>[] : documentsList.sublist(startIndex, endIndex);

    // Keep sidebar badge in sync with actual inbox count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsInboxCountProvider.notifier).state = _inboxDocuments.length;
    });

    return ZerpaiLayout(
      pageTitle: isFolder
          ? folderName
          : (isInbox ? 'Files' : (isTrash ? 'Trash' : 'All Documents')),
      useHorizontalPadding: false,
      useTopPadding: false,
      enableBodyScroll: false,
      titleWidget: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: isFolder
            ? Text(
                folderName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              )
            : (isInbox
                ? const Text(
                    'Files',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  )
                : (isTrash
                    ? const Text(
                        'Trash',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      )
                    : const Text(
                        'All Documents',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ))),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInbox) ...[
                // Available Autoscans Button (dropdown info panel)
                _AutoscansDropdown(),
                const SizedBox(width: 8),
                // Configure Button
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => EmailReceiptsDialog.show(context),
                    icon: Icon(LucideIcons.mail, size: 13, color: Colors.blue.shade700),
                    label: Text(
                      'Configure',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Use Advanced Autoscan tooltip/badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.lightbulb, size: 14, color: Colors.yellow.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'Use Advanced Autoscan.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 2),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {},
                      child: Text(
                        'Buy Addon \u25b8',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              // Trash actions: Empty Trash + Restore All
              if (isTrash) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {},
                  icon: const Icon(LucideIcons.trash2, size: 14),
                  label: const Text('Empty Trash'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {},
                  icon: const Icon(LucideIcons.rotateCcw, size: 14),
                  label: const Text('Restore All'),
                ),
              ] else
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {},
                      child: const Text('Upload File'),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                      indent: 6,
                      endIndent: 6,
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                      ),
                      child: PopupMenuButton<String>(
                        offset: const Offset(20, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        color: Colors.white,
                        elevation: 4,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 180, maxWidth: 180),
                        icon: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.white),
                        itemBuilder: (ctx) => [
                          PopupMenuItem<String>(
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: UploadMenuItem(
                              label: 'Attach From Desktop',
                              onTap: () {
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ),
                          PopupMenuItem<String>(
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: UploadMenuItem(
                              label: 'Attach From Cloud',
                              onTap: () {
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isTrash) ...[
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  width: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade50,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                    ),
                    child: PopupMenuButton<String>(
                      offset: const Offset(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),
                      icon: const Icon(LucideIcons.moreVertical, size: 18),
                      itemBuilder: (ctx) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 4),
                          child: const Text(
                            'SORT BY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          padding: EdgeInsets.zero,
                          height: 36,
                          child: SortMenuItem(
                            label: 'File Name',
                            isSelected: _sortBy == 'File Name',
                            showArrow: _sortBy == 'File Name',
                            isAscending: _sortAscending,
                            onTap: () {
                              setState(() {
                                if (_sortColumn == 'fileName') {
                                  _sortAscending = !_sortAscending;
                                } else {
                                  _sortColumn = 'fileName';
                                  _sortAscending = true;
                                }
                                _sortBy = 'File Name';
                              });
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                        PopupMenuItem<String>(
                          padding: EdgeInsets.zero,
                          height: 36,
                          child: SortMenuItem(
                            label: 'Uploaded By',
                            isSelected: _sortBy == 'Uploaded By',
                            showArrow: _sortBy == 'Uploaded By',
                            isAscending: _sortAscending,
                            onTap: () {
                              setState(() {
                                if (_sortColumn == 'uploadedBy') {
                                  _sortAscending = !_sortAscending;
                                } else {
                                  _sortColumn = 'uploadedBy';
                                  _sortAscending = true;
                                }
                                _sortBy = 'Uploaded By';
                              });
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                        PopupMenuItem<String>(
                          padding: EdgeInsets.zero,
                          height: 36,
                          child: SortMenuItem(
                            label: 'Uploaded On',
                            isSelected: _sortBy == 'Uploaded On',
                            showArrow: _sortBy == 'Uploaded On',
                            isAscending: _sortAscending,
                            onTap: () {
                              setState(() {
                                if (_sortColumn == 'uploadedOn') {
                                  _sortAscending = !_sortAscending;
                                } else {
                                  _sortColumn = 'uploadedOn';
                                  _sortAscending = true;
                                }
                                _sortBy = 'Uploaded On';
                              });
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                        PopupMenuItem<String>(
                          padding: EdgeInsets.zero,
                          height: 36,
                          child: SortMenuItem(
                            label: 'Folder',
                            isSelected: _sortBy == 'Folder',
                            showArrow: _sortBy == 'Folder',
                            isAscending: _sortAscending,
                            onTap: () {
                              setState(() {
                                if (_sortColumn == 'folder') {
                                  _sortAscending = !_sortAscending;
                                } else {
                                  _sortColumn = 'folder';
                                  _sortAscending = true;
                                }
                                _sortBy = 'Folder';
                              });
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                        PopupMenuItem<String>(
                          enabled: false,
                          padding: EdgeInsets.zero,
                          child: const Divider(height: 1, color: AppTheme.borderColor),
                        ),
                        PopupMenuItem<String>(
                          padding: EdgeInsets.zero,
                          height: 44,
                          child: ExportMenuButton(
                            onTap: () {
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner for Autoscan limits on Inbox Route
            if (isInbox)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: const Color(0xFFFEF7E0),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: Color(0xFFB06000), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          children: [
                            const TextSpan(
                              text: 'All the purchased autoscans have been used. To continue auto-scanning receipts ',
                            ),
                            WidgetSpan(
                              child: InkWell(
                                onTap: () {},
                                child: const Text(
                                  '\u200d\ud83d\uded2 Buy Autoscan Addon \u25b8',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB06000),
                                    decoration: TextDecoration.underline,
                                  ),
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
            // Filter Bar or Bulk Action Ribbon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: _selectedRows.isNotEmpty
                  ? Row(
                      children: [
                        // Trash bin button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRows.clear();
                            });
                          },
                          child: Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade50,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.trash2, size: 14, color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Move to dropdown button
                        Theme(
                          data: Theme.of(context).copyWith(
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                          ),
                          child: PopupMenuButton<String>(
                            offset: const Offset(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: AppTheme.borderColor),
                            ),
                            color: Colors.white,
                            elevation: 6,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey.shade50,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Move to',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.textSecondary),
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
                                        content: Text('Moved ${_selectedRows.length} documents to ' + folderName),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    setState(() {
                                      _selectedRows.clear();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add to green button
                        Theme(
                          data: Theme.of(context).copyWith(
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                          ),
                          child: PopupMenuButton<String>(
                            offset: const Offset(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: AppTheme.borderColor),
                            ),
                            color: Colors.white,
                            elevation: 6,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Add to',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(LucideIcons.chevronDown, size: 12, color: Colors.white),
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
                        const Spacer(),
                        // Close button (x)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.textSecondary),
                          onPressed: () {
                            setState(() {
                              _selectedRows.clear();
                            });
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Text(
                          'Filter By :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isInbox ? 'Status:' : 'File Type:',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isInbox)
                          Theme(
                            data: Theme.of(context).copyWith(
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                            ),
                            child: PopupMenuButton<String>(
                              offset: const Offset(0, 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: AppTheme.borderColor),
                              ),
                              color: Colors.white,
                              elevation: 4,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 160, maxWidth: 160),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedStatus,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textPrimary),
                                ],
                              ),
                              onSelected: (val) {
                                setState(() => _selectedStatus = val);
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem<String>(
                                  value: 'All',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'All',
                                    isSelected: _selectedStatus == 'All',
                                    onTap: () {
                                      Navigator.of(ctx).pop('All');
                                    },
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Scan In Progress',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'Scan In Progress',
                                    isSelected: _selectedStatus == 'Scan In Progress',
                                    onTap: () {
                                      Navigator.of(ctx).pop('Scan In Progress');
                                    },
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Scan Completed',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'Scan Completed',
                                    isSelected: _selectedStatus == 'Scan Completed',
                                    onTap: () {
                                      Navigator.of(ctx).pop('Scan Completed');
                                    },
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Scan Failed',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'Scan Failed',
                                    isSelected: _selectedStatus == 'Scan Failed',
                                    onTap: () {
                                      Navigator.of(ctx).pop('Scan Failed');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Theme(
                            data: Theme.of(context).copyWith(
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                            ),
                            child: PopupMenuButton<String>(
                              offset: const Offset(0, 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: AppTheme.borderColor),
                              ),
                              color: Colors.white,
                              elevation: 4,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 160, maxWidth: 160),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedFileType,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textPrimary),
                                ],
                              ),
                              onSelected: (val) {
                                setState(() => _selectedFileType = val);
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem<String>(
                                  value: 'All',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'All',
                                    isSelected: _selectedFileType == 'All',
                                    onTap: () {
                                      Navigator.of(ctx).pop('All');
                                    },
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Images',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'Images',
                                    isSelected: _selectedFileType == 'Images',
                                    onTap: () {
                                      Navigator.of(ctx).pop('Images');
                                    },
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'PDF',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'PDF',
                                    isSelected: _selectedFileType == 'PDF',
                                    onTap: () {
                                      Navigator.of(ctx).pop('PDF');
                                    },
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Docs',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'Docs',
                                    isSelected: _selectedFileType == 'Docs',
                                    onTap: () {
                                      Navigator.of(ctx).pop('Docs');
                                    },
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Sheets',
                                  padding: EdgeInsets.zero,
                                  height: 36,
                                  child: StatusFilterMenuItem(
                                    label: 'Sheets',
                                    isSelected: _selectedFileType == 'Sheets',
                                    onTap: () {
                                      Navigator.of(ctx).pop('Sheets');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            // High Density Table & Side Detail Pane
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                  columnWidths: isInbox
                      ? const {
                          0: FixedColumnWidth(48), // Checkbox
                          1: FlexColumnWidth(3),   // File Name
                          2: FlexColumnWidth(3),   // Details
                          3: FlexColumnWidth(1.2), // Uploaded By
                          4: FlexColumnWidth(2),   // Uploaded On
                          5: FixedColumnWidth(150), // Action Button
                        }
                      : (isFolder
                          ? const {
                              0: FixedColumnWidth(48), // Checkbox
                              1: FlexColumnWidth(3),   // File Name
                              2: FlexColumnWidth(1.5), // Uploaded By
                              3: FlexColumnWidth(2),   // Uploaded On
                              4: FlexColumnWidth(2),   // Associated To
                              5: FixedColumnWidth(100), // Search Icon
                            }
                          : const {
                              0: FixedColumnWidth(48), // Checkbox
                              1: FlexColumnWidth(3),   // File Name
                              2: FlexColumnWidth(1.5), // Uploaded By
                              3: FlexColumnWidth(2),   // Uploaded On
                              4: FlexColumnWidth(2),   // Associated To
                              5: FlexColumnWidth(1.5), // Folder
                              6: FixedColumnWidth(100), // Action Button
                            }),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  children: [
                    // Table Header Row
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                      ),
                      children: isInbox
                          ? [
                              _buildCheckboxHeader(),
                              _buildSortedHeaderCell('FILE NAME', 'fileName'),
                              _buildHeaderCell('DETAILS'),
                              _buildSortedHeaderCell('UPLOADED BY', 'uploadedBy'),
                              _buildSortedHeaderCell('UPLOADED ON', 'uploadedOn'),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(LucideIcons.search, size: 14),
                                      color: AppTheme.textSecondary,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        AdvancedSearchDialog.show(context);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          : [
                              _buildCheckboxHeader(),
                              _buildSortedHeaderCell('FILE NAME', 'fileName'),
                              _buildSortedHeaderCell('UPLOADED BY', 'uploadedBy'),
                              _buildSortedHeaderCell('UPLOADED ON', 'uploadedOn'),
                              _buildHeaderCell('ASSOCIATED TO'),
                              _buildHeaderCell('FOLDER'),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(LucideIcons.search, size: 14),
                                      color: AppTheme.textSecondary,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        AdvancedSearchDialog.show(context);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                    ),
                    // Table Body Rows
                    ...paginatedDocuments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      final isCheckboxSelected = _selectedRows.contains(index);
                      final isRowClicked = _selectedDocument != null && _selectedDocument!['fileName'] == doc['fileName'];
                      final isHovered = _hoveredRowIndex == index;
                      final isMenuOpen = _openMenuRowIndex == index;

                      return TableRow(
                        decoration: BoxDecoration(
                          color: isRowClicked
                              ? Colors.blue.shade50.withValues(alpha: 0.4)
                              : (isCheckboxSelected
                                  ? Colors.blue.shade50.withValues(alpha: 0.2)
                                  : ((isHovered || isMenuOpen)
                                      ? Colors.grey.shade50
                                      : Colors.transparent)),
                        ),
                        children: isInbox
                            ? [
                                _buildCheckboxBody(index, isCheckboxSelected),
                                // Inbox File Name with Icon & Badge
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                    onExit: (_) => setState(() => _hoveredRowIndex = null),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setState(() {
                                          _selectedDocument = doc;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  doc['fileType'] == 'pdf'
                                                      ? LucideIcons.fileText
                                                      : (doc['fileType'] == 'csv' ? LucideIcons.fileSpreadsheet : LucideIcons.image),
                                                  size: 16,
                                                  color: doc['fileType'] == 'pdf'
                                                      ? Colors.red.shade600
                                                      : (doc['fileType'] == 'csv' ? Colors.green.shade600 : Colors.blue.shade600),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    doc['fileName'],
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (doc['status'] != null) ...[
                                              const SizedBox(height: 4),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 24),
                                                child: _buildStatusBadge(doc['status']),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Extracted autoscan Details column
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                    onExit: (_) => setState(() => _hoveredRowIndex = null),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setState(() {
                                          _selectedDocument = doc;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: doc['amount'] != null
                                            ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    doc['amount'],
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Vendor: ${doc['vendor']}",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Date: ${doc['date']}",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                  if (doc['ref'] != null)
                                                    Text(
                                                      "Ref #: ${doc['ref']}",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                ],
                                              )
                                            : const Text(
                                                '-',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildBodyCell(
                                  doc['uploadedBy'],
                                  onTap: () {
                                    setState(() {
                                      _selectedDocument = doc;
                                    });
                                  },
                                  index: index,
                                ),
                                _buildBodyCell(
                                  doc['uploadedOn'],
                                  onTap: () {
                                    setState(() {
                                      _selectedDocument = doc;
                                    });
                                  },
                                  index: index,
                                ),
                                 // Hover Add to Expense Action Button
                                 TableCell(
                                   verticalAlignment: TableCellVerticalAlignment.middle,
                                   child: MouseRegion(
                                     onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                     onExit: (_) => setState(() => _hoveredRowIndex = null),
                                     child: Padding(
                                       padding: const EdgeInsets.symmetric(horizontal: 12),
                                       child: Align(
                                         alignment: Alignment.centerRight,
                                         child: (isHovered || isRowClicked || isMenuOpen)
                                             ? Theme(
                                                 data: Theme.of(context).copyWith(
                                                   hoverColor: Colors.transparent,
                                                   splashColor: Colors.transparent,
                                                 ),
                                                 child: PopupMenuButton<String>(
                                                   onOpened: () => setState(() => _openMenuRowIndex = index),
                                                   onCanceled: () => setState(() => _openMenuRowIndex = null),
                                                   onSelected: (_) => setState(() => _openMenuRowIndex = null),
                                                   offset: const Offset(0, 30),
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(6),
                                                     side: const BorderSide(color: AppTheme.borderColor),
                                                   ),
                                                   color: Colors.white,
                                                   elevation: 4,
                                                   padding: EdgeInsets.zero,
                                                   constraints: const BoxConstraints(minWidth: 180, maxWidth: 180),
                                                   child: Container(
                                                     height: 26,
                                                     decoration: BoxDecoration(
                                                       border: Border.all(color: AppTheme.borderColor),
                                                       borderRadius: BorderRadius.circular(4),
                                                       color: Colors.white,
                                                     ),
                                                     padding: const EdgeInsets.symmetric(horizontal: 8),
                                                     child: Row(
                                                       mainAxisSize: MainAxisSize.min,
                                                       children: const [
                                                         Text(
                                                           'Add to',
                                                           style: TextStyle(
                                                             fontSize: 13,
                                                             color: AppTheme.textPrimary,
                                                           ),
                                                         ),
                                                         SizedBox(width: 4),
                                                         Icon(
                                                           LucideIcons.chevronDown,
                                                           size: 10,
                                                           color: AppTheme.textSecondary,
                                                         ),
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
                                               )
                                             : const SizedBox(),
                                       ),
                                     ),
                                   ),
                                 ),
                              ]
                            : [
                                _buildCheckboxBody(index, isCheckboxSelected),
                                // All Documents File Name with Icon & Badge
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                    onExit: (_) => setState(() => _hoveredRowIndex = null),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setState(() {
                                          _selectedDocument = doc;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  doc['fileType'] == 'pdf'
                                                      ? LucideIcons.fileText
                                                      : LucideIcons.image,
                                                  size: 16,
                                                  color: doc['fileType'] == 'pdf'
                                                      ? Colors.red.shade600
                                                      : Colors.blue.shade600,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    doc['fileName'],
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (doc['status'] != null) ...[
                                              const SizedBox(height: 4),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 24),
                                                child: _buildStatusBadge(doc['status']),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildBodyCell(
                                  doc['uploadedBy'],
                                  onTap: () {
                                    setState(() {
                                      _selectedDocument = doc;
                                    });
                                  },
                                  index: index,
                                ),
                                _buildBodyCell(
                                  doc['uploadedOn'],
                                  onTap: () {
                                    setState(() {
                                      _selectedDocument = doc;
                                    });
                                  },
                                  index: index,
                                ),
                                // Associated Link
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                    onExit: (_) => setState(() => _hoveredRowIndex = null),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: doc['associatedType'] != null
                                          ? InkWell(
                                              onTap: () {},
                                              child: Text(
                                                "${doc['associatedType']}: ${doc['associatedNumber']}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.primaryBlue,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              '-',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                _buildBodyCell(
                                  '',
                                  onTap: () {
                                    setState(() {
                                      _selectedDocument = doc;
                                    });
                                  },
                                  index: index,
                                ), // Folder Column
                                // Hover Add Action Button
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                    onExit: (_) => setState(() => _hoveredRowIndex = null),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: (isHovered || isRowClicked || isMenuOpen)
                                            ? Theme(
                                                data: Theme.of(context).copyWith(
                                                  hoverColor: Colors.transparent,
                                                  splashColor: Colors.transparent,
                                                ),
                                                child: PopupMenuButton<String>(
                                                  onOpened: () => setState(() => _openMenuRowIndex = index),
                                                  onCanceled: () => setState(() => _openMenuRowIndex = null),
                                                  onSelected: (_) => setState(() => _openMenuRowIndex = null),
                                                  offset: const Offset(0, 30),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                    side: const BorderSide(color: AppTheme.borderColor),
                                                  ),
                                                  color: Colors.white,
                                                  elevation: 4,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 180, maxWidth: 180),
                                                  child: Container(
                                                    height: 26,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: AppTheme.borderColor),
                                                      borderRadius: BorderRadius.circular(4),
                                                      color: Colors.white,
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Text(
                                                          'Add to',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: AppTheme.textPrimary,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Icon(
                                                          LucideIcons.chevronDown,
                                                          size: 10,
                                                          color: AppTheme.textSecondary,
                                                        ),
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
                                              )
                                            : const SizedBox(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            if (_selectedDocument != null)
              isTrash
                  ? _buildTrashDetailPane(_selectedDocument!)
                  : _buildDetailPane(_selectedDocument!),
          ],
        ),
      ),
            if (isFolder && documentsList.isEmpty)
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    'No documents have been added',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ZerpaiPaginationWidget(
              totalItems: totalItems,
              currentPage: _currentPage,
              pageSize: _pageSize,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              onPageSizeChanged: (size) {
                setState(() {
                  _pageSize = size;
                  _currentPage = 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxHeader() {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(
            height: 16,
            width: 16,
            child: Checkbox(
              activeColor: AppTheme.primaryBlue,
              checkColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              value: _selectAll,
              onChanged: (val) {
                setState(() {
                  _selectAll = val ?? false;
                  if (_selectAll) {
                    _selectedRows.addAll(
                      Iterable<int>.generate(
                        _inboxDocuments.length,
                      ),
                    );
                  } else {
                    _selectedRows.clear();
                  }
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxBody(int index, bool isSelected) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredRowIndex = index),
        onExit: (_) => setState(() => _hoveredRowIndex = null),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              height: 16,
              width: 16,
              child: Checkbox(
                activeColor: AppTheme.primaryBlue,
                checkColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedRows.add(index);
                    } else {
                      _selectedRows.remove(index);
                      _selectAll = false;
                    }
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSortedHeaderCell(String label, String column) {
    final bool isActive = _sortColumn == column;
    final bool isHovered = _hoveredHeaderColumn == column;
    final bool showArrows = isActive || isHovered;
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredHeaderColumn = column),
        onExit: (_) => setState(() => _hoveredHeaderColumn = null),
        child: GestureDetector(
          onTap: () => setState(() {
            if (_sortColumn == column) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = column;
              _sortAscending = true;
            }
            // Sync _sortBy
            if (column == 'fileName') {
              _sortBy = 'File Name';
            } else if (column == 'uploadedBy') {
              _sortBy = 'Uploaded By';
            } else if (column == 'uploadedOn') {
              _sortBy = 'Uploaded On';
            } else if (column == 'folder') {
              _sortBy = 'Folder';
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                // Arrows: only visible on hover or when this column is active
                if (showArrows) ...[
                  const SizedBox(width: 4),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.chevronUp,
                        size: 9,
                        color: (isActive && _sortAscending)
                            ? AppTheme.primaryBlue
                            : AppTheme.textSecondary,
                      ),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 9,
                        color: (isActive && !_sortAscending)
                            ? AppTheme.primaryBlue
                            : AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyCell(String text, {VoidCallback? onTap, int? index}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: MouseRegion(
        onEnter: (_) {
          if (index != null) {
            setState(() => _hoveredRowIndex = index);
          }
        },
        onExit: (_) {
          if (index != null) {
            setState(() => _hoveredRowIndex = null);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              text.isEmpty ? '-' : text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Trash detail pane ─────────────────────────────────────────────────────
  Widget _buildTrashDetailPane(Map<String, dynamic> doc) {
    final String fileName = doc['fileName'] as String? ?? '';
    final String fileSize = doc['fileSize'] as String? ?? '1.5 KB';
    final String fileType = doc['fileType'] as String? ?? '';

    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header bar ────────────────────────────────────────────────
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                // Restore outlined button — white + shadow
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () {},
                    child: const Text('Restore'),
                  ),
                ),
                const SizedBox(width: 6),
                // Permanent delete icon button — white + shadow
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(LucideIcons.trash2, size: 13, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                ),
                const Spacer(),
                // Close X
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary),
                  onPressed: () => setState(() => _selectedDocument = null),
                ),
              ],
            ),
          ),
          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // filename · size
                  Text(
                    '$fileName · $fileSize',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // File preview card
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFileTypeIcon(fileType),
                              const SizedBox(height: 12),
                              Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        // Search loupe bottom-right
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: ZTooltip(
                            message: 'Zoom In',
                            direction: ZTooltipDirection.top,
                            child: GestureDetector(
                              onTap: () => DocumentPreviewDialog.show(context, doc),
                              behavior: HitTestBehavior.opaque,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(LucideIcons.zoomIn, size: 15, color: Colors.grey.shade400),
                              ),
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
        ],
      ),
    );
  }

  /// Renders the file-type icon badge (CSV, Excel, Image, PDF, generic).
  Widget _buildFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF28A745),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'CSV',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
        );
      case 'excel':
      case 'xlsx':
      case 'xls':
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF1D6F42),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'XLS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
        );
      case 'pdf':
        return Icon(LucideIcons.fileText, size: 64, color: Colors.red.shade600);
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icon(LucideIcons.image, size: 64, color: Colors.blue.shade600);
      default:
        return Icon(LucideIcons.file, size: 64, color: Colors.grey.shade400);
    }
  }

  Widget _buildDetailPane(Map<String, dynamic> doc) {
    final bool isPdf = doc['fileType'] == 'pdf';

    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Detail Pane Header Actions
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                // Move to dropdown button
                Theme(
                  data: Theme.of(context).copyWith(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    color: Colors.white,
                    elevation: 6,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade50,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Move to',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.textSecondary),
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
                const SizedBox(width: 8),
                // Add to green button
                Theme(
                  data: Theme.of(context).copyWith(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    color: Colors.white,
                    elevation: 6,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Add to',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(LucideIcons.chevronDown, size: 12, color: Colors.white),
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
                const SizedBox(width: 8),
                // Settings cog button
                Theme(
                  data: Theme.of(context).copyWith(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    color: Colors.white,
                    elevation: 6,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 140, maxWidth: 140),
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade50,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.settings, size: 14, color: AppTheme.textSecondary),
                    ),
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        padding: EdgeInsets.zero,
                        height: 32,
                        child: UploadMenuItem(
                          label: 'Rename',
                          onTap: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                      PopupMenuItem<String>(
                        padding: EdgeInsets.zero,
                        height: 32,
                        child: UploadMenuItem(
                          label: 'Delete',
                          onTap: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Close button (x)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary),
                  onPressed: () {
                    setState(() {
                      _selectedDocument = null;
                    });
                  },
                ),
              ],
            ),
          ),
          // Scrollable Preview area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: filename - size
                  Text(
                    "${doc['fileName']} - ${doc['fileSize'] ?? '4.7 KB'}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dotted Preview Box
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPdf ? LucideIcons.fileText : LucideIcons.image,
                                size: 64,
                                color: isPdf ? Colors.red.shade600 : Colors.blue.shade600,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                doc['fileName'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Zoom Icon (+) bottom-right
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: ZTooltip(
                            message: 'Zoom In',
                            direction: ZTooltipDirection.top,
                            child: GestureDetector(
                              onTap: () => DocumentPreviewDialog.show(context, doc),
                              behavior: HitTestBehavior.opaque,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(
                                  LucideIcons.zoomIn,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ASSOCIATED TO section
                  const Text(
                    'ASSOCIATED TO :',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          doc['associatedType'] ?? 'Quote',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Text(
                        doc['associatedNumber'] ?? doc['ref'] ?? 'QT-000003',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const UploadMenuItem({super.key, required this.label, required this.onTap});

  @override
  State<UploadMenuItem> createState() => _UploadMenuItemState();
}

class _UploadMenuItemState extends State<UploadMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) {
          setState(() {
            _isHovered = hovered;
          });
        },
        borderRadius: BorderRadius.circular(6),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: _isHovered ? Colors.white : AppTheme.textPrimary,
                fontWeight: _isHovered ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SortMenuItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool showArrow;
  final bool isAscending;
  final VoidCallback onTap;

  const SortMenuItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.showArrow,
    required this.isAscending,
    required this.onTap,
  });

  @override
  State<SortMenuItem> createState() => _SortMenuItemState();
}

class _SortMenuItemState extends State<SortMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _isHovered
        ? AppTheme.primaryBlue
        : (widget.isSelected ? Colors.grey.shade100 : Colors.transparent);
    final Color textColor = _isHovered ? Colors.white : AppTheme.textPrimary;
    final Color arrowColor = _isHovered ? Colors.white : AppTheme.primaryBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) {
          setState(() {
            _isHovered = hovered;
          });
        },
        borderRadius: BorderRadius.circular(4),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: _isHovered ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                if (widget.showArrow)
                  Icon(
                    widget.isAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                    size: 14,
                    color: arrowColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExportMenuButton extends StatefulWidget {
  final VoidCallback onTap;

  const ExportMenuButton({super.key, required this.onTap});

  @override
  State<ExportMenuButton> createState() => _ExportMenuButtonState();
}

class _ExportMenuButtonState extends State<ExportMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) {
          setState(() {
            _isHovered = hovered;
          });
        },
        borderRadius: BorderRadius.circular(4),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.upload,
                size: 14,
                color: _isHovered ? Colors.white : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'Export Document Details',
                style: TextStyle(
                  fontSize: 13,
                  color: _isHovered ? Colors.white : AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusFilterMenuItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const StatusFilterMenuItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<StatusFilterMenuItem> createState() => _StatusFilterMenuItemState();
}

class _StatusFilterMenuItemState extends State<StatusFilterMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _isHovered ? AppTheme.primaryBlue : Colors.transparent;
    final Color textColor = _isHovered ? Colors.white : AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) {
          setState(() {
            _isHovered = hovered;
          });
        },
        borderRadius: BorderRadius.circular(4),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdvancedSearchDialog extends StatefulWidget {
  const AdvancedSearchDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 0.0),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 750,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const AdvancedSearchDialog(),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  String _searchTarget = 'Documents';
  final TextEditingController _fileNameController = TextEditingController();
  String _transactionType = '';

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search Target Dropdown & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    height: 32,
                    child: FormDropdown<String>(
                      height: 32,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      value: _searchTarget,
                      items: const [
                        'Documents',
                        'Customers',
                        'Items',
                        'Composite Items',
                        'Batch',
                        'Assemblies',
                        'Price Lists',
                        'Inventory Adjustments',
                      ],
                      hint: 'Select Search Target',
                      showSearch: true,
                      allowClear: false,
                      alwaysShowClear: false,
                      showClearDivider: false,
                      displayStringForValue: (v) => v,
                      searchStringForValue: (v) => v,
                      onChanged: (val) {
                        if (val != null) setState(() => _searchTarget = val);
                      },
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Row 2: File Name Input & Transaction Type Dropdown side by side
          Row(
            children: [
              // File Name Field
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'File Name',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                  Container(
                    width: 220,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: TextField(
                        controller: _fileNameController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Transaction Type Field
              Row(
                children: [
                  const SizedBox(
                    width: 110,
                    child: Text(
                      'Transaction Type',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    height: 32,
                    child: FormDropdown<String>(
                      height: 32,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      value: _transactionType.isEmpty ? null : _transactionType,
                      items: const [
                        'Quote',
                        'Customer Payment',
                        'Retainer Payment',
                        'Payments Made',
                        'Customer',
                        'Vendor',
                        'Item',
                        'Account',
                      ],
                      hint: '',
                      showSearch: true,
                      allowClear: true,
                      alwaysShowClear: true,
                      showClearDivider: true,
                      displayStringForValue: (v) => v,
                      searchStringForValue: (v) => v,
                      onChanged: (val) {
                        setState(() => _transactionType = val ?? '');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Row 3: Action Buttons (Search & Cancel)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27C59A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MoveToDropdownContent extends StatefulWidget {
  final WidgetRef ref;
  final VoidCallback onNewFolderTap;
  final Function(String) onSelectFolder;

  const MoveToDropdownContent({
    required this.ref,
    required this.onNewFolderTap,
    required this.onSelectFolder,
  });

  @override
  State<MoveToDropdownContent> createState() => _MoveToDropdownContentState();
}

class _MoveToDropdownContentState extends State<MoveToDropdownContent> {
  String _searchQuery = '';
  final TextEditingController _controller = TextEditingController();
  bool _isInboxHovered = false;
  bool _isNewFolderHovered = false;
  String? _hoveredFolder;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folders = widget.ref.watch(documentsFoldersProvider);
    final filteredFolders = folders
        .where((f) => f.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3B82F6)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Type a folder name',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                          _controller.clear();
                        });
                      },
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          
          MouseRegion(
            onEnter: (_) => setState(() => _isInboxHovered = true),
            onExit: (_) => setState(() => _isInboxHovered = false),
            child: InkWell(
              onTap: () => widget.onSelectFolder('Inbox'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _isInboxHovered ? AppTheme.primaryBlue : Colors.transparent,
                child: Text(
                  'Inbox',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _isInboxHovered ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          
          if (filteredFolders.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 12, bottom: 6),
              child: Text(
                'FOLDERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...filteredFolders.map((folder) {
              final isHovered = _hoveredFolder == folder;
              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredFolder = folder),
                onExit: (_) => setState(() => _hoveredFolder = null),
                child: InkWell(
                  onTap: () => widget.onSelectFolder(folder),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isHovered ? AppTheme.primaryBlue : Colors.transparent,
                    child: Text(
                      folder,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isHovered ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          
          const Divider(height: 1, color: AppTheme.borderColor),
          
          MouseRegion(
            onEnter: (_) => setState(() => _isNewFolderHovered = true),
            onExit: (_) => setState(() => _isNewFolderHovered = false),
            child: InkWell(
              onTap: widget.onNewFolderTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _isNewFolderHovered ? AppTheme.primaryBlue : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: 14,
                      color: _isNewFolderHovered ? Colors.white : AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'New Folder',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _isNewFolderHovered ? Colors.white : AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Autoscans info dropdown — matches Zoho-style autoscans panel in screenshot
// ---------------------------------------------------------------------------
class _AutoscansDropdown extends StatefulWidget {
  const _AutoscansDropdown();

  @override
  State<_AutoscansDropdown> createState() => _AutoscansDropdownState();
}

class _AutoscansDropdownState extends State<_AutoscansDropdown> {
  // Mock data — replace with real provider values when wired
  final int _purchased = 1;
  final int _remaining = 0;
  final int _carryForwarded = 0;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 32),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black26,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _AutoscansPanel(
            purchased: _purchased,
            remaining: _remaining,
            carryForwarded: _carryForwarded,
          ),
        ),
      ],
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(4),
          color: Colors.blue.shade50.withValues(alpha: 0.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileText, size: 13, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(
              'Available Autoscans: $_remaining',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoscansPanel extends StatelessWidget {
  final int purchased;
  final int remaining;
  final int carryForwarded;

  const _AutoscansPanel({
    required this.purchased,
    required this.remaining,
    required this.carryForwarded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow('Purchased Monthly Auto-scans', purchased, isCount: true),
          _buildRow('Remaining Monthly Auto-scans', remaining, isGreen: remaining > 0),
          _buildRow('Carry-forwarded Auto-scans', carryForwarded, isGreen: carryForwarded > 0),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          // Purchase Add-ons link
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Purchase Add-ons',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 13, color: Colors.blue.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, int count, {bool isGreen = false, bool isCount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isGreen || (!isCount && count == 0)
                  ? const Color(0xFF22C55E)
                  : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

/// A reusable file upload button with an attached-file badge and popup overlay.
///
/// Usage:
/// ```dart
/// FileUploadButton(
///   files: myFileList,
///   onFilesChanged: (updated) => setState(() => myFileList = updated),
/// )
/// ```
///
/// - Always occupies 32 px in the layout (no overflow regardless of file count).
/// - Badge floats as an absolutely-positioned overlay on top-right — no layout shift.
/// - Self-contained overlay popup with per-file delete and hover interactions.
class FileUploadButton extends StatefulWidget {
  final List<PlatformFile> files;
  final ValueChanged<List<PlatformFile>> onFilesChanged;
  final double height;
  final List<String> allowedExtensions;
  final int maxFiles;

  const FileUploadButton({
    super.key,
    required this.files,
    required this.onFilesChanged,
    this.height = 34,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    this.maxFiles = 5,
  });

  @override
  State<FileUploadButton> createState() => _FileUploadButtonState();
}

class _FileUploadButtonState extends State<FileUploadButton> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  // ── File picking ──────────────────────────────────────────────────────────

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
      allowMultiple: true,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final remaining = widget.maxFiles - widget.files.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxFiles} files allowed')),
      );
      return;
    }

    final toAdd = result.files.take(remaining).toList();
    widget.onFilesChanged([...widget.files, ...toAdd]);
  }

  void _removeFile(int index) {
    final updated = List<PlatformFile>.from(widget.files)..removeAt(index);
    widget.onFilesChanged(updated);
    _removeOverlay();
  }

  // ── Overlay ───────────────────────────────────────────────────────────────

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _removeOverlay,
            behavior: HitTestBehavior.translucent,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.files
                      .asMap()
                      .entries
                      .map(
                        (e) => _FileListItem(
                          file: e.value,
                          onDelete: () => _removeFile(e.key),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasFiles = widget.files.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      // Layout footprint is always 32 px — badge floats to the right
      // via Positioned(left: 40) with Clip.none, so it never shifts layout.
      child: SizedBox(
        width: 32,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Upload icon button (always visible)
            ZTooltip(
              message: 'Attach documents (PDF/Image)',
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: _pickFiles,
                child: SizedBox(
                  width: 32,
                  height: widget.height,
                  child: const Center(
                    child: Icon(
                      LucideIcons.upload,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Badge pill — sits 8 px to the right of the upload icon,
            // same height, does not affect layout (clip: none + Positioned).
            if (hasFiles)
              Positioned(
                left: 40, // 32 px icon + 8 px gap
                top: 0,
                child: GestureDetector(
                  onTap: _toggleOverlay,
                  child: Material(
                    color: AppTheme.infoBlue,
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: _toggleOverlay,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: widget.height,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.paperclip,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.files.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

// ── File list item ──────────────────────────────────────────────────────────

class _FileListItem extends StatefulWidget {
  final PlatformFile file;
  final VoidCallback onDelete;

  const _FileListItem({required this.file, required this.onDelete});

  @override
  State<_FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<_FileListItem> {
  bool _isHovered = false;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get _fileIcon {
    final ext = widget.file.extension?.toLowerCase() ?? '';
    if (ext == 'pdf') return LucideIcons.fileText;
    if ({'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(ext)) {
      return LucideIcons.image;
    }
    return LucideIcons.file;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: _isHovered ? AppTheme.infoBlue : Colors.transparent,
        child: Row(
          children: [
            Icon(
              _fileIcon,
              size: 20,
              color: _isHovered ? Colors.white : AppTheme.infoBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isHovered ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'File size: ${_formatSize(widget.file.size)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isHovered ? Colors.white70 : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_isHovered)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

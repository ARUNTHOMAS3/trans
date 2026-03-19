part of '../items_item_create.dart';

extension _ItemCreateImages on _ItemCreateScreenState {
  Widget _buildImageUploadBox() {
    return DropTarget(
      onDragEntered: (_) => updateState(() => _isImageDragging = true),
      onDragExited: (_) => updateState(() => _isImageDragging = false),
      onDragDone: (details) {
        updateState(() => _isImageDragging = false);
        _onFilesDropped(details);
      },
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: _isImageDragging
              ? AppTheme.selectionActiveBg
              : const Color(0xFFFBFBFD),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _isImageDragging
                ? AppTheme.primaryBlue
                : const Color(0xFFD4D7E2),
            width: _isImageDragging ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: _itemImages.isEmpty
            ? InkWell(
                onTap: _pickItemImages,
                borderRadius: BorderRadius.circular(6),
                child: _emptyImageState(),
              )
            : Column(
                children: [
                  SizedBox(height: 148, child: _primaryImageView()),
                  const SizedBox(height: 8),
                  SizedBox(height: 22, child: _primaryStatusRow()),
                  const SizedBox(height: 8),
                  SizedBox(height: 48, child: _thumbnailStrip()),
                ],
              ),
      ),
    );
  }

  Widget _emptyImageState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.image_outlined, size: 42, color: AppTheme.textMuted),
        SizedBox(height: 12),
        Text(
          "Drag image(s) here or",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
        SizedBox(height: 4),
        Text(
          "Browse images",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF1B8EF1),
            decoration: TextDecoration.underline,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Maximum 15 images, each up to 5MB.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _primaryImageView() {
    if (_primaryImageIndex >= _itemImages.length) {
      _primaryImageIndex = 0;
    }
    final image = _itemImages[_primaryImageIndex];
    bool isHovering = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return MouseRegion(
          onEnter: (_) => setLocalState(() => isHovering = true),
          onExit: (_) => setLocalState(() => isHovering = false),
          child: GestureDetector(
            onTap: () => _openImagePreview(startIndex: _primaryImageIndex),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: image is String
                      ? Image.network(
                          image,
                          height: 148,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _errorImagePlaceholder(),
                        )
                      : Image.memory(
                          (image as PlatformFile).bytes!,
                          height: 148,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                if (isHovering)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.search,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _errorImagePlaceholder() {
    return Container(
      color: AppTheme.bgDisabled,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _primaryStatusRow() {
    final bool isPrimary = _primaryImageIndex == 0;

    return Row(
      children: [
        if (isPrimary)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
                SizedBox(width: 6),
                Text(
                  "Primary",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successTextDark,
                  ),
                ),
              ],
            ),
          )
        else
          Material(
            color: AppTheme.infoBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                updateState(() {
                  final img = _itemImages.removeAt(_primaryImageIndex);
                  _itemImages.insert(0, img);
                  _primaryImageIndex = 0;
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  "Mark as Primary",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlueDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

        const Spacer(),

        // Delete icon
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              updateState(() {
                _itemImages.removeAt(_primaryImageIndex);
                if (_primaryImageIndex >= _itemImages.length &&
                    _itemImages.isNotEmpty) {
                  _primaryImageIndex = _itemImages.length - 1;
                } else if (_itemImages.isEmpty) {
                  _primaryImageIndex = 0;
                }
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _thumbnailStrip() {
    const double thumbSize = 48;
    const int maxThumbs = 3;

    final extraCount = _itemImages.length > maxThumbs
        ? _itemImages.length - maxThumbs
        : 0;

    final visible = _itemImages.take(maxThumbs).toList();

    return Row(
      children: [
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isActive = index == _primaryImageIndex;
              final img = visible[index];

              return InkWell(
                onTap: () => updateState(() => _primaryImageIndex = index),
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryBlueDark
                          : AppTheme.borderColor,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: img is String
                        ? Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _errorImagePlaceholder(),
                          )
                        : Image.memory(
                            (img as PlatformFile).bytes!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              );
            },
          ),
        ),

        if (extraCount > 0) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _openImagePreview(startIndex: maxThumbs),
            child: Container(
              width: thumbSize,
              height: thumbSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
                color: AppTheme.bgDisabled,
              ),
              child: Text(
                '+$extraCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(width: 8),

        InkWell(
          onTap: _pickItemImages,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(Icons.add, color: AppTheme.primaryBlueDark),
          ),
        ),
      ],
    );
  }

  void _openImagePreview({required int startIndex}) {
    if (_itemImages.isEmpty) return;

    int current = startIndex.clamp(0, _itemImages.length - 1);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Image preview',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (ctx, _, __) =>
          _ImagePreview(images: _itemImages, startIndex: current),
    );
  }
}

// ============================================================================
// Image Preview Dialog Widget
// ============================================================================

class _ImagePreview extends StatefulWidget {
  final List<dynamic> images;
  final int startIndex;

  const _ImagePreview({required this.images, required this.startIndex});

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.images[_currentIndex];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Main image display
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: currentImage is String
                  ? Image.network(currentImage, fit: BoxFit.contain)
                  : Image.memory(
                      (currentImage as PlatformFile).bytes!,
                      fit: BoxFit.contain,
                    ),
            ),
          ),

          // Top bar with close button and counter
          Positioned(
            top: 24,
            right: 24,
            child: Row(
              children: [
                // Image counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Close button
                Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Left navigation arrow
          if (_currentIndex > 0)
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _previousImage,
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Right navigation arrow
          if (_currentIndex < widget.images.length - 1)
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _nextImage,
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 32,
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

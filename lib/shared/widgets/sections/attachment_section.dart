import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';

class AttachmentSection extends StatelessWidget {
  const AttachmentSection({
    super.key,
    required this.title,
    required this.files,
    required this.onFilesChanged,
    this.helperText = 'You can upload a maximum of 5 files, 10MB each',
    this.maxFiles = 5,
    this.allowedExtensions = const <String>['pdf', 'jpg', 'jpeg', 'png'],
    this.titleFontSize = 12,
    this.helperFontSize = 12,
  });

  final String title;
  final List<PlatformFile> files;
  final ValueChanged<List<PlatformFile>> onFilesChanged;
  final String helperText;
  final int maxFiles;
  final List<String> allowedExtensions;
  final double titleFontSize;
  final double helperFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        FileUploadButton(
          files: files,
          onFilesChanged: onFilesChanged,
          maxFiles: maxFiles,
          allowedExtensions: allowedExtensions,
          variant: FileUploadButtonVariant.button,
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: TextStyle(
            fontSize: helperFontSize,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

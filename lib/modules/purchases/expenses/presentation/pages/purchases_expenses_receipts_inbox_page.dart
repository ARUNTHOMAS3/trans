import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class ExpensesReceiptsInboxPage extends StatefulWidget {
  const ExpensesReceiptsInboxPage({super.key});

  @override
  State<ExpensesReceiptsInboxPage> createState() =>
      _ExpensesReceiptsInboxPageState();
}

class _ExpensesReceiptsInboxPageState extends State<ExpensesReceiptsInboxPage> {
  Future<void> _pickUploadExpenseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final names = result.files.map((file) => file.name).join(', ');
        ZerpaiToast.success(context, 'Receipt uploaded: $names');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error selecting file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _tabItem('Receipts Inbox', isActive: true, onTap: () {}),
                  const SizedBox(width: 28),
                  _tabItem(
                    'Expenses',
                    isActive: false,
                    onTap: () => context.go('/$orgId${AppRoutes.expenses}'),
                  ),
                  const Spacer(),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.selectionActiveBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          LucideIcons.receipt,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Available Receipt Scans:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '50/50',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 950),
                          child: DottedBorder(
                            color: AppTheme.borderColor,
                            strokeWidth: 1,
                            dashPattern: const [6, 4],
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 76,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTheme.warningOrange,
                                          AppTheme.warningBg,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.uploadCloud,
                                      size: 44,
                                      color: AppTheme.backgroundColor,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  const Text(
                                    'Drag & Drop Files Here',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Upload your documents (Images, PDF, Docs or Sheets) here',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  ElevatedButton(
                                    onPressed: _pickUploadExpenseFile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: AppTheme.backgroundColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: const Text('Choose files to upload'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      color: AppTheme.bgLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 56,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Key Features of Document',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Wrap(
                            spacing: 48,
                            runSpacing: 32,
                            alignment: WrapAlignment.center,
                            children: const [
                              _FeatureCard(
                                icon: LucideIcons.scanLine,
                                title: 'Auto scan',
                                description:
                                    'Enable auto-scan to automatically capture data',
                              ),
                              _FeatureCard(
                                icon: LucideIcons.mail,
                                title: 'Mail-In',
                                description:
                                    'Have your clients directly mail documents to your account',
                              ),
                              _FeatureCard(
                                icon: LucideIcons.repeat2,
                                title: 'Convert',
                                description:
                                    'Convert scanned documents into transactions',
                              ),
                            ],
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
      ),
    );
  }

  Widget _tabItem(
    String text, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: AppTheme.primaryBlue, width: 3),
                )
              : null,
        ),
        child: Text(
          text,
          style: AppTextStyles.title.copyWith(
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, size: 28, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

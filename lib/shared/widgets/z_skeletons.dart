import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Standard box skeleton for Skeletonizer.
/// This widget provides a static structure that Skeletonizer will animate.
class ZBone extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;

  const ZBone({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 4.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Generic Form Skeleton Structure (Label + Field rows)
class ZFormSkeleton extends StatelessWidget {
  final int rows;
  const ZFormSkeleton({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rows, (index) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space16),
        child: Row(
          children: [
            const ZBone(width: 150, height: 20),
            const SizedBox(width: AppTheme.space24),
            Expanded(child: const ZBone(height: 36)),
          ],
        ),
      )),
    );
  }
}

/// Generic List Skeleton Structure
class ZListSkeleton extends StatelessWidget {
  final int itemCount;
  const ZListSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            const ZBone(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ZBone(width: 200, height: 16),
                  const SizedBox(height: AppTheme.space8),
                  const ZBone(width: 120, height: 12),
                ],
              ),
            ),
            const ZBone(width: 60, height: 20),
          ],
        ),
      ),
    );
  }
}

/// Generic Table Skeleton Structure
class ZTableSkeleton extends StatelessWidget {
  final int rows;
  final int columns;
  const ZTableSkeleton({super.key, this.rows = 5, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          color: AppTheme.bgDisabled,
          child: Row(
            children: List.generate(columns, (index) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: const ZBone(height: 16),
              ),
            )),
          ),
        ),
        // Rows
        ...List.generate(rows, (index) => Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: List.generate(columns, (index) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: const ZBone(height: 14),
              ),
            )),
          ),
        )),
      ],
    );
  }
}

/// Detail Content Skeleton (for View Screens)
class ZDetailContentSkeleton extends StatelessWidget {
  const ZDetailContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ZBone(width: 300, height: 32),
          const SizedBox(height: AppTheme.space24),
          Row(
            children: [
              Expanded(child: const ZTableSkeleton(rows: 3, columns: 3)),
              const SizedBox(width: AppTheme.space24),
              const ZBone(width: 200, height: 200),
            ],
          ),
          const SizedBox(height: AppTheme.space32),
          const ZFormSkeleton(rows: 4),
        ],
      ),
    );
  }
}

/// Document Detail Skeleton (Invoice-like structure)
class ZDocumentDetailSkeleton extends StatelessWidget {
  const ZDocumentDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner
        const ZBone(height: 80),
        const SizedBox(height: AppTheme.space24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ZBone(width: 250, height: 100),
              const ZBone(width: 200, height: 100),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space32),
        // Items Table
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.space32),
          child: ZTableSkeleton(rows: 4, columns: 5),
        ),
        const SizedBox(height: AppTheme.space32),
        // Totals
        const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: AppTheme.space32),
            child: ZBone(width: 200, height: 120),
          ),
        ),
      ],
    );
  }
}

/// Sales Order Detail Skeleton
/// Action bar -> banner -> tabs -> status -> document card
class ZSalesOrderDetailSkeleton extends StatelessWidget {
  const ZSalesOrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ZBone(height: 56), // Action Bar
        Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            children: [
              const ZBone(height: 100), // Banner
              const SizedBox(height: AppTheme.space16),
              const ZBone(height: 48), // Tabs
              const SizedBox(height: AppTheme.space16),
              Row(
                children: [
                  const ZBone(width: 150, height: 20), // Status
                  const Spacer(),
                  const ZBone(width: 100, height: 20),
                ],
              ),
              const SizedBox(height: AppTheme.space24),
              const ZDocumentDetailSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Error Placeholder for Tables and Lists
class ZErrorPlaceholder extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? message;

  const ZErrorPlaceholder({
    super.key,
    required this.error,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: AppTheme.space16),
            Text(
              message ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.space24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

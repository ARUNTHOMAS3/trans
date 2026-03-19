import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 4,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? AppTheme.borderColor,
      highlightColor: highlightColor ?? AppTheme.bgDisabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              children: [
                const Skeleton(width: 180, height: 24),
                const SizedBox(width: 24),
                Expanded(child: const Skeleton(height: 34)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TableSkeleton extends StatelessWidget {
  final int rows;
  final int columns;

  const TableSkeleton({super.key, this.rows = 8, this.columns = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: List.generate(
              columns,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Skeleton(height: 16),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: rows,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppTheme.borderColor),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: List.generate(
                  columns,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Skeleton(height: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(width: 120, height: 20),
            const SizedBox(height: 16),
            const Skeleton(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const Skeleton(width: 200, height: 14),
          ],
        ),
      ),
    );
  }
}

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar Skeleton
          Container(
            width: 300,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Skeleton(height: 40),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Skeleton(width: 40, height: 40, borderRadius: 20),
                          SizedBox(width: 12),
                          Expanded(child: Skeleton(height: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Skeleton(width: 250, height: 32),
                      Row(
                        children: [
                          Skeleton(width: 80, height: 36),
                          SizedBox(width: 12),
                          Skeleton(width: 80, height: 36),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: List.generate(
                      4,
                      (index) => const Padding(
                        padding: EdgeInsets.only(right: 24),
                        child: Skeleton(width: 80, height: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Body
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: double.infinity, height: 200),
                        SizedBox(height: 24),
                        Skeleton(width: 200, height: 24),
                        SizedBox(height: 16),
                        Skeleton(width: double.infinity, height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;

  const ListSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: CardSkeleton(),
      ),
    );
  }
}

class DocumentDetailSkeleton extends StatelessWidget {
  const DocumentDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Skeleton(width: 80, height: 36),
              const SizedBox(width: 12),
              const Skeleton(width: 80, height: 36),
              const SizedBox(width: 12),
              const Skeleton(width: 120, height: 36),
            ],
          ),
          const SizedBox(height: 24),
          // Main Info Card
          const CardSkeleton(),
          const SizedBox(height: 24),
          // Table
          const TableSkeleton(rows: 5),
          const SizedBox(height: 24),
          // Summary
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Skeleton(width: 80, height: 16),
                      Skeleton(width: 60, height: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Skeleton(width: 80, height: 16),
                      Skeleton(width: 60, height: 16),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Skeleton(width: 80, height: 20),
                      Skeleton(width: 60, height: 20),
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

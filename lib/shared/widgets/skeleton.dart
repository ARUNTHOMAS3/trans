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
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 450) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 150, height: 20),
                      const SizedBox(height: 12),
                      const Skeleton(width: double.infinity, height: 34),
                    ],
                  );
                }
                return Row(
                  children: [
                    const Skeleton(width: 180, height: 24),
                    const SizedBox(width: 24),
                    Expanded(child: const Skeleton(height: 34)),
                  ],
                );
              },
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
  final bool showHeader;

  const TableSkeleton({
    super.key,
    this.rows = 8,
    this.columns = 5,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildHeader() => Padding(
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
    );

    Widget buildRow(int index) => Padding(
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;

        if (!hasBoundedHeight) {
          // Avoid Expanded/ListView inside unbounded-height parents (e.g. SingleChildScrollView).
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHeader) ...[
                buildHeader(),
                const Divider(height: 1, color: AppTheme.borderColor),
              ],
              ...List.generate(rows, (index) => buildRow(index)),
            ],
          );
        }

        return Column(
          children: [
            if (showHeader) ...[
              buildHeader(),
              const Divider(height: 1, color: AppTheme.borderColor),
            ],
            Expanded(
              child: ListView.separated(
                itemCount: rows,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppTheme.borderColor),
                itemBuilder: (context, index) => buildRow(index),
              ),
            ),
          ],
        );
      },
    );
  }
}

class TableErrorPlaceholder extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const TableErrorPlaceholder({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
          ],
        ),
      ),
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

class DetailContentSkeleton extends StatelessWidget {
  const DetailContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Skeleton(width: 200, height: 32),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Skeleton(width: 80, height: 36),
                        const SizedBox(width: 12),
                        const Skeleton(width: 80, height: 36),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Skeleton(width: 250, height: 32),
                  Row(
                    children: [
                      const Skeleton(width: 80, height: 36),
                      const SizedBox(width: 12),
                      const Skeleton(width: 80, height: 36),
                    ],
                  ),
                ],
              );
            },
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

/// Skeleton matching the sales order full-table view:
/// toolbar → table header → rows (checkbox + Date + SO# + Reference# + Customer + Status + Invoiced + Payment + Packed + Shipped + Amount)
class SalesOrderTableSkeleton extends StatelessWidget {
  const SalesOrderTableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar row
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 14),
          child: Row(
            children: [
              Skeleton(width: 120, height: 28, borderRadius: 6),
              SizedBox(width: 12),
              Skeleton(width: 80, height: 28, borderRadius: 6),
              Spacer(),
              Skeleton(width: 32, height: 28, borderRadius: 6),
              SizedBox(width: 8),
              Skeleton(width: 32, height: 28, borderRadius: 6),
              SizedBox(width: 8),
              Skeleton(width: 100, height: 28, borderRadius: 6),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        // Table header
        Container(
          height: 44,
          color: AppTheme.bgLight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Skeleton(width: 16, height: 16, borderRadius: 2),
              const SizedBox(width: 28),
              ..._headerWidths.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Skeleton(width: w, height: 13),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: 10,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.bgDisabled),
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  const Skeleton(width: 16, height: 16, borderRadius: 2),
                  const SizedBox(width: 28),
                  ..._cellWidths.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Skeleton(width: w, height: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const List<double> _headerWidths = [
    90,
    100,
    90,
    120,
    80,
    70,
    70,
    70,
    70,
    80,
  ];
  static const List<double> _cellWidths = [
    80,
    90,
    70,
    110,
    60,
    55,
    55,
    55,
    55,
    75,
  ];
}

/// Skeleton matching the sales order selection list (narrow 360px panel):
/// header → search bar → list items (checkbox icon + customer name + SO#•date + status + amount)
class SalesOrderListSkeleton extends StatelessWidget {
  const SalesOrderListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel header
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Skeleton(width: 100, height: 20),
              Spacer(),
              Skeleton(width: 28, height: 28, borderRadius: 6),
            ],
          ),
        ),
        // Search bar
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Skeleton(height: 36, borderRadius: 6),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: ListView.separated(
            itemCount: 10,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 14, height: 14, borderRadius: 2),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 130, height: 14),
                        SizedBox(height: 7),
                        Skeleton(width: 160, height: 12),
                        SizedBox(height: 8),
                        Skeleton(width: 60, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Skeleton(width: 55, height: 14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton matching the customer detail screen layout:
/// left panel (280px list) + right panel (detail content with tabs)
class CustomerDetailSkeleton extends StatelessWidget {
  const CustomerDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel — customer mini-list
        Container(
          width: 280,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(child: Skeleton(height: 20, width: 120)),
                    SizedBox(width: 12),
                    Skeleton(width: 20, height: 20, borderRadius: 4),
                    SizedBox(width: 8),
                    Skeleton(width: 20, height: 20, borderRadius: 4),
                    SizedBox(width: 8),
                    Skeleton(width: 20, height: 20, borderRadius: 4),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: 8,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 120, height: 14),
                        SizedBox(height: 6),
                        Skeleton(width: 80, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Right panel — detail
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header + actions
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Skeleton(width: 220, height: 28),
                          SizedBox(height: 10),
                          Skeleton(width: 140, height: 16),
                        ],
                      ),
                    ),
                    Skeleton(width: 74, height: 32, borderRadius: 4),
                    SizedBox(width: 8),
                    Skeleton(width: 36, height: 32, borderRadius: 4),
                    SizedBox(width: 8),
                    Skeleton(width: 104, height: 32, borderRadius: 4),
                    SizedBox(width: 12),
                    Skeleton(width: 152, height: 32, borderRadius: 4),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),
              // Tab bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Wrap(
                  spacing: 28,
                  runSpacing: 12,
                  children: List.generate(
                    5,
                    (i) => Skeleton(
                      width: [60.0, 70.0, 80.0, 70.0, 60.0][i],
                      height: 16,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Skeleton(
                                  width: 48,
                                  height: 48,
                                  borderRadius: 4,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Skeleton(width: 180, height: 18),
                                      SizedBox(height: 10),
                                      Skeleton(width: 96, height: 14),
                                    ],
                                  ),
                                ),
                                Skeleton(
                                  width: 18,
                                  height: 18,
                                  borderRadius: 9,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            ...List.generate(
                              5,
                              (index) => const Padding(
                                padding: EdgeInsets.only(bottom: 18),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Skeleton(height: 14, width: 140),
                                    ),
                                    SizedBox(width: 16),
                                    Skeleton(
                                      width: 14,
                                      height: 14,
                                      borderRadius: 7,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                border: Border.all(
                                  color: const Color(0xFFDCFCE7),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Skeleton(width: 240, height: 14),
                                  SizedBox(height: 8),
                                  Skeleton(width: 180, height: 14),
                                  SizedBox(height: 14),
                                  Skeleton(
                                    width: 110,
                                    height: 32,
                                    borderRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Row(
                              children: [
                                Expanded(
                                  child: Skeleton(height: 14, width: 120),
                                ),
                                SizedBox(width: 16),
                                Skeleton(
                                  width: 14,
                                  height: 14,
                                  borderRadius: 7,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Skeleton(width: 150, height: 14),
                                      SizedBox(height: 8),
                                      Skeleton(width: 130, height: 14),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Skeleton(width: 80, height: 14),
                                      SizedBox(height: 8),
                                      Skeleton(width: 70, height: 14),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            const Skeleton(width: 90, height: 18),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Skeleton(height: 12)),
                                      SizedBox(width: 12),
                                      Expanded(child: Skeleton(height: 12)),
                                      SizedBox(width: 12),
                                      Expanded(child: Skeleton(height: 12)),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: Skeleton(height: 14)),
                                      SizedBox(width: 12),
                                      Expanded(child: Skeleton(height: 14)),
                                      SizedBox(width: 12),
                                      Expanded(child: Skeleton(height: 14)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Skeleton(width: 150, height: 14),
                            const SizedBox(height: 8),
                            const Skeleton(width: 210, height: 14),
                            const SizedBox(height: 36),
                            const Skeleton(width: 110, height: 18),
                            const SizedBox(height: 16),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Skeleton(width: 72, height: 14),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Skeleton(height: 120, borderRadius: 4),
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
            ),
          ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton that matches the sales order detail pane layout:
/// action bar → "what's next" banner → tabs → status strip → document card.
class SalesOrderDetailSkeleton extends StatelessWidget {
  const SalesOrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Action bar (customer label + SO number + action buttons) ──────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 160, height: 12),
                    SizedBox(height: 6),
                    Skeleton(width: 80, height: 22),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Skeleton(width: i == 4 ? 26 : 72, height: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),

        // ── "What's Next?" banner ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                const Skeleton(width: 16, height: 16, borderRadius: 8),
                const SizedBox(width: 10),
                const Expanded(child: Skeleton(height: 14)),
                const SizedBox(width: 16),
                const Skeleton(width: 90, height: 32, borderRadius: 6),
                const SizedBox(width: 8),
                const Skeleton(width: 110, height: 32, borderRadius: 6),
              ],
            ),
          ),
        ),

        // ── Tabs ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: List.generate(
              2,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Skeleton(width: i == 0 ? 72 : 64, height: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppTheme.borderLight),

        // ── Status strip ──────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Skeleton(width: 140, height: 12),
              SizedBox(width: 24),
              Skeleton(width: 100, height: 12),
              Spacer(),
              Skeleton(width: 100, height: 28, borderRadius: 6),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),

        // ── Document card ─────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "SALES ORDER" title
                      Skeleton(width: 120, height: 16),
                      SizedBox(height: 12),
                      Skeleton(width: 180, height: 20),
                      SizedBox(height: 24),
                      // Addresses row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Skeleton(width: 80, height: 11),
                                SizedBox(height: 8),
                                Skeleton(width: 140, height: 14),
                                SizedBox(height: 6),
                                Skeleton(width: 100, height: 12),
                                SizedBox(height: 4),
                                Skeleton(width: 80, height: 12),
                              ],
                            ),
                          ),
                          SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Skeleton(width: 80, height: 11),
                                SizedBox(height: 8),
                                Skeleton(width: 140, height: 14),
                                SizedBox(height: 6),
                                Skeleton(width: 100, height: 12),
                                SizedBox(height: 4),
                                Skeleton(width: 80, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      // Meta fields grid (2 × 4)
                      Row(
                        children: [
                          Expanded(child: Skeleton(height: 12)),
                          SizedBox(width: 16),
                          Expanded(child: Skeleton(height: 12)),
                          SizedBox(width: 16),
                          Expanded(child: Skeleton(height: 12)),
                          SizedBox(width: 16),
                          Expanded(child: Skeleton(height: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Items table header
                const Skeleton(height: 36, borderRadius: 0),
                const SizedBox(height: 1),
                ...List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Skeleton(height: 13)),
                        SizedBox(width: 12),
                        Expanded(flex: 2, child: Skeleton(height: 13)),
                        SizedBox(width: 12),
                        Expanded(flex: 2, child: Skeleton(height: 13)),
                        SizedBox(width: 12),
                        Expanded(flex: 2, child: Skeleton(height: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Totals
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 280,
                    child: Column(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Skeleton(
                                width: i == 2 ? 80 : 60,
                                height: i == 2 ? 18 : 13,
                              ),
                              Skeleton(width: 60, height: i == 2 ? 18 : 13),
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
        ),
      ],
    );
  }
}

/// Skeleton for report screens: date filters row + summary cards row + table
class ReportTableSkeleton extends StatelessWidget {
  const ReportTableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters row
          const Row(
            children: [
              Skeleton(width: 200, height: 36, borderRadius: 6),
              SizedBox(width: 12),
              Skeleton(width: 200, height: 36, borderRadius: 6),
              SizedBox(width: 12),
              Skeleton(width: 100, height: 36, borderRadius: 6),
              Spacer(),
              Skeleton(width: 90, height: 36, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 24),
          // Table header
          Container(
            height: 44,
            color: AppTheme.bgLight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Skeleton(height: 13)),
                SizedBox(width: 16),
                Expanded(flex: 2, child: Skeleton(height: 13)),
                SizedBox(width: 16),
                Expanded(flex: 2, child: Skeleton(height: 13)),
                SizedBox(width: 16),
                Expanded(flex: 2, child: Skeleton(height: 13)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          ...List.generate(
            8,
            (_) => Column(
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Skeleton(height: 13)),
                      SizedBox(width: 16),
                      Expanded(flex: 2, child: Skeleton(height: 13)),
                      SizedBox(width: 16),
                      Expanded(flex: 2, child: Skeleton(height: 13)),
                      SizedBox(width: 16),
                      Expanded(flex: 2, child: Skeleton(height: 13)),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.bgDisabled),
              ],
            ),
          ),
        ],
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
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  const Skeleton(width: 80, height: 36),
                  const Skeleton(width: 80, height: 36),
                  const Skeleton(width: 120, height: 36),
                ],
              );
            },
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

/// Skeleton for the Credit Note full-table layout:
/// toolbar → table header → shimmer rows
class CreditNoteTableSkeleton extends StatelessWidget {
  const CreditNoteTableSkeleton({super.key});

  // Flex ratios matching the credit note column widths — no fixed pixel widths
  static const List<int> _flex = [8, 11, 11, 11, 16, 11, 8, 9, 9, 10, 10];

  static List<Widget> _headerCells() => _flex
      .map(
        (f) => Expanded(
          flex: f,
          child: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Skeleton(height: 12),
          ),
        ),
      )
      .toList();

  static List<Widget> _dataCells(int rowIndex) => _flex
      .map(
        (f) => Expanded(
          flex: f,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FractionallySizedBox(
              widthFactor: rowIndex.isEven ? 0.85 : 0.65,
              alignment: Alignment.centerLeft,
              child: const Skeleton(height: 13),
            ),
          ),
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 14),
          child: Row(
            children: [
              Skeleton(width: 140, height: 26, borderRadius: 6),
              SizedBox(width: 8),
              Skeleton(width: 14, height: 14, borderRadius: 7),
              Spacer(),
              Skeleton(width: 200, height: 32, borderRadius: 4),
              SizedBox(width: 12),
              Skeleton(width: 74, height: 32, borderRadius: 4),
              SizedBox(width: 8),
              Skeleton(width: 32, height: 32, borderRadius: 4),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        // Table header
        Container(
          height: 44,
          color: AppTheme.bgLight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Skeleton(width: 14, height: 14, borderRadius: 2),
              const SizedBox(width: 28),
              ..._headerCells(),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        // Rows
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.bgDisabled),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  const Skeleton(width: 14, height: 14, borderRadius: 2),
                  const SizedBox(width: 28),
                  ..._dataCells(i),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton for the Vendor Credit add/edit form.
/// Shown while initial page data (customers, items) is loading.
class VendorCreditAddSkeleton extends StatelessWidget {
  const VendorCreditAddSkeleton({super.key});

  static const double _labelWidth = 150.0;
  static const double _gap = 16.0;
  static const double _fieldH = 32.0;
  static const double _rowBottomPad = 14.0;

  Widget _row({required double fieldWidth, double labelW = _labelWidth}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: _rowBottomPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Skeleton(width: labelW, height: 14),
            const SizedBox(width: _gap),
            Skeleton(width: fieldWidth, height: _fieldH),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Vendor header band ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Name
                  _row(fieldWidth: 500),
                  // Credit Note#
                  _row(fieldWidth: 330),
                  // Order Number
                  _row(fieldWidth: 330),
                  // Vendor Credit Date
                  _row(fieldWidth: 330),
                  // Subject
                  _row(fieldWidth: 434),
                  // Reverse charge checkbox placeholder
                  Padding(
                    padding: EdgeInsets.only(
                      left: _labelWidth + _gap,
                      bottom: _rowBottomPad,
                    ),
                    child: Row(
                      children: [
                        const Skeleton(width: 16, height: 16, borderRadius: 2),
                        const SizedBox(width: 8),
                        const Skeleton(width: 260, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Toolbar (discount + price list) ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: const [
                Skeleton(width: 180, height: 36, borderRadius: 4),
                SizedBox(width: 24),
                Skeleton(width: 180, height: 36, borderRadius: 4),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Items table ─────────────────────────────────────────────────
          // Table header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: const [
                Skeleton(width: 80, height: 14),
                Spacer(),
                Skeleton(width: 100, height: 28, borderRadius: 4),
                SizedBox(width: 8),
                Skeleton(width: 32, height: 28, borderRadius: 4),
              ],
            ),
          ),
          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                left: BorderSide(color: AppTheme.borderLight),
                right: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: Row(
              children: const [
                SizedBox(width: 40),
                Expanded(flex: 14, child: Skeleton(height: 12)),
                SizedBox(width: 12),
                Expanded(flex: 6, child: Skeleton(height: 12)),
                SizedBox(width: 12),
                Expanded(flex: 4, child: Skeleton(height: 12)),
                SizedBox(width: 12),
                Expanded(flex: 4, child: Skeleton(height: 12)),
                SizedBox(width: 12),
                Expanded(flex: 4, child: Skeleton(height: 12)),
                SizedBox(width: 12),
                Expanded(flex: 4, child: Skeleton(height: 12)),
              ],
            ),
          ),
          // Two skeleton item rows
          ...List.generate(
            2,
            (i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(
                  left: BorderSide(color: AppTheme.borderLight),
                  right: BorderSide(color: AppTheme.borderLight),
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 14,
                    child: FractionallySizedBox(
                      widthFactor: i == 0 ? 0.7 : 0.5,
                      alignment: Alignment.centerLeft,
                      child: const Skeleton(height: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: Skeleton(height: 14)),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: Skeleton(height: 14)),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: Skeleton(height: 14)),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: Skeleton(height: 14)),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: Skeleton(height: 14)),
                ],
              ),
            ),
          ),
          // Table bottom cap
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              border: Border(
                left: BorderSide(color: AppTheme.borderLight),
                right: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Totals area (right-aligned) ─────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 300,
              child: Column(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Skeleton(
                          width: i == 2 ? 70.0 : 55.0,
                          height: i == 2 ? 18.0 : 13.0,
                        ),
                        Skeleton(width: 65, height: i == 2 ? 18.0 : 13.0),
                      ],
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

/// Skeleton for the Credit Note compact list layout (narrow panel).
/// Set [showToolbar] to false to render only the shimmer list items
/// (used when the toolbar is already rendered above).
class CreditNoteListSkeleton extends StatelessWidget {
  final bool showToolbar;
  const CreditNoteListSkeleton({super.key, this.showToolbar = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar (optional)
        if (showToolbar)
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: const Row(
              children: [
                Skeleton(width: 120, height: 20, borderRadius: 4),
                SizedBox(width: 6),
                Skeleton(width: 12, height: 12, borderRadius: 6),
                Spacer(),
                Skeleton(width: 160, height: 28, borderRadius: 4),
                SizedBox(width: 8),
                Skeleton(width: 28, height: 28, borderRadius: 4),
                SizedBox(width: 8),
                Skeleton(width: 28, height: 28, borderRadius: 4),
              ],
            ),
          ),
        // List items
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 14,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 14, height: 14, borderRadius: 2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: i.isEven ? 130.0 : 110.0, height: 14),
                        const SizedBox(height: 6),
                        Skeleton(width: i.isEven ? 170.0 : 140.0, height: 12),
                        const SizedBox(height: 7),
                        Skeleton(width: i.isEven ? 58.0 : 48.0, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Skeleton(width: 60, height: 14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

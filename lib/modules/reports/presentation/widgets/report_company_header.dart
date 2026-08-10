import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/providers/report_branch_provider.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

class ReportCompanyHeader extends ConsumerWidget {
  final String companyName;

  const ReportCompanyHeader({
    super.key,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchNameAsync = ref.watch(reportBranchNameProvider);

    if (branchNameAsync.isLoading && !branchNameAsync.hasValue) {
      return const Skeleton(
        width: 200,
        height: 16,
        borderRadius: AppTheme.space4,
      );
    }

    final branchName = branchNameAsync.valueOrNull?.trim();
    final resolvedName = branchName?.isNotEmpty == true ? branchName! : companyName;
    final displayName = resolvedName.toUpperCase();

    return Text(
      displayName,
      textAlign: TextAlign.center,
      style: AppTheme.metaHelper.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

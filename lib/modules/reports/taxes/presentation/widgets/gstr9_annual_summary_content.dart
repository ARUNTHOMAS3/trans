import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';

class Gstr9AnnualSummaryContent extends StatelessWidget {
  const Gstr9AnnualSummaryContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _Gstr9HeroSection(),
          Divider(height: 1, color: AppTheme.borderLight),
          _Gstr9AboutSection(),
        ],
      ),
    );
  }
}

class _Gstr9HeroSection extends StatelessWidget {
  const _Gstr9HeroSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 46, 48, 72),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.fileText,
            size: 50,
            color: AppTheme.warningOrange,
          ),
          const SizedBox(height: AppTheme.space24),
          Text(
            'GSTR-9',
            textAlign: TextAlign.center,
            style: AppTheme.pageTitle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Text(
              'GSTR-9 is a consolidated summary of all your GST return filings from the current/previous financial year\nand should be filed annually.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space32),
          ReportPrimaryActionButton(
            label: 'GENERATE RETURN',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _Gstr9AboutSection extends StatelessWidget {
  const _Gstr9AboutSection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 54, 0, 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About GSTR-9',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.space32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.space8),
                    child: Container(
                      width: AppTheme.space4,
                      height: AppTheme.space4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space14),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          height: 1.55,
                        ),
                        children: [
                          const TextSpan(text: 'The '),
                          TextSpan(
                            text: 'GSTR-9',
                            style: AppTheme.bodyText.copyWith(
                              color: AppTheme.primaryBlue,
                              fontSize: 16,
                              height: 1.55,
                            ),
                          ),
                          const TextSpan(
                            text:
                                ' should be furnished by all the registered taxpayers under GST, excluding Input Service Distributors\n(ISD), casual taxable persons, non-resident taxable persons and those paying taxes under Section 51 or 52 of\nIntegrated Goods and Services Tax Act, 2017.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

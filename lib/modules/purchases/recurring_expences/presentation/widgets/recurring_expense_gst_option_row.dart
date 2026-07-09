import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';

const List<String> kRecurringExpenseBaseGstTreatmentOptions = <String>[
  'Registered Business - Regular',
  'Registered Business - Composition',
  'Unregistered Business',
  'Consumer',
  'Overseas',
];

const List<String> kRecurringExpenseExtendedGstTreatmentOptions = <String>[
  ...kRecurringExpenseBaseGstTreatmentOptions,
  'Special Economic Zone',
  'Deemed Export',
  'Non-GST Supply',
  'Out Of Scope',
  'Tax Deductor',
  'SEZ Developer',
  'Input Service Distributor',
];

const Map<String, String> kRecurringExpenseGstTreatmentDescriptions = {
  'Registered Business - Regular': 'Business that is registered under GST',
  'Registered Business - Composition':
      'Business that is registered under the Composition Scheme in GST',
  'Unregistered Business': 'Business that has not been registered under GST',
  'Consumer': 'A customer who is a regular consumer',
  'Overseas':
      'Persons with whom you do import or export of supplies outside India',
  'Special Economic Zone':
      'Business (Unit) that is located in a Special Economic Zone (SEZ) of India or a SEZ Developer',
  'Deemed Export':
      'Supply of goods to an Export Oriented Unit or against Advanced Authorization/Export Promotion Capital Goods.',
  'Non-GST Supply': 'Transactions with supplies that do not attract GST',
  'Out Of Scope': 'Transactions that do not come under the ambit of GST',
  'Tax Deductor':
      'Departments of the State/Central government, governmental agencies or local authorities',
  'SEZ Developer':
      'A person/organisation who owns at least 26% of the equity in creating business units in a Special Economic Zone (SEZ)',
  'Input Service Distributor':
      'Input Service Distributor (ISD) is an office that receives tax invoices for services used by the company in different states under the same PAN.',
};

Widget buildRecurringExpenseGstOptionRow({
  required String item,
  required bool isSelected,
  required bool isHovered,
  required double height,
  bool useStandardDropdownTypography = false,
  Map<String, String> descriptions = kRecurringExpenseGstTreatmentDescriptions,
}) {
  final backgroundColor = isHovered
      ? const Color(0xFF3B82F6)
      : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
  final titleColor = isHovered
      ? AppTheme.backgroundColor
      : AppTheme.textPrimary;
  final descriptionColor = isHovered
      ? AppTheme.backgroundColor
      : AppTheme.textSecondary;
  final description = descriptions[item] ?? '';
  return Container(
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (useStandardDropdownTypography
                        ? AppTextStyles.input
                        : AppTextStyles.body)
                    .copyWith(
                  color: titleColor,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: descriptionColor,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check,
            color: isHovered ? AppTheme.backgroundColor : AppTheme.infoBlue,
            size: 18,
          ),
      ],
    ),
  );
}

part of '../pages/items_item_create.dart';

class MoreInfoSection extends StatelessWidget {
  final TextEditingController storageDescCtrl;
  final TextEditingController aboutCtrl;
  final TextEditingController usesDescCtrl;
  final TextEditingController howToUseCtrl;
  final TextEditingController dosageDescCtrl;
  final TextEditingController missedDoseDescCtrl;
  final TextEditingController safetyAdviceCtrl;
  final TextEditingController howItWorksCtrl;
  final TextEditingController drugInteractionsCtrl;
  final TextEditingController contraindicationsCtrl;
  final TextEditingController sideEffectsManagementCtrl;
  final TextEditingController goodToKnowCtrl;
  final TextEditingController quickTipsCtrl;
  final TextEditingController allergyInformationCtrl;
  final TextEditingController productHighlightsCtrl;
  final TextEditingController ingredientsListCtrl;
  final TextEditingController safetyPregnancyCtrl;
  final TextEditingController safetyBreastfeedingCtrl;
  final TextEditingController safetyAlcoholCtrl;
  final TextEditingController safetyLiverCtrl;
  final TextEditingController safetyKidneyCtrl;
  final TextEditingController safetyDrivingCtrl;
  final TextEditingController safetyAllergyCtrl;
  final TextEditingController safetyChildrenCtrl;
  final TextEditingController safetyOlderPatientsCtrl;
  final TextEditingController interactionsDrugDrugCtrl;
  final TextEditingController interactionsDrugDiseaseCtrl;
  final TextEditingController dosageDailyDoseCtrl;
  final TextEditingController dosageOverDoseCtrl;
  final TextEditingController dosageMissedDoseCtrl;
  final TextEditingController referencesTextCtrl;
  final TextEditingController productDescriptionCtrl;
  final TextEditingController additionalInfoAllergyCtrl;
  final TextEditingController additionalInfoConcernsCtrl;
  final TextEditingController additionalInfoGoodToKnowCtrl;
  final TextEditingController additionalInfoQuickTipsCtrl;
  final TextEditingController directionsForUseCtrl;
  final TextEditingController sideEffectsCtrl;
  final TextEditingController faqTextCtrl;

  const MoreInfoSection({
    super.key,
    required this.storageDescCtrl,
    required this.aboutCtrl,
    required this.usesDescCtrl,
    required this.howToUseCtrl,
    required this.dosageDescCtrl,
    required this.missedDoseDescCtrl,
    required this.safetyAdviceCtrl,
    required this.howItWorksCtrl,
    required this.drugInteractionsCtrl,
    required this.contraindicationsCtrl,
    required this.sideEffectsManagementCtrl,
    required this.goodToKnowCtrl,
    required this.quickTipsCtrl,
    required this.allergyInformationCtrl,
    required this.productHighlightsCtrl,
    required this.ingredientsListCtrl,
    required this.safetyPregnancyCtrl,
    required this.safetyBreastfeedingCtrl,
    required this.safetyAlcoholCtrl,
    required this.safetyLiverCtrl,
    required this.safetyKidneyCtrl,
    required this.safetyDrivingCtrl,
    required this.safetyAllergyCtrl,
    required this.safetyChildrenCtrl,
    required this.safetyOlderPatientsCtrl,
    required this.interactionsDrugDrugCtrl,
    required this.interactionsDrugDiseaseCtrl,
    required this.dosageDailyDoseCtrl,
    required this.dosageOverDoseCtrl,
    required this.dosageMissedDoseCtrl,
    required this.referencesTextCtrl,
    required this.productDescriptionCtrl,
    required this.additionalInfoAllergyCtrl,
    required this.additionalInfoConcernsCtrl,
    required this.additionalInfoGoodToKnowCtrl,
    required this.additionalInfoQuickTipsCtrl,
    required this.directionsForUseCtrl,
    required this.sideEffectsCtrl,
    required this.faqTextCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextArea("Storage description", storageDescCtrl),
            const SizedBox(height: 16),
            _buildTextArea("About", aboutCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Uses description", usesDescCtrl),
            const SizedBox(height: 16),
            _buildTextArea("How-to-use", howToUseCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Dosage description", dosageDescCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Missed dose description", missedDoseDescCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Safety advice", safetyAdviceCtrl),
            const SizedBox(height: 16),
            _buildTextArea("How It Works", howItWorksCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Drug Interactions", drugInteractionsCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Contraindications", contraindicationsCtrl),
            const SizedBox(height: 16),
            _buildTextArea(
              "Side Effects Management",
              sideEffectsManagementCtrl,
            ),
            const SizedBox(height: 16),
            _buildTextArea("Good To Know", goodToKnowCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Quick Tips", quickTipsCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Allergy Information", allergyInformationCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Product Highlights", productHighlightsCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Ingredients List", ingredientsListCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Product Description", productDescriptionCtrl),
            const SizedBox(height: 16),
            _buildTextArea("References", referencesTextCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Directions For Use", directionsForUseCtrl),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildTextArea("Safety - Pregnancy", safetyPregnancyCtrl),
            const SizedBox(height: 16),
            _buildTextArea(
              "Safety - Breastfeeding",
              safetyBreastfeedingCtrl,
            ),
            const SizedBox(height: 16),
            _buildTextArea("Safety - Alcohol", safetyAlcoholCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Safety - Liver", safetyLiverCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Safety - Kidney", safetyKidneyCtrl),
            const SizedBox(height: 16),
            _buildTextArea(
              "Safety - Driving / Machinery",
              safetyDrivingCtrl,
            ),
            const SizedBox(height: 16),
            _buildTextArea("Safety - Allergy", safetyAllergyCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Safety - Children", safetyChildrenCtrl),
            const SizedBox(height: 16),
            _buildTextArea(
              "Safety - Older Patients",
              safetyOlderPatientsCtrl,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildTextArea(
              "Interactions - Drug-Drug",
              interactionsDrugDrugCtrl,
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Interactions - Drug-Disease",
              interactionsDrugDiseaseCtrl,
            ),
            const SizedBox(height: 16),
            _buildTextArea("Dosage - Daily Dose", dosageDailyDoseCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Dosage - Over Dose", dosageOverDoseCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Dosage - Missed Dose", dosageMissedDoseCtrl),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildTextArea("Additional Info - Allergy", additionalInfoAllergyCtrl),
            const SizedBox(height: 16),
            _buildTextArea(
              "Additional Info - Concerns",
              additionalInfoConcernsCtrl,
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Additional Info - Good To Know",
              additionalInfoGoodToKnowCtrl,
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Additional Info - Quick Tips",
              additionalInfoQuickTipsCtrl,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildStructuredTextArea(
              "Side Effects",
              sideEffectsCtrl,
              hint:
                  "Enter one effect per line or separate each group with a blank line",
            ),
            const SizedBox(height: 16),
            _buildStructuredTextArea(
              "FAQ",
              faqTextCtrl,
              hint:
                  "Paste question-answer blocks here. Separate each FAQ with a blank line",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller) {
    return SharedFieldLayout(
      label: label,
      compact: false,
      child: CustomTextField(
        controller: controller,
        hintText: 'Enter $label',
        maxLines: 4,
        height: 100,
      ),
    );
  }

  Widget _buildStructuredTextArea(
    String label,
    TextEditingController controller, {
    required String hint,
  }) {
    return SharedFieldLayout(
      label: label,
      compact: false,
      child: CustomTextField(
        controller: controller,
        hintText: hint,
        maxLines: 6,
        height: 132,
      ),
    );
  }
}

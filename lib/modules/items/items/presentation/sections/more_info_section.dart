part of '../items_item_create.dart';

class MoreInfoSection extends StatelessWidget {
  final TextEditingController storageDescCtrl;
  final TextEditingController aboutCtrl;
  final TextEditingController usesDescCtrl;
  final TextEditingController howToUseCtrl;
  final TextEditingController dosageDescCtrl;
  final TextEditingController missedDoseDescCtrl;
  final TextEditingController safetyAdviceCtrl;
  final List<TextEditingController> sideEffectCtrls;
  final List<TextEditingController> faqTextCtrls;
  final VoidCallback onAddSideEffect;
  final Function(int) onRemoveSideEffect;
  final VoidCallback onAddFaq;
  final Function(int) onRemoveFaq;

  const MoreInfoSection({
    super.key,
    required this.storageDescCtrl,
    required this.aboutCtrl,
    required this.usesDescCtrl,
    required this.howToUseCtrl,
    required this.dosageDescCtrl,
    required this.missedDoseDescCtrl,
    required this.safetyAdviceCtrl,
    required this.sideEffectCtrls,
    required this.faqTextCtrls,
    required this.onAddSideEffect,
    required this.onRemoveSideEffect,
    required this.onAddFaq,
    required this.onRemoveFaq,
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            _buildDynamicList(
              "Side Effects",
              sideEffectCtrls,
              onAddSideEffect,
              onRemoveSideEffect,
            ),
            const SizedBox(height: 24),
            _buildDynamicList("FAQ", faqTextCtrls, onAddFaq, onRemoveFaq),
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

  Widget _buildDynamicList(
    String label,
    List<TextEditingController> ctrls,
    VoidCallback onAdd,
    Function(int) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textBody,
          ),
        ),
        const SizedBox(height: 12),
        ...ctrls.asMap().entries.map((entry) {
          final index = entry.key;
          final ctrl = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: ctrl,
                    hintText: 'Enter point',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => onRemove(index),
                ),
              ],
            ),
          );
        }),
        InkWell(
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16, color: AppTheme.primaryBlueDark),
                const SizedBox(width: 4),
                Text(
                  "Add More",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlueDark,
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

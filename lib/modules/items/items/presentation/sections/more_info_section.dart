part of '../pages/items_item_create.dart';

class MoreInfoSection extends StatelessWidget {
  final TextEditingController aboutCtrl;
  final TextEditingController usesDescCtrl;
  final TextEditingController dosageDescCtrl;
  final TextEditingController howItWorksCtrl;
  final TextEditingController sideEffectsManagementCtrl;
  final TextEditingController safetyAdviceCtrl;
  final TextEditingController drugInteractionsCtrl;
  final TextEditingController additionalInformationCtrl;
  final TextEditingController productHighlightsCtrl;
  final TextEditingController ingredientsListCtrl;
  final TextEditingController referencesTextCtrl;
  final TextEditingController productDescriptionCtrl;
  final TextEditingController directionsForUseCtrl;
  final TextEditingController sideEffectsCtrl;
  final TextEditingController faqTextCtrl;

  const MoreInfoSection({
    super.key,
    required this.aboutCtrl,
    required this.usesDescCtrl,
    required this.dosageDescCtrl,
    required this.howItWorksCtrl,
    required this.sideEffectsManagementCtrl,
    required this.safetyAdviceCtrl,
    required this.drugInteractionsCtrl,
    required this.additionalInformationCtrl,
    required this.productHighlightsCtrl,
    required this.ingredientsListCtrl,
    required this.referencesTextCtrl,
    required this.productDescriptionCtrl,
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
            _buildTextArea(
              "About",
              aboutCtrl,
              hint:
                  "Structure:\nShort overview of the product.\nWhat it is used for.\nWho it is suitable for.",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Uses of",
              usesDescCtrl,
              hint:
                  "Structure:\nUsed for condition 1.\nUsed for condition 2.\nUsed for condition 3.",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Product Highlights",
              productHighlightsCtrl,
              hint:
                  "Structure:\nHighlight 1\nHighlight 2\nHighlight 3\nAdd one short benefit per line.",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Product Description",
              productDescriptionCtrl,
              hint:
                  "Structure:\nParagraph 1: What the product is.\nParagraph 2: What it contains.\nParagraph 3: What it may help support.",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Ingredients",
              ingredientsListCtrl,
              hint:
                  "Structure:\nINGREDIENT NAME:\nDescription of what this ingredient is and its role.\n\nINGREDIENT NAME:\nDescription of what this ingredient is and its role.",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Directions For Use",
              directionsForUseCtrl,
              hint:
                  "Structure:\nHow to take/use the product.\nWhen to take/use it.\nWhether to take with food or water.\nSpecial handling instructions, if any.",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Dosage",
              dosageDescCtrl,
              hint:
                  "Structure:\nDAILY DOSE\nDescription\n\nOVER DOSE\nDescription\n\nMISSED DOSE\nDescription",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "How It Works",
              howItWorksCtrl,
              hint:
                  "Structure:\nACTIVE INGREDIENT / FORMULATION:\nExplain how it works in the body.\nAdd separate blocks if there is more than one action.",
            ),
            const SizedBox(height: 16),
            _buildStructuredTextArea(
              "Side Effects",
              sideEffectsCtrl,
              hint:
                  "Structure:\nSide effect 1\nSide effect 2\nSide effect 3\nAdd one side effect per line.",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Management Of Side Effects",
              sideEffectsManagementCtrl,
              hint:
                  "Structure:\nSIDE EFFECT NAME:\nHow to manage it.\nWhen to seek medical advice.\n\nSIDE EFFECT NAME:\nHow to manage it.\nWhen to seek medical advice.",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Safety Measures & Warnings",
              safetyAdviceCtrl,
              hint:
                  "Structure:\nPREGNANCY\nDescription\n\nBREASTFEEDING\nDescription\n\nALCOHOL\nDescription\n\nLIVER\nDescription\n\nKIDNEY\nDescription\n\nUSE IN DRIVING AND OPERATING MACHINERY\nDescription\n\nALLERGY\nDescription\n\nCHILDREN\nDescription\n\nOLDER PATIENTS\nDescription",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Interactions",
              drugInteractionsCtrl,
              hint:
                  "Structure:\nDRUG INTERACTIONS\nDescription\n\nFOOD INTERACTIONS\nDescription\n\nDISEASE INTERACTIONS\nDescription",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "Additional Information",
              additionalInformationCtrl,
              hint:
                  "Structure:\nGOOD TO KNOW\nDescription\n\nQUICK TIPS\nDescription\n\nCONCERNS IT CAN HELP WITH\nDescription",
            ),
            const SizedBox(height: 16),
            _buildStructuredTextArea(
              "Frequently Asked Questions (FAQs)",
              faqTextCtrl,
              hint:
                  "Structure:\nQ: Add the question here\nA: Add the answer here\n\nQ: Add the next question here\nA: Add the next answer here",
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              "References",
              referencesTextCtrl,
              hint:
                  "Structure:\nSource / publication name\nURL or citation details\n\nSource / publication name\nURL or citation details",
            ),
          ],
        ),
      ),
    );
  }

  void _normalizePastedText(TextEditingController controller, String rawValue) {
    final normalized = _sanitizeStructuredText(rawValue);
    if (normalized == rawValue) return;
    controller.value = controller.value.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
  }

  String _sanitizeStructuredText(String rawValue) {
    var normalized = rawValue
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u2028', '\n')
        .replaceAll('\u2029', '\n')
        .replaceAll('\u0085', '\n')
        .replaceAll('\u00A0', ' ');

    final trimmed = normalized.trim();
    if (trimmed.length >= 2 &&
        trimmed.startsWith('"') &&
        trimmed.endsWith('"') &&
        trimmed.contains('\n')) {
      final start = normalized.indexOf(trimmed);
      final end = start + trimmed.length;
      final unquoted = trimmed
          .substring(1, trimmed.length - 1)
          .replaceAll('""', '"');
      normalized =
          '${normalized.substring(0, start)}$unquoted${normalized.substring(end)}';
    }

    final lines = normalized.split('\n');
    final normalizedLines = <String>[];
    for (var index = 0; index < lines.length; index++) {
      normalizedLines.add(
        _normalizeStructuredLine(
          lines[index],
          previousNormalizedLine: index > 0 ? normalizedLines[index - 1] : null,
        ),
      );
    }
    normalized = normalizedLines.join('\n');
    normalized = normalized.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return normalized;
  }

  String _normalizeStructuredLine(
    String line, {
    String? previousNormalizedLine,
  }) {
    final value = line
        .replaceAll('\t', '    ')
        .replaceAll(RegExp(r'[ \t]+$'), '');

    if (value.trim().isEmpty) {
      return '';
    }

    final bulletMatch = RegExp(
      r'^([ ]*)([•●◦▪▫‣⁃∙■◆➤→*-])(?:[ \t]+)(.*)$',
    ).firstMatch(value);
    if (bulletMatch != null) {
      final indent = bulletMatch.group(1) ?? '';
      final content = bulletMatch.group(3)?.trimLeft() ?? '';
      return '$indent• $content';
    }

    final numberedMatch = RegExp(
      r'^([ ]*)(\d+[\.\)])(?:[ \t]+)(.*)$',
    ).firstMatch(value);
    if (numberedMatch != null) {
      final indent = numberedMatch.group(1) ?? '';
      final marker = numberedMatch.group(2) ?? '';
      final content = numberedMatch.group(3)?.trimLeft() ?? '';
      return '$indent$marker $content';
    }

    if (_looksLikeImplicitBulletItem(
      value,
      previousNormalizedLine: previousNormalizedLine,
    )) {
      final leadingSpaces = RegExp(r'^\s*').stringMatch(value) ?? '';
      return '$leadingSpaces• ${value.trimLeft()}';
    }

    return value;
  }

  bool _looksLikeImplicitBulletItem(
    String value, {
    String? previousNormalizedLine,
  }) {
    final trimmed = value.trimLeft();
    if (trimmed.isEmpty || !trimmed.contains(':')) return false;
    if (trimmed.length > 220) return false;

    final prefix = trimmed.split(':').first.trim();
    if (prefix.isEmpty || prefix.length > 60) return false;

    final colonLabelPattern = RegExp(r'^[A-Z][A-Za-z0-9\s/&(),+\-]{1,58}$');
    if (!colonLabelPattern.hasMatch(prefix)) return false;

    final previous = previousNormalizedLine?.trim() ?? '';
    if (previous.startsWith('• ') ||
        RegExp(r'^\d+[\.\)]\s').hasMatch(previous)) {
      return true;
    }

    if (previous.isEmpty) {
      return true;
    }

    final leadInPatterns = [
      'Here are',
      'following side effects',
      'contains two active ingredients',
      'interacts with the following',
      'common side effects',
      'tips to manage',
    ];

    return leadInPatterns.any((pattern) => previous.contains(pattern));
  }

  Widget _buildTextArea(
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
        keyboardType: TextInputType.multiline,
        contentCase: ContentCase.none,
        onChanged: (value) => _normalizePastedText(controller, value),
        maxLines: null,
        height: 120,
        minHeight: 120,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        resizable: true,
        textStyle: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AppTheme.textPrimary,
        ),
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
        keyboardType: TextInputType.multiline,
        contentCase: ContentCase.none,
        onChanged: (value) => _normalizePastedText(controller, value),
        maxLines: null,
        height: 140,
        minHeight: 140,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        resizable: true,
        textStyle: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

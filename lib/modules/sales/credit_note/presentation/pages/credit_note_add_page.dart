import 'package:flutter/material.dart';

import 'credit_note_create_page.dart';

class CreditNoteAddPage extends StatelessWidget {
  final String? initialCustomer;
  final String? creditNoteId;

  const CreditNoteAddPage({
    super.key,
    this.initialCustomer,
    this.creditNoteId,
  });

  @override
  Widget build(BuildContext context) {
    return CreditNoteCreatePage(
      initialCustomer: initialCustomer,
      creditNoteId: creditNoteId,
    );
  }
}

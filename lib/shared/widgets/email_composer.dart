import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class EmailComposerScreen extends StatefulWidget {
  final String title;
  final String initialFrom;
  final String initialTo;
  final String initialSubject;
  final String initialBody;
  final String attachmentName;
  final Function(String from, String to, String subject, String body, bool attachPdf) onSend;

  const EmailComposerScreen({
    super.key,
    required this.title,
    required this.initialFrom,
    required this.initialTo,
    required this.initialSubject,
    required this.initialBody,
    required this.attachmentName,
    required this.onSend,
  });

  @override
  State<EmailComposerScreen> createState() => _EmailComposerScreenState();
}

class _EmailComposerScreenState extends State<EmailComposerScreen> {
  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _bodyCtrl;
  bool _attachPdf = true;

  @override
  void initState() {
    super.initState();
    _fromCtrl = TextEditingController(text: widget.initialFrom);
    _toCtrl = TextEditingController(text: widget.initialTo);
    _subjectCtrl = TextEditingController(text: widget.initialSubject);
    _bodyCtrl = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fields
              _buildField('From', _fromCtrl, readOnly: true),
              _buildField('Send To', _toCtrl),
              _buildField('Subject', _subjectCtrl),
              
              // Toolbar (Visual only for now to match screenshot)
              _buildToolbar(),
              
              // Body
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: 15,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              
              // Attachments Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _attachPdf,
                      onChanged: (val) {
                        setState(() => _attachPdf = val ?? false);
                      },
                    ),
                    const Text('Attach Sales Order PDF'),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.fileText, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(widget.attachmentName),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22A95E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () {
                        widget.onSend(
                          _fromCtrl.text,
                          _toCtrl.text,
                          _subjectCtrl.text,
                          _bodyCtrl.text,
                          _attachPdf,
                        );
                      },
                      child: const Text('Send'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              readOnly: readOnly,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: readOnly ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: const Row(
        children: [
          Icon(LucideIcons.bold, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 16),
          Icon(LucideIcons.italic, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 16),
          Icon(LucideIcons.underline, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 16),
          Icon(LucideIcons.strikethrough, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 24),
          Text('16px', style: TextStyle(color: Color(0xFF4B5563))),
          SizedBox(width: 24),
          Text('Arial', style: TextStyle(color: Color(0xFF4B5563))),
          SizedBox(width: 24),
          Icon(LucideIcons.alignLeft, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 16),
          Icon(LucideIcons.alignCenter, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 24),
          Icon(LucideIcons.list, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 16),
          Icon(LucideIcons.listOrdered, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 24),
          Icon(LucideIcons.image, size: 20, color: Color(0xFF4B5563)),
          SizedBox(width: 16),
          Icon(LucideIcons.link, size: 20, color: Color(0xFF4B5563)),
        ],
      ),
    );
  }
}

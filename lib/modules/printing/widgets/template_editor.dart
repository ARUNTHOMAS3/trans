// PATH: lib/modules/printing/widgets/template_editor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/print_template.dart';

class TemplateEditor extends ConsumerStatefulWidget {
  final PrintTemplate? template;
  final Function(PrintTemplate) onSave;

  const TemplateEditor({super.key, this.template, required this.onSave});

  @override
  ConsumerState<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<TemplateEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedType = TemplateType.invoice;
  bool _isDefault = false;
  Map<String, String> _variables = {};

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _initializeFromTemplate(widget.template!);
    } else {
      _contentController.text = _getDefaultTemplateContent();
    }
  }

  void _initializeFromTemplate(PrintTemplate template) {
    _nameController.text = template.name;
    _descriptionController.text = template.description ?? '';
    _contentController.text = template.content;
    _selectedType = template.type;
    _isDefault = template.isDefault;
    _variables = Map<String, String>.from(
      template.variables.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  String _getDefaultTemplateContent() {
    switch (_selectedType) {
      case TemplateType.invoice:
        return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .company-name { font-size: 24px; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-name">{{company_name}}</div>
        <div>{{company_address}}</div>
    </div>
    
    <h2>INVOICE</h2>
    <p>Invoice #: {{document_number}}</p>
    <p>Date: {{document_date}}</p>
    
    <p>To: {{party_name}}</p>
    <p>Address: {{party_address}}</p>
    
    <table>
        <thead>
            <tr>
                <th>Description</th>
                <th>Quantity</th>
                <th>Rate</th>
                <th>Amount</th>
            </tr>
        </thead>
        <tbody>
            {{item_list}}
        </tbody>
        <tfoot>
            <tr>
                <td colspan="3"><strong>Total</strong></td>
                <td><strong>{{total_amount}}</strong></td>
            </tr>
        </tfoot>
    </table>
</body>
</html>
''';
      case TemplateType.receipt:
        return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; text-align: center; }
        .header { margin-bottom: 30px; }
        .company-name { font-size: 20px; font-weight: bold; }
        .amount-box { border: 2px solid #000; padding: 20px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-name">{{company_name}}</div>
    </div>
    
    <h2>PAYMENT RECEIPT</h2>
    
    <p>Receipt #: {{document_number}}</p>
    <p>Date: {{document_date}}</p>
    <p>Received From: {{party_name}}</p>
    
    <div class="amount-box">
        <div>AMOUNT RECEIVED</div>
        <div>{{currency_symbol}} {{total_amount}}</div>
    </div>
</body>
</html>
''';
      default:
        return '<!-- Template content for $_selectedType -->';
    }
  }

  void _saveTemplate() {
    if (!_formKey.currentState!.validate()) return;

    final template = PrintTemplate(
      id:
          widget.template?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _selectedType,
      content: _contentController.text,
      variables: _variables,
      description: _descriptionController.text.trim(),
      isDefault: _isDefault,
      isActive: true,
      createdBy: 'current_user', // Would come from auth context
      createdAt: widget.template?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(template);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.template == null ? 'Create Template' : 'Edit Template',
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveTemplate)],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Template Info Section
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Template Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter template name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Template Type',
                        border: OutlineInputBorder(),
                      ),
                      items: TemplateType.all.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_formatTemplateType(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          _contentController.text =
                              _getDefaultTemplateContent();
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),

                    SwitchListTile(
                      title: Text('Set as Default'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Template Content Section
            Expanded(
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Template Content',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showVariableHelp,
                            icon: Icon(Icons.help_outline),
                            label: Text('Variables'),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      Expanded(
                        child: TextFormField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            hintText: 'Enter HTML template content...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter template content';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTemplate,
                      child: Text('Save Template'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVariableHelp() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final commonVariables = [
          TemplateVariables.companyName,
          TemplateVariables.companyAddress,
          TemplateVariables.documentNumber,
          TemplateVariables.documentDate,
          TemplateVariables.partyName,
          TemplateVariables.partyAddress,
          TemplateVariables.totalAmount,
        ];

        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available Variables',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Use these variables in your template by wrapping them in double curly braces:',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: commonVariables.length,
                  itemBuilder: (context, index) {
                    final variable = commonVariables[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(variable),
                        trailing: IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            // Copy to clipboard functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied: $variable')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTemplateType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

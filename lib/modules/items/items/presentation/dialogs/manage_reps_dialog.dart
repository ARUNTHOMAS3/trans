import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ManageRepsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> reps;
  final List<Map<String, dynamic>> brands;
  final Future<List<Map<String, dynamic>>> Function(String query)? onSearch;
  final Future<Map<String, dynamic>> Function({
    required String name,
    String? number,
    String? brandId,
    String? division,
    String? area,
  })
  onCreate;
  final ValueChanged<Map<String, dynamic>>? onSelect;

  const ManageRepsDialog({
    super.key,
    required this.reps,
    required this.brands,
    required this.onCreate,
    this.onSearch,
    this.onSelect,
  });

  @override
  State<ManageRepsDialog> createState() => _ManageRepsDialogState();
}

class _ManageRepsDialogState extends State<ManageRepsDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _numberCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();

  List<Map<String, dynamic>> _reps = const [];
  bool _showCreateForm = false;
  bool _isSaving = false;
  String? _selectedBrandId;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _reps = List<Map<String, dynamic>>.from(widget.reps);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  String _brandOrDivision(Map<String, dynamic> rep) {
    final brand = (rep['brand_name'] ?? rep['brand'] ?? '').toString().trim();
    if (brand.isNotEmpty) return brand;
    return (rep['division'] ?? '').toString().trim();
  }

  String _repLabel(Map<String, dynamic> rep) {
    final name = (rep['name'] ?? rep['rep_name'] ?? '').toString().trim();
    final brandOrDivision = _brandOrDivision(rep);
    if (brandOrDivision.isEmpty) return name;
    return '$name ($brandOrDivision)';
  }

  String? _validatePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Phone number is required.';
    if (!RegExp(r'^\d{10}$').hasMatch(trimmed)) {
      return 'Phone number must be exactly 10 digits.';
    }
    return null;
  }

  bool get _canSave {
    return _nameCtrl.text.trim().isNotEmpty &&
        _numberCtrl.text.trim().isNotEmpty &&
        _selectedBrandId != null &&
        _selectedBrandId!.trim().isNotEmpty &&
        _areaCtrl.text.trim().isNotEmpty &&
        _validatePhone(_numberCtrl.text) == null &&
        !_isSaving;
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _reps = List<Map<String, dynamic>>.from(widget.reps));
      return;
    }
    if (widget.onSearch != null) {
      final rows = await widget.onSearch!(query);
      if (!mounted) return;
      setState(() => _reps = rows);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _reps = widget.reps.where((rep) {
        final label = _repLabel(rep).toLowerCase();
        return label.contains(lower);
      }).toList();
    });
  }

  Future<void> _create() async {
    if (_isSaving) return;
    final name = _nameCtrl.text.trim();
    final phoneError = _validatePhone(_numberCtrl.text);
    setState(() => _phoneError = phoneError);
    if (name.isEmpty ||
        phoneError != null ||
        _selectedBrandId == null ||
        _selectedBrandId!.trim().isEmpty ||
        _areaCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final selectedBrand = widget.brands.firstWhere(
        (b) => b['id']?.toString() == _selectedBrandId,
        orElse: () => const {},
      );
      final selectedBrandName = (selectedBrand['name'] ??
              selectedBrand['brand_name'] ??
              '')
          .toString()
          .trim();
      final created = await widget.onCreate(
        name: name,
        number: _numberCtrl.text.trim(),
        brandId: _selectedBrandId,
        division: selectedBrandName.isEmpty ? null : selectedBrandName,
        area: _areaCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _reps = [created, ..._reps];
        _showCreateForm = false;
        _nameCtrl.clear();
        _numberCtrl.clear();
        _areaCtrl.clear();
        _selectedBrandId = null;
        _phoneError = null;
      });
      // Save + immediately select the newly created rep in caller dropdown.
      widget.onSelect?.call(created);
      Navigator.of(context).pop(created);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 640,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage Rep',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchCtrl,
                      hintText: 'Search reps',
                      height: 40,
                      onChanged: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ZButton.primary(
                    label: _showCreateForm ? 'Close New' : 'New',
                    onPressed: () {
                      setState(() => _showCreateForm = !_showCreateForm);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_showCreateForm) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameCtrl,
                        hintText: 'Name',
                        label: 'Name',
                        height: 40,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _numberCtrl,
                        hintText: 'Phone Number / Mobile Number',
                        label: 'Phone Number / Mobile Number',
                        height: 40,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        errorText: _phoneError,
                        onChanged: (value) {
                          setState(() {
                            _phoneError = _validatePhone(value);
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      FormDropdown<String>(
                        value: _selectedBrandId,
                        items: widget.brands
                            .map((b) => b['id']?.toString() ?? '')
                            .where((id) => id.isNotEmpty)
                            .toList(),
                        hint: 'Select brand or division',
                        onChanged: (v) =>
                            setState(() => _selectedBrandId = v),
                        displayStringForValue: (id) {
                          final brand = widget.brands.firstWhere(
                            (b) => b['id']?.toString() == id,
                            orElse: () => const {},
                          );
                          return (brand['name'] ?? brand['brand_name'] ?? id)
                              .toString();
                        },
                        showSearch: true,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _areaCtrl,
                        hintText: 'Area',
                        label: 'Area',
                        height: 40,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ZButton.primary(
                            label: 'Save and Select',
                            loading: _isSaving,
                            onPressed: _canSave ? _create : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Rep List',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: _reps.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('No reps found'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final rep = _reps[index];
                          return ListTile(
                            dense: true,
                            title: Text(_repLabel(rep)),
                            subtitle: Text(
                              [
                                rep['division']?.toString(),
                                rep['area']?.toString(),
                              ].where((e) => (e ?? '').isNotEmpty).join(' • '),
                            ),
                            onTap: () {
                              widget.onSelect?.call(rep);
                              Navigator.of(context).pop(rep);
                            },
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppTheme.borderLight),
                        itemCount: _reps.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

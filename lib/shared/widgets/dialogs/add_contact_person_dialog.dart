import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../inputs/dropdown_input.dart';

class AddContactPersonDialog extends StatefulWidget {
  const AddContactPersonDialog({super.key});

  @override
  State<AddContactPersonDialog> createState() => _AddContactPersonDialogState();
}

class _AddContactPersonDialogState extends State<AddContactPersonDialog> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _workPhoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _skypeCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();

  String _salutation = 'Salutation';
  String _workPhonePrefix = '+91';
  String _mobilePrefix = '+91';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _workPhoneCtrl.dispose();
    _mobileCtrl.dispose();
    _skypeCtrl.dispose();
    _designationCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontFamily: 'Inter'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIcon != null
          ? const BoxConstraints(minWidth: 36, maxHeight: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _formRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required double width,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      height: 40,
      child: FormDropdown<String>(
        value: value,
        hint: hint,
        items: items,
        showSearch: false,
        onChanged: onChanged,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
        itemBuilder: (item, isSelected, isHovered) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF3B82F6)
                  : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isHovered
                    ? Colors.white
                    : (isSelected ? const Color(0xFF111827) : const Color(0xFF374151)),
                fontFamily: 'Inter',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.only(top: 0),
      alignment: Alignment.topCenter,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                color: const Color(0xFFF7FAF9),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      'Add Contact Person',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 24),

              // Content Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Form Fields
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name row
                          _formRow(
                            'Name',
                            Row(
                              children: [
                                _buildDropdownField(
                                  width: 110,
                                  value: _salutation == 'Salutation' ? null : _salutation,
                                  hint: 'Salutation',
                                  items: const ['Mr.', 'Mrs.', 'Ms.', 'Miss', 'Dr.'],
                                  onChanged: (v) {
                                    setState(() {
                                      _salutation = v ?? 'Salutation';
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: _firstNameCtrl,
                                      decoration: _inputDecoration('First Name'),
                                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: _lastNameCtrl,
                                      decoration: _inputDecoration('Last Name'),
                                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Email Address row
                          _formRow(
                            'Email Address',
                            SizedBox(
                              height: 40,
                              child: TextField(
                                controller: _emailCtrl,
                                decoration: _inputDecoration('Email Address'),
                                style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                              ),
                            ),
                          ),

                          // Phone row
                          _formRow(
                            'Phone',
                            Column(
                              children: [
                                Row(
                                  children: [
                                    _buildDropdownField(
                                      width: 75,
                                      value: _workPhonePrefix,
                                      hint: '+91',
                                      items: const ['+91', '+1', '+44', '+971'],
                                      onChanged: (v) {
                                        setState(() {
                                          _workPhonePrefix = v ?? '+91';
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                          controller: _workPhoneCtrl,
                                          decoration: _inputDecoration('Work Phone'),
                                          style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildDropdownField(
                                      width: 75,
                                      value: _mobilePrefix,
                                      hint: '+91',
                                      items: const ['+91', '+1', '+44', '+971'],
                                      onChanged: (v) {
                                        setState(() {
                                          _mobilePrefix = v ?? '+91';
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                          controller: _mobileCtrl,
                                          decoration: _inputDecoration('Mobile'),
                                          style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Skype Name/Number row
                          _formRow(
                            'Skype Name/Number',
                            SizedBox(
                              height: 40,
                              child: TextField(
                                controller: _skypeCtrl,
                                decoration: _inputDecoration(
                                  'Skype Name/Number',
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 10, right: 4),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00AFF0),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'S',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Inter',
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                              ),
                            ),
                          ),

                          // Other Details row
                          _formRow(
                            'Other Details',
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: _designationCtrl,
                                      decoration: _inputDecoration('Designation'),
                                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: _departmentCtrl,
                                      decoration: _inputDecoration('Department'),
                                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Profile Image Box
                    Expanded(
                      flex: 3,
                      child: CustomPaint(
                        painter: DashedRectPainter(
                          color: const Color(0xFFCBD5E1),
                          strokeWidth: 1.0,
                          gap: 4.0,
                        ),
                        child: Container(
                          height: 220,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.arrowUp,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Drag & Drop Profile Image',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Supported Files: jpg, jpeg, png, gif, bmp\nMaximum File Size: 5MB',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Inter',
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () {},
                                child: const Text(
                                  'Upload File',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB),
                                    decoration: TextDecoration.underline,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 24),

              // Actions Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'salutation': _salutation,
                          'firstName': _firstNameCtrl.text,
                          'lastName': _lastNameCtrl.text,
                          'email': _emailCtrl.text,
                          'workPhonePrefix': _workPhonePrefix,
                          'workPhone': _workPhoneCtrl.text,
                          'mobilePrefix': _mobilePrefix,
                          'mobile': _mobileCtrl.text,
                          'skype': _skypeCtrl.text,
                          'designation': _designationCtrl.text,
                          'department': _departmentCtrl.text,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                      ),
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
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.0,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    _addDashedLine(path, const Offset(0, 0), Offset(size.width, 0));
    _addDashedLine(path, Offset(size.width, 0), Offset(size.width, size.height));
    _addDashedLine(path, Offset(size.width, size.height), Offset(0, size.height));
    _addDashedLine(path, Offset(0, size.height), const Offset(0, 0));

    canvas.drawPath(path, paint);
  }

  void _addDashedLine(Path path, Offset start, Offset end) {
    final double distance = (end - start).distance;
    final double dashLength = gap;
    final double spaceLength = gap;
    double currentDistance = 0.0;
    final Offset direction = (end - start) / distance;

    while (currentDistance < distance) {
      final Offset p1 = start + direction * currentDistance;
      currentDistance += dashLength;
      if (currentDistance > distance) {
        currentDistance = distance;
      }
      final Offset p2 = start + direction * currentDistance;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      currentDistance += spaceLength;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

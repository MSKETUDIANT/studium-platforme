import 'package:flutter/material.dart';

class AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppFormField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
              : null),
    );
  }
}

class AppDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  String get _formatted {
    if (value == null) return 'Non définie';
    return '${value!.day.toString().padLeft(2, '0')}/'
        '${value!.month.toString().padLeft(2, '0')}/${value!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(
                    _formatted,
                    style: TextStyle(
                      fontSize: 15,
                      color: value != null
                          ? Colors.black87
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null && value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.clear,
                    size: 18, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}
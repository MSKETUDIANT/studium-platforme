import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/academic_background.dart';
import '../providers/profile_providers.dart';

class AddAcademicPage extends ConsumerStatefulWidget {
  final AcademicBackground? existing;

  const AddAcademicPage({super.key, this.existing});

  @override
  ConsumerState<AddAcademicPage> createState() => _AddAcademicPageState();
}

class _AddAcademicPageState extends ConsumerState<AddAcademicPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _degreeCtrl;
  late final TextEditingController _universityCtrl;
  late final TextEditingController _averageCtrl;

  int? _year;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  bool get _canSave =>
      _degreeCtrl.text.trim().isNotEmpty &&
      _universityCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _degreeCtrl = TextEditingController(text: widget.existing?.degree ?? '');
    _universityCtrl =
        TextEditingController(text: widget.existing?.university ?? '');
    _averageCtrl = TextEditingController(
      text: widget.existing?.average?.toString() ?? '',
    );

    _year = widget.existing?.year;

    _degreeCtrl.addListener(_refresh);
    _universityCtrl.addListener(_refresh);
    _averageCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _degreeCtrl.removeListener(_refresh);
    _universityCtrl.removeListener(_refresh);
    _averageCtrl.removeListener(_refresh);

    _degreeCtrl.dispose();
    _universityCtrl.dispose();
    _averageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickYear() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year ?? now.year),
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 5),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Sélectionner l’année',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (picked != null) {
      setState(() => _year = picked.year);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userId = ref.read(currentUserIdProvider) ?? '';

      final background = AcademicBackground(
        id: widget.existing?.id ?? '',
        userId: userId,
        degree: _degreeCtrl.text.trim(),
        university: _universityCtrl.text.trim(),
        year: _year,
        average: _averageCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_averageCtrl.text.trim().replaceAll(',', '.')),
      );

      final notifier = ref.read(academicBackgroundsProvider.notifier);

      if (_isEdit) {
        await notifier.updateItem(background);
      } else {
        await notifier.add(background);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1D2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Modifier la formation' : 'Ajouter une formation',
          style: const TextStyle(
            color: Color(0xFF1A1D2E),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader('Diplôme'),
                const SizedBox(height: 12),
                _FormCard(
                  children: [
                    _StyledField(
                      controller: _degreeCtrl,
                      label: 'Intitulé du diplôme',
                      hint: 'Ex : Licence Informatique / Bac scientifique',
                      icon: Icons.school_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _StyledField(
                      controller: _universityCtrl,
                      label: 'Établissement',
                      hint: 'Ex : Université de Tunis El Manar',
                      icon: Icons.account_balance_outlined,
                      required: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionHeader('Résultats'),
                const SizedBox(height: 12),
                _FormCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _YearPickerField(
                            year: _year,
                            onPick: _pickYear,
                            onClear: () => setState(() => _year = null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StyledField(
                            controller: _averageCtrl,
                            label: 'Moyenne',
                            hint: 'Sur 20',
                            icon: Icons.grade_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }

                              final parsed = double.tryParse(
                                value.trim().replaceAll(',', '.'),
                              );

                              if (parsed == null) return 'Valeur invalide';
                              if (parsed < 0 || parsed > 20) {
                                return 'Entre 0 et 20';
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_loading || !_canSave) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4880FF),
                      disabledBackgroundColor:
                          const Color(0xFF4880FF).withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEdit ? Icons.check : Icons.add,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEdit
                                    ? 'Modifier la formation'
                                    : 'Ajouter la formation',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (!_canSave) ...[
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Renseignez le diplôme et l’établissement pour continuer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF4880FF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D2E),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;

  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFFD1D5DB),
        ),
        prefixIcon: icon == null
            ? null
            : Icon(
                icon,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4880FF),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
      ),
      validator: validator ??
          (required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Champ requis';
                  }
                  return null;
                }
              : null),
    );
  }
}

class _YearPickerField extends StatelessWidget {
  final int? year;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _YearPickerField({
    required this.year,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = year != null;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? const Color(0xFF4880FF).withValues(alpha: 0.45)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: hasValue
                  ? const Color(0xFF4880FF)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Année',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? '$year' : 'Ex : 2024',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue
                          ? const Color(0xFF1A1D2E)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.clear,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              )
            else
              const Icon(
                Icons.expand_more,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
          ],
        ),
      ),
    );
  }
}
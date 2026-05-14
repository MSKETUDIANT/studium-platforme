import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/experience.dart';
import '../providers/profile_providers.dart';

class AddExperiencePage extends ConsumerStatefulWidget {
  final Experience? existing;

  const AddExperiencePage({super.key, this.existing});

  @override
  ConsumerState<AddExperiencePage> createState() => _AddExperiencePageState();
}

class _AddExperiencePageState extends ConsumerState<AddExperiencePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _descriptionCtrl;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  bool get _canSave =>
      _companyCtrl.text.trim().isNotEmpty &&
      _positionCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _companyCtrl     = TextEditingController(text: widget.existing?.company ?? '');
    _positionCtrl    = TextEditingController(text: widget.existing?.position ?? '');
    _descriptionCtrl = TextEditingController(text: widget.existing?.description ?? '');

    _startDate = widget.existing?.startDate;
    _endDate   = widget.existing?.endDate;

    _companyCtrl.addListener(_refresh);
    _positionCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _companyCtrl.removeListener(_refresh);
    _positionCtrl.removeListener(_refresh);

    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final now     = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 1),
      helpText:    isStart ? 'Sélectionner la date de début' : 'Sélectionner la date de fin',
      cancelText:  'Annuler',
      confirmText: 'Confirmer',
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'La date de fin doit être postérieure à la date de début.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final experience = Experience(
        id:               widget.existing?.id ?? '',
        studentProfileId: userId,
        company:          _companyCtrl.text.trim(),
        position:         _positionCtrl.text.trim(),
        startDate:        _startDate,
        endDate:          _endDate,
        description:      _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
      );

      final repo = ref.read(profileRepositoryProvider);
      if (_isEdit) {
        await repo.updateExperience(experience);
      } else {
        await repo.addExperience(experience);
      }
      ref.invalidate(experiencesProvider);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('save error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur : $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non définie';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
          _isEdit ? 'Modifier l\u2019expérience' : 'Ajouter une expérience',
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
                const _SectionHeader('Informations'),
                const SizedBox(height: 12),
                _FormCard(
                  children: [
                    _StyledField(
                      controller: _companyCtrl,
                      label: 'Entreprise',
                      hint: 'Ex : Talan Tunisia',
                      icon: Icons.business_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _StyledField(
                      controller: _positionCtrl,
                      label: 'Poste',
                      hint: 'Ex : Stagiaire développeur',
                      icon: Icons.work_outline,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _StyledField(
                      controller: _descriptionCtrl,
                      label: 'Description',
                      hint: 'Décrivez vos missions, outils utilisés et responsabilités...',
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionHeader('Période'),
                const SizedBox(height: 12),
                _FormCard(
                  children: [
                    _DateField(
                      label: 'Date de début',
                      value: _formatDate(_startDate),
                      hint: 'Non définie',
                      onTap: () => _pickDate(isStart: true),
                      onClear: _startDate == null
                          ? null
                          : () => setState(() => _startDate = null),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: 'Date de fin',
                      value: _formatDate(_endDate),
                      hint: 'Laisser vide si en cours',
                      onTap: () => _pickDate(isStart: false),
                      onClear: _endDate == null
                          ? null
                          : () => setState(() => _endDate = null),
                    ),
                    if (_startDate != null && _endDate == null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                            SizedBox(width: 6),
                            Text(
                              'Poste actuel',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          const Color(0xFF4880FF).withValues(alpha: 0.40),
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
                              Icon(_isEdit ? Icons.check : Icons.add, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _isEdit
                                    ? 'Modifier l\u2019expérience'
                                    : 'Ajouter l\u2019expérience',
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
                      'Renseignez l\u2019entreprise et le poste pour continuer',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
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

// ─── Section Header ───────────────────────────────────────────────────────────

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

// ─── Form Card ────────────────────────────────────────────────────────────────

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

// ─── Styled Field ─────────────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
  final IconData? icon;
  final TextInputAction textInputAction;

  const _StyledField({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.icon,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
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
          borderSide: const BorderSide(color: Color(0xFF4880FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) return 'Champ requis';
              return null;
            }
          : null,
    );
  }
}

// ─── Date Field ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final String? hint;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != 'Non définie';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? const Color(0xFF4880FF).withValues(alpha: 0.35)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: hasValue
                  ? const Color(0xFF4880FF)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 3),
                  Text(
                    hasValue ? value : (hint ?? 'Non définie'),
                    style: TextStyle(
                      fontSize: 14,
                      color: hasValue
                          ? const Color(0xFF1A1D2E)
                          : const Color(0xFFD1D5DB),
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasValue && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.clear,
                    size: 16, color: Color(0xFF9CA3AF)),
              )
            else
              const Icon(Icons.expand_more,
                  size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
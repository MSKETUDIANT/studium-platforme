import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../documents/domain/entities/document.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../../../programs/domain/entities/program.dart';
import '../../../programs/presentation/providers/program_providers.dart';
import '../providers/application_providers.dart';

const _kNavy  = Color(0xFF1A1D2E);
const _kBlue  = Color(0xFF4880FF);
const _kGrey  = Color(0xFF9CA3AF);
const _kBg    = Color(0xFFF4F6FB);
const _kBorder = Color(0xFFE5E7EB);

class NewApplicationWizard extends ConsumerStatefulWidget {
  final Program? program;
  const NewApplicationWizard({super.key, this.program});

  @override
  ConsumerState<NewApplicationWizard> createState() =>
      _NewApplicationWizardState();
}

class _NewApplicationWizardState
    extends ConsumerState<NewApplicationWizard> {
  final _pageController    = PageController();
  final _motivationCtrl    = TextEditingController();
  Program? _selectedProgram;
  int _currentStep         = 0;
  bool _submitting         = false;
  String? _programSearchQ;

  static const _steps = ['Programme', 'Dossier', 'Récapitulatif'];

  @override
  void initState() {
    super.initState();
    _selectedProgram = widget.program;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _motivationCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 0 && _selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un programme')),
      );
      return;
    }
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    if (_selectedProgram == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(myApplicationsProvider.notifier).submit(
            programId: _selectedProgram!.id,
          );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Candidature soumise avec succès'),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _kNavy),
          onPressed: () => context.pop(),
        ),
        title: const Text('Nouvelle candidature',
            style: TextStyle(
                color: _kNavy,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _StepIndicator(
              current: _currentStep, labels: _steps),
        ),
      ),
      body: PageView(
        controller:   _pageController,
        physics:      const NeverScrollableScrollPhysics(),
        children: [
          _StepProgram(
            selected:   _selectedProgram,
            searchQuery: _programSearchQuery,
            onSearchChanged: (q) =>
                setState(() => _programSearchQ = q),
            onSelect: (p) =>
                setState(() => _selectedProgram = p),
          ),
          _StepDocuments(),
          _StepRecap(
            program:        _selectedProgram,
            motivationCtrl: _motivationCtrl,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String get _programSearchQuery => _programSearchQ ?? '';

  Widget _buildBottomBar() {
    final isLast = _currentStep == _steps.length - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: _back,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                side: const BorderSide(color: _kBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retour',
                  style: TextStyle(color: _kNavy)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _GradientButton(
              onTap: isLast ? (_submitting ? null : _submit) : _next,
              label: isLast
                  ? (_submitting ? 'Envoi en cours…' : 'Soumettre')
                  : 'Suivant',
              loading: _submitting,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final List<String> labels;
  const _StepIndicator({required this.current, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: List.generate(labels.length, (i) {
          final done   = i < current;
          final active = i == current;
          final color  = done || active ? _kBlue : _kGrey;
          return Expanded(
            child: Row(children: [
              if (i > 0) ...[
                Expanded(
                  child: Container(
                    height: 2,
                    color: done ? _kBlue : _kBorder,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Column(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: done || active
                        ? _kBlue
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                      : Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? Colors.white
                                  : _kGrey,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: color,
                  ),
                ),
              ]),
              if (i < labels.length - 1) const SizedBox(width: 6),
            ]),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Programme ────────────────────────────────────────────────────────

class _StepProgram extends ConsumerWidget {
  final Program? selected;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Program> onSelect;

  const _StepProgram({
    required this.selected,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If a program was pre-selected (coming from program detail), show it read-only
    if (selected != null) {
      return _buildPreselected(selected!);
    }

    final programsAsync = ref.watch(programsProvider);
    return programsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kBlue)),
      error: (e, _) =>
          Center(child: Text(e.toString())),
      data: (programs) {
        final filtered = searchQuery.isEmpty
            ? programs
            : programs.where((p) {
                final q = searchQuery.toLowerCase();
                return p.programName.toLowerCase().contains(q) ||
                    p.universityName.toLowerCase().contains(q) ||
                    (p.country?.toLowerCase().contains(q) ?? false);
              }).toList();

        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un programme…',
                hintStyle: const TextStyle(color: _kGrey),
                prefixIcon: const Icon(Icons.search, color: _kGrey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _kBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final p = filtered[i];
                return _ProgramTile(
                  program:  p,
                  selected: selected?.id == p.id,
                  onTap:    () => onSelect(p),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildPreselected(Program p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Programme sélectionné',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kGrey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBlue.withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.programName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kNavy)),
                const SizedBox(height: 4),
                Text(p.universityName,
                    style: const TextStyle(
                        fontSize: 14, color: _kGrey)),
                if (p.country != null) ...[
                  const SizedBox(height: 4),
                  Text(p.country!,
                      style: const TextStyle(
                          fontSize: 13, color: _kGrey)),
                ],
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  if (p.level != null) _Tag(p.levelLabel),
                  if (p.language != null) _Tag(p.language!),
                  _Tag(p.costLabel),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(children: [
              Icon(Icons.check_circle_outline,
                  color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Appuyez sur "Suivant" pour continuer avec ce programme.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final Program program;
  final bool selected;
  final VoidCallback onTap;
  const _ProgramTile(
      {required this.program,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? _kBlue
                  : _kBorder,
              width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(program.programName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kNavy),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(program.universityName,
                    style: const TextStyle(
                        fontSize: 12, color: _kGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (program.country != null) ...[
                  const SizedBox(height: 2),
                  Text(program.country!,
                      style: const TextStyle(
                          fontSize: 11, color: _kGrey)),
                ],
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle,
                color: _kBlue, size: 20),
        ]),
      ),
    );
  }
}

// ─── Step 2: Dossier documents ────────────────────────────────────────────────

class _StepDocuments extends ConsumerWidget {
  const _StepDocuments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);

    return docsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kBlue)),
      error: (_, __) => const Center(
          child: Text('Impossible de charger les documents')),
      data: (docs) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre dossier',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kNavy),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tous vos documents uploadés seront inclus dans votre candidature.',
                style: TextStyle(
                    fontSize: 13, color: _kGrey, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aucun document uploadé. Ajoutez des documents dans votre profil avant de soumettre.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E)),
                      ),
                    ),
                  ]),
                )
              else
                ...docs.map((d) => _DocumentRow(doc: d)),
            ],
          ),
        );
      },
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final Document doc;
  const _DocumentRow({required this.doc});

  IconData get _icon => switch (doc.type) {
    DocumentType.cv             => Icons.description_outlined,
    DocumentType.transcript     => Icons.school_outlined,
    DocumentType.recommendation => Icons.verified_user_outlined,
    DocumentType.passport       => Icons.badge_outlined,
    _                           => Icons.insert_drive_file_outlined,
  };

  Color get _statusColor => switch (doc.status) {
    DocumentStatus.approved   => const Color(0xFF10B981),
    DocumentStatus.rejected   => const Color(0xFFEF4444),
    DocumentStatus.underReview => const Color(0xFFF59E0B),
    _                          => _kGrey,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        Icon(_icon, color: _kBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.typeLabel,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kNavy)),
              Text(doc.fileName,
                  style: const TextStyle(
                      fontSize: 11, color: _kGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            doc.statusLabel,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _statusColor),
          ),
        ),
      ]),
    );
  }
}

// ─── Step 3: Récapitulatif ────────────────────────────────────────────────────

class _StepRecap extends StatelessWidget {
  final Program? program;
  final TextEditingController motivationCtrl;
  const _StepRecap(
      {required this.program, required this.motivationCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Récapitulatif',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kNavy)),
          const SizedBox(height: 20),

          // Programme recap
          if (program != null) ...[
            _SectionLabel('Programme'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(program!.programName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kNavy)),
                  const SizedBox(height: 3),
                  Text(program!.universityName,
                      style:
                          const TextStyle(fontSize: 13, color: _kGrey)),
                  if (program!.country != null) ...[
                    const SizedBox(height: 2),
                    Text(program!.country!,
                        style: const TextStyle(
                            fontSize: 12, color: _kGrey)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Motivation optionnelle
          _SectionLabel('Message de motivation (optionnel)'),
          TextField(
            controller: motivationCtrl,
            maxLines: 5,
            maxLength: 800,
            decoration: InputDecoration(
              hintText:
                  'Expliquez votre motivation pour ce programme…',
              hintStyle:
                  const TextStyle(color: _kGrey, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _kBlue, width: 2),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),

          // Confirmation message
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _kBlue.withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: _kBlue, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'En soumettant, vous confirmez que vos informations sont exactes et vos documents à jour.',
                    style: TextStyle(
                        fontSize: 13,
                        color: _kBlue,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kGrey)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kBlue)),
    );
  }
}

// ─── Gradient button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool loading;
  const _GradientButton(
      {required this.onTap, required this.label, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF4880FF), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
        ),
      ),
    );
  }
}

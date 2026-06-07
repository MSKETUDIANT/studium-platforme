import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../documents/domain/entities/document.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../../../programs/domain/entities/program.dart';
import '../../../programs/presentation/providers/program_providers.dart';
import '../providers/application_providers.dart';

// Design tokens
const _kNavy   = Color(0xFF0B1852);
const _kBlue   = Color(0xFF4880FF);
const _kGreen  = Color(0xFF10B981);
const _kOrange = Color(0xFFF59E0B);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);
const _kBg     = Color(0xFFF7F8FC);

class NewApplicationWizard extends ConsumerStatefulWidget {
  final Program? program;
  const NewApplicationWizard({super.key, this.program});

  @override
  ConsumerState<NewApplicationWizard> createState() =>
      _NewApplicationWizardState();
}

class _NewApplicationWizardState extends ConsumerState<NewApplicationWizard> {
  final _pageController = PageController();
  final _motivationCtrl = TextEditingController();
  Program? _selectedProgram;
  int     _currentStep  = 0;
  bool    _submitting   = false;
  bool    _savingDraft  = false;
  String? _programSearchQ;
  final Set<String> _selectedDocIds = {};

  static const _steps = ['Programme', 'Dossier', 'Recapitulatif'];

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
        _snack('Veuillez selectionner un programme', isError: true),
      );
      return;
    }
    if (_currentStep == 0 && (_selectedProgram?.isExpired ?? false)) {
      _showExpiredDialog();
      return;
    }
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delai depasse',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _kNavy)),
        content: Text(
          'La date limite de candidature pour "${_selectedProgram?.programName}" est depassee.\nIl n\'est plus possible de postuler.',
          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris',
                style: TextStyle(color: _kBlue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_selectedProgram == null) return;
    setState(() => _savingDraft = true);
    try {
      await ref.read(myApplicationsProvider.notifier).saveDraft(
            programId: _selectedProgram!.id,
          );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Brouillon enregistre', color: const Color(0xFF6366F1)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingDraft = false);
        ScaffoldMessenger.of(context).showSnackBar(
          _snack(e.toString(), isError: true),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedProgram == null) return;
    if (_selectedProgram!.isExpired) { _showExpiredDialog(); return; }
    setState(() => _submitting = true);
    try {
      await ref.read(myApplicationsProvider.notifier).submit(
            programId: _selectedProgram!.id,
          );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Candidature soumise avec succes', color: _kGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          _snack(e.toString(), isError: true),
        );
      }
    }
  }

  SnackBar _snack(String msg, {bool isError = false, Color? color}) => SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: isError ? const Color(0xFFEF4444) : (color ?? _kGreen),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(children: [
          // Header gradient
          _WizardHeader(
            currentStep: _currentStep,
            steps: _steps,
            onClose: () => context.pop(),
          ),
          // Body
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepProgram(
                  selected: _selectedProgram,
                  searchQuery: _programSearchQ ?? '',
                  onSearchChanged: (q) => setState(() => _programSearchQ = q),
                  onSelect: (p) => setState(() => _selectedProgram = p),
                ),
                _StepDocuments(
                  program: _selectedProgram,
                  selected: _selectedDocIds,
                  onToggle: (id) => setState(() {
                    if (_selectedDocIds.contains(id)) {
                      _selectedDocIds.remove(id);
                    } else {
                      _selectedDocIds.add(id);
                    }
                  }),
                ),
                _StepRecap(
                  program: _selectedProgram,
                  motivationCtrl: _motivationCtrl,
                  selectedDocIds: _selectedDocIds,
                ),
              ],
            ),
          ),
        ]),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentStep == _steps.length - 1;
    final busy   = _submitting || _savingDraft;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                onPressed: busy ? null : _back,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  side: const BorderSide(color: _kBorder, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  foregroundColor: _kNavy,
                ),
                child: const Text('Retour',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(width: 12),
            ],
            if (isLast) ...[
              OutlinedButton(
                onPressed: busy ? null : _saveDraft,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  side: const BorderSide(color: _kBorder, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  foregroundColor: _kNavy,
                ),
                child: _savingDraft
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _kNavy))
                    : const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.bookmark_outline, size: 16),
                        SizedBox(width: 6),
                        Text('Brouillon',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GradientButton(
                  onTap: busy ? null : _submit,
                  label: _submitting ? 'Envoi...' : 'Soumettre',
                  loading: _submitting,
                ),
              ),
            ] else
              Expanded(
                child: _GradientButton(
                  onTap: busy ? null : _next,
                  label: 'Suivant',
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ─── Header avec step indicator ──────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  final VoidCallback onClose;
  const _WizardHeader({
    required this.currentStep,
    required this.steps,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07112B), Color(0xFF1A3A8F), Color(0xFF1A67D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 16, 6),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                onPressed: onClose,
              ),
              const Expanded(
                child: Text(
                  'Nouvelle candidature',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w800, letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ]),
          ),
          _StepIndicator(current: currentStep, labels: steps),
          const SizedBox(height: 10),
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
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 4),
        child: Row(
          children: List.generate(labels.length, (i) {
            final done   = i < current;
            final active = i == current;
            return Expanded(
              child: Row(children: [
                if (i > 0) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: done
                            ? _kGreen
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: done
                          ? _kGreen
                          : active
                              ? Colors.white
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done
                            ? _kGreen
                            : active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                        width: 2,
                      ),
                      boxShadow: active
                          ? [BoxShadow(
                              color: Colors.white.withValues(alpha: 0.35),
                              blurRadius: 10, spreadRadius: 0,
                            )]
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: active
                                    ? _kBlue
                                    : Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: done
                          ? _kGreen
                          : active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ]),
              ]),
            );
          }),
        ),
      ),
      // Barre de progression
      Stack(children: [
        Container(height: 3, color: Colors.white.withValues(alpha: 0.08)),
        AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
          widthFactor: (current + 1) / labels.length,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_kGreen, Color(0xFF34D399)]),
            ),
          ),
        ),
      ]),
    ]);
  }
}

// ─── Step 1 : Programme ───────────────────────────────────────────────────────

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
    if (selected != null) return _buildPreselected(selected!);

    final programsAsync = ref.watch(programsProvider);
    return programsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
      error: (e, _) => Center(
        child: Text(e.toString(), style: const TextStyle(color: _kGrey)),
      ),
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
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 14, color: _kNavy),
              decoration: InputDecoration(
                hintText: 'Rechercher un programme...',
                hintStyle: const TextStyle(color: _kGrey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _kGrey, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kBlue, width: 2),
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off_rounded, size: 48, color: _kGrey.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('Aucun programme trouve',
                      style: TextStyle(color: _kGrey, fontSize: 14)),
                ]),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ProgramTile(
                  program: filtered[i],
                  selected: selected?.id == filtered[i].id,
                  onTap: () => onSelect(filtered[i]),
                ),
              ),
            ),
        ]);
      },
    );
  }

  Widget _buildPreselected(Program p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Programme selectionne'),
        _ProgramCard(program: p).animate().fadeIn(delay: 60.ms).slideY(begin: .03),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: _kGreen, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Programme pret. Appuyez sur Suivant pour continuer.',
                style: TextStyle(
                  fontSize: 13.5, color: Color(0xFF065F46),
                  fontWeight: FontWeight.w600, height: 1.4,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final Program program;
  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Bandeau haut
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B1852), Color(0xFF1A3A8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                program.programName,
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                program.universityName,
                style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
          // Infos bas
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (program.country != null)
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: _kGrey),
                  const SizedBox(width: 4),
                  Text(program.country!,
                      style: const TextStyle(fontSize: 13, color: _kGrey)),
                ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (program.level != null) _LevelTag(program.levelLabel),
                if (program.language != null) _Tag(program.language!, color: _kBlue),
                _Tag(program.costLabel, color: const Color(0xFF059669)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final Program program;
  final bool selected;
  final VoidCallback onTap;
  const _ProgramTile({required this.program, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _kBlue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kBlue : _kBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _kBlue.withValues(alpha: 0.12), blurRadius: 10)]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(program.programName,
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: selected ? _kBlue : _kNavy,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(program.universityName,
                  style: const TextStyle(fontSize: 12, color: _kGrey),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (program.country != null) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 11, color: _kGrey),
                  const SizedBox(width: 2),
                  Text(program.country!,
                      style: const TextStyle(fontSize: 11, color: _kGrey)),
                ]),
              ],
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (program.level != null) _LevelTag(program.levelLabel),
                _Tag(program.costLabel, color: const Color(0xFF059669)),
              ]),
            ]),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: selected ? _kBlue : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? _kBlue : _kBorder, width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── Step 2 : Dossier ─────────────────────────────────────────────────────────

class _StepDocuments extends ConsumerWidget {
  final Program? program;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _StepDocuments({
    required this.program,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);
    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
      error: (_, __) => const Center(child: Text('Impossible de charger les documents')),
      data: (docs) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionLabel('Votre dossier'),
          const Text(
            'Selectionnez les documents a joindre a votre candidature.',
            style: TextStyle(fontSize: 13.5, color: _kGrey, height: 1.5),
          ),
          const SizedBox(height: 20),

          if (docs.isEmpty) ...[
            // Etat vide avec guidance
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_open_outlined,
                        color: _kOrange, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Aucun document disponible',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                const Text(
                  'Ajoutez vos documents dans votre profil avant de soumettre une candidature.',
                  style: TextStyle(
                    fontSize: 13, color: Color(0xFF92400E), height: 1.5,
                  ),
                ),
                if (program?.requirements != null &&
                    program!.requirements!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Documents requis pour ce programme :',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: Color(0xFF78350F),
                      )),
                  const SizedBox(height: 8),
                  ...program!.requirements!.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(children: [
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                          color: _kOrange, shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(r,
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0xFF92400E))),
                    ]),
                  )),
                ],
              ]),
            ),
          ] else ...[
            // Liste des documents
            ...docs.map((d) => _DocumentRow(
              doc: d,
              isSelected: selected.contains(d.id),
              onToggle: onToggle,
            )),
            const SizedBox(height: 14),
            // Compteur
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected.isEmpty
                    ? _kGrey.withValues(alpha: 0.08)
                    : _kBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected.isEmpty
                      ? _kBorder
                      : _kBlue.withValues(alpha: 0.25),
                ),
              ),
              child: Row(children: [
                Icon(
                  selected.isEmpty
                      ? Icons.info_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: selected.isEmpty ? _kGrey : _kBlue,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  selected.isEmpty
                      ? 'Aucun document selectionne'
                      : '${selected.length} document(s) selectionne(s)',
                  style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600,
                    color: selected.isEmpty ? _kGrey : _kBlue,
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final Document doc;
  final bool isSelected;
  final ValueChanged<String> onToggle;
  const _DocumentRow({required this.doc, required this.isSelected, required this.onToggle});

  IconData get _icon => switch (doc.type) {
    DocumentType.cv             => Icons.description_outlined,
    DocumentType.transcript     => Icons.school_outlined,
    DocumentType.recommendation => Icons.verified_user_outlined,
    DocumentType.passport       => Icons.badge_outlined,
    _                           => Icons.insert_drive_file_outlined,
  };

  Color get _statusColor => switch (doc.status) {
    DocumentStatus.approved    => _kGreen,
    DocumentStatus.rejected    => const Color(0xFFEF4444),
    DocumentStatus.underReview => _kOrange,
    _                          => _kGrey,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(doc.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _kBlue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kBlue : _kBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isSelected
                  ? _kBlue.withValues(alpha: 0.12)
                  : _kGrey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon,
                color: isSelected ? _kBlue : _kGrey, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doc.typeLabel,
                  style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700,
                    color: isSelected ? _kNavy : _kNavy,
                  )),
              const SizedBox(height: 2),
              Text(doc.fileName,
                  style: const TextStyle(fontSize: 11.5, color: _kGrey),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(doc.statusLabel,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _statusColor)),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: isSelected ? _kBlue : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _kBlue : _kBorder, width: 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── Step 3 : Récapitulatif ───────────────────────────────────────────────────

class _StepRecap extends StatelessWidget {
  final Program? program;
  final TextEditingController motivationCtrl;
  final Set<String> selectedDocIds;
  const _StepRecap({
    required this.program,
    required this.motivationCtrl,
    required this.selectedDocIds,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Recapitulatif').animate().fadeIn(delay: 50.ms),

        // Programme
        if (program != null) ...[
          _ProgramCard(program: program!).animate().fadeIn(delay: 80.ms).slideY(begin: .03),
          const SizedBox(height: 20),
        ],

        // Checklist
        const _SectionLabel('Checklist de completude'),
        _ChecklistCard(
          program: program,
          docCount: selectedDocIds.length,
          motivationCtrl: motivationCtrl,
        ).animate().fadeIn(delay: 120.ms),
        const SizedBox(height: 20),

        // Message de motivation
        const _SectionLabel('Message de motivation'),
        TextField(
          controller: motivationCtrl,
          maxLines: 5,
          maxLength: 800,
          style: const TextStyle(fontSize: 14, color: _kNavy, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Expliquez votre motivation pour ce programme (optionnel)...',
            hintStyle: const TextStyle(color: _kGrey, fontSize: 13.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Note de confirmation
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBlue.withValues(alpha: 0.18)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.shield_outlined, color: _kBlue, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'En soumettant, vous confirmez que vos informations sont exactes et vos documents a jour.',
                style: TextStyle(
                  fontSize: 13, color: _kBlue, height: 1.5,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _ChecklistCard extends StatefulWidget {
  final Program? program;
  final int docCount;
  final TextEditingController motivationCtrl;
  const _ChecklistCard({
    required this.program,
    required this.docCount,
    required this.motivationCtrl,
  });

  @override
  State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard> {
  @override
  void initState() {
    super.initState();
    widget.motivationCtrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.motivationCtrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasMotivation = widget.motivationCtrl.text.trim().isNotEmpty;
    final items = [
      (
        label: 'Programme selectionne',
        detail: widget.program?.programName ?? 'Aucun programme',
        done: widget.program != null,
        optional: false,
      ),
      (
        label: 'Documents joints',
        detail: widget.docCount > 0
            ? '${widget.docCount} document(s)'
            : 'Aucun document selectionne',
        done: widget.docCount > 0,
        optional: false,
      ),
      (
        label: 'Message de motivation',
        detail: hasMotivation ? 'Redige' : 'Non renseigne',
        done: hasMotivation,
        optional: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i    = entry.key;
          final item = entry.value;
          final iconColor = item.done
              ? _kGreen
              : item.optional
                  ? _kGrey
                  : _kOrange;

          return Container(
            decoration: BoxDecoration(
              border: i < items.length - 1
                  ? const Border(bottom: BorderSide(color: _kBorder))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.done
                      ? Icons.check_circle_rounded
                      : item.optional
                          ? Icons.radio_button_unchecked_rounded
                          : Icons.warning_amber_rounded,
                  color: iconColor, size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(item.label,
                        style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700,
                          color: item.done ? _kNavy : _kGrey,
                        )),
                    if (item.optional) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('optionnel',
                            style: TextStyle(
                                fontSize: 9.5, color: _kGrey,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(item.detail,
                      style: const TextStyle(fontSize: 12, color: _kGrey)),
                ]),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Widgets communs ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w800,
              color: _kNavy, letterSpacing: -0.2,
            )),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, {this.color = _kBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _LevelTag extends StatelessWidget {
  final String label;
  const _LevelTag(this.label);

  Color get _color {
    if (label.toLowerCase().contains('master')) { return const Color(0xFF7C3AED); }
    if (label.toLowerCase().contains('licence') ||
        label.toLowerCase().contains('bachelor')) { return const Color(0xFF0891B2); }
    if (label.toLowerCase().contains('doctorat') ||
        label.toLowerCase().contains('phd')) { return const Color(0xFFDB2777); }
    return _kBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: _color)),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool loading;
  final IconData? icon;
  const _GradientButton({
    required this.onTap,
    required this.label,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: onTap != null
            ? const LinearGradient(
                colors: [Color(0xFF4880FF), Color(0xFF2D56E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onTap == null ? _kBorder : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
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
                        color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(label,
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800,
                          fontSize: 15, letterSpacing: -0.2,
                        )),
                    if (icon != null) ...[
                      const SizedBox(width: 6),
                      Icon(icon, color: Colors.white, size: 18),
                    ],
                  ]),
          ),
        ),
      ),
    );
  }
}

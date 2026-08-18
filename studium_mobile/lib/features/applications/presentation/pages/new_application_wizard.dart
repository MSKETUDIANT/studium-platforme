import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../documents/domain/entities/document.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../../../programs/domain/entities/program.dart';
import '../../../programs/presentation/providers/program_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/application_providers.dart';

// Design tokens
const _kNavy   = Color(0xFF0B1852);
const _kBlue   = Color(0xFF4880FF);
const _kGreen  = Color(0xFF10B981);
const _kOrange = Color(0xFFF59E0B);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);
const _kBg     = Color(0xFFF7F8FC);

// Mots-clés par typeLabel normalisé pour le matching requis ↔ document
const _kTypeKeywords = <String, List<String>>{
  'cv':                          ['cv', 'curriculum'],
  'releve de notes':             ['releve', 'notes', 'bulletin', 'academique', 'transcript'],
  'lettre de recommandation':    ['recommandation'],
  'passeport':                   ['passeport', 'passport'],
  'lettre de motivation':        ['motivation'],
  'diplome':                     ['diplome', 'licence', 'master', 'bac', 'bachelor', 'brevet'],
  'attestation de langue':       ['attestation', 'langue', 'b1', 'b2', 'c1', 'c2',
                                  'toefl', 'ielts', 'delf', 'dalf', 'tcf', 'linguistique'],
  'justificatif de financement': ['financement', 'bourse', 'bancaire', 'ressources', 'financier'],
};

// Normalise les accents pour la comparaison requis ↔ typeLabel
bool _matchesRequirement(String typeLabel, String req) {
  String n(String s) => s
    .toLowerCase()
    .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e')
    .replaceAll('à', 'a').replaceAll('â', 'a')
    .replaceAll('î', 'i').replaceAll('ô', 'o')
    .replaceAll('û', 'u').replaceAll('ù', 'u')
    .replaceAll('ç', 'c');
  final a = n(typeLabel);
  final b = n(req);
  // Match direct (sous-chaîne)
  if (b.contains(a) || a.contains(b)) return true;
  // Match par mots-clés du type
  final keywords = _kTypeKeywords[a];
  if (keywords != null) {
    return keywords.any((kw) => b.contains(kw));
  }
  return false;
}

class NewApplicationWizard extends ConsumerStatefulWidget {
  final Program? program;
  final String?  draftId;
  final String?  motivationLetter;
  const NewApplicationWizard({super.key, this.program, this.draftId, this.motivationLetter});

  @override
  ConsumerState<NewApplicationWizard> createState() =>
      _NewApplicationWizardState();
}

class _NewApplicationWizardState extends ConsumerState<NewApplicationWizard> {
  late final PageController _pageController;
  final _motivationCtrl = TextEditingController();
  Program? _selectedProgram;
  int     _currentStep  = 0;
  bool    _submitting   = false;
  bool    _savingDraft  = false;
  String? _programSearchQ;
  final Set<String> _selectedDocIds = {};

  static const _steps = ['Programme', 'Dossier', 'Recapitulatif'];

  bool get _isResumingDraft =>
      widget.draftId != null && widget.program != null;

  @override
  void initState() {
    super.initState();
    _selectedProgram = widget.program;
    // Sauter à l'étape Dossier si programme déjà sélectionné (depuis fiche programme ou brouillon)
    final startPage = _selectedProgram != null ? 1 : 0;
    _currentStep    = startPage;
    _pageController = PageController(initialPage: startPage);
    // Pré-sélectionner les docs correspondants aux requis du programme
    if (_selectedProgram != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoSelectMatchingDocs());
    }
    // Lettre de motivation : reprend celle déjà saisie pour ce brouillon,
    // sinon part du modèle de base renseigné dans le profil (à adapter
    // pour ce programme précis, plutôt qu'une lettre générique).
    if (widget.motivationLetter != null && widget.motivationLetter!.trim().isNotEmpty) {
      _motivationCtrl.text = widget.motivationLetter!;
    } else if (!_isResumingDraft) {
      final draftModel = ref.read(profileProvider).valueOrNull?.motivationLetter;
      if (draftModel != null && draftModel.trim().isNotEmpty) {
        _motivationCtrl.text = draftModel;
      }
    }
  }

  Future<void> _autoSelectMatchingDocs() async {
    if (!mounted) return;
    final requirements = _selectedProgram?.requirements ?? [];
    if (requirements.isEmpty) return;

    List<Document> docs;
    final cached = ref.read(documentsProvider).valueOrNull;
    if (cached != null) {
      docs = cached;
    } else {
      docs = await ref.read(documentsProvider.future);
    }
    if (!mounted) return;

    final autoIds = <String>{};
    for (final req in requirements) {
      final match = docs
          .where((d) =>
              d.status != DocumentStatus.rejected &&
              _matchesRequirement(d.typeLabel, req))
          .firstOrNull;
      if (match != null) autoIds.add(match.id);
    }
    if (autoIds.isNotEmpty && mounted) {
      setState(() => _selectedDocIds.addAll(autoIds));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _motivationCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
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
    // Reprise : brouillon déjà en base, on ferme simplement
    if (_isResumingDraft) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Brouillon conserve', color: const Color(0xFF6366F1)),
      );
      return;
    }
    if (_selectedProgram == null) return;
    setState(() => _savingDraft = true);
    try {
      await ref.read(myApplicationsProvider.notifier).saveDraft(
            programId: _selectedProgram!.id,
            motivationLetter: _motivationCtrl.text,
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
      if (_isResumingDraft) {
        await ref.read(myApplicationsProvider.notifier).submitDraft(
              widget.draftId!,
              documentIds: _selectedDocIds.toList(),
              motivationLetter: _motivationCtrl.text,
            );
      } else {
        await ref.read(myApplicationsProvider.notifier).submit(
              programId:   _selectedProgram!.id,
              documentIds: _selectedDocIds.toList(),
              motivationLetter: _motivationCtrl.text,
            );
      }
      if (mounted) {
        _showSuccessDialog();
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

  void _showSuccessDialog() {
    final program = _selectedProgram!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _kGreen, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'Candidature soumise !',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: _kNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '${program.programName}\n${program.universityName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5, color: Color(0xFF4B5563), height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous serez notifie de toute mise a jour de votre dossier.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5, color: Color(0xFF9CA3AF), height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kNavy, _kBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.28),
                    blurRadius: 10, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/applications');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voir mes candidatures',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/home');
              },
              child: const Text(
                'Retour a l\'accueil',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
              ),
            ),
          ]),
        ),
      ),
    );
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
    // Calcul canSubmit : tous les requis couverts par les docs sélectionnés
    final requirements = _selectedProgram?.requirements ?? <String>[];
    final allDocs = ref.watch(documentsProvider).valueOrNull ?? [];
    final selDocs = allDocs
        .where((d) => _selectedDocIds.contains(d.id))
        .toList();
    final missingReqs = requirements
        .where((req) => !selDocs.any((d) => _matchesRequirement(d.typeLabel, req)))
        .toList();
    final canSubmit = missingReqs.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(children: [
          _WizardHeader(
            currentStep: _currentStep,
            steps: _steps,
            onClose: () => context.pop(),
          ),
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
                  program:        _selectedProgram,
                  motivationCtrl: _motivationCtrl,
                  selectedDocIds: _selectedDocIds,
                  canSubmit:      canSubmit,
                  missingReqs:    missingReqs,
                ),
              ],
            ),
          ),
        ]),
        bottomNavigationBar: _buildBottomBar(canSubmit: canSubmit),
      ),
    );
  }

  Widget _buildBottomBar({required bool canSubmit}) {
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  foregroundColor: _kNavy,
                ),
                child: const Text('Retour',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(width: 12),
            ],
            if (isLast) ...[
              // Brouillon toujours disponible
              OutlinedButton(
                onPressed: busy ? null : _saveDraft,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  side: BorderSide(
                    color: canSubmit ? _kBorder : _kOrange,
                    width: canSubmit ? 1.5 : 2,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  foregroundColor: canSubmit ? _kNavy : _kOrange,
                  backgroundColor: canSubmit
                      ? null
                      : _kOrange.withValues(alpha: 0.06),
                ),
                child: _savingDraft
                    ? SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: canSubmit ? _kNavy : _kOrange))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.bookmark_outline,
                            size: 16,
                            color: canSubmit ? _kNavy : _kOrange),
                        const SizedBox(width: 6),
                        Text('Brouillon',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: canSubmit ? _kNavy : _kOrange,
                            )),
                      ]),
              ),
              const SizedBox(width: 10),
              // Soumettre : actif seulement si dossier complet
              Expanded(
                child: _GradientButton(
                  onTap: (busy || !canSubmit) ? null : _submit,
                  label: _submitting ? 'Envoi...' : 'Soumettre',
                  loading: _submitting,
                  disabled: !canSubmit,
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

// ─── Header ───────────────────────────────────────────────────────────────────

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

    // IDs de programmes déjà en candidature active (hors archivé/rejeté)
    final existingApps = ref.watch(myApplicationsProvider).valueOrNull ?? [];
    final takenProgIds = existingApps
        .where((a) => !a.isTerminal)
        .map((a) => a.programId)
        .toSet();

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
                  program:  filtered[i],
                  selected: selected?.id == filtered[i].id,
                  isTaken:  takenProgIds.contains(filtered[i].id),
                  onTap:    () {
                    if (takenProgIds.contains(filtered[i].id)) return;
                    _showProgramPreviewSheet(
                      context,
                      filtered[i],
                      () => onSelect(filtered[i]),
                    );
                  },
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

void _showProgramPreviewSheet(
  BuildContext context,
  Program program,
  VoidCallback onConfirm,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProgramPreviewSheet(program: program, onConfirm: onConfirm),
  );
}

class _ProgramPreviewSheet extends StatelessWidget {
  final Program      program;
  final VoidCallback onConfirm;
  const _ProgramPreviewSheet({required this.program, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final isExpired = program.isExpired;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header gradient
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1852), Color(0xFF1A3A8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                program.programName,
                style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: Colors.white, height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                program.universityName,
                style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
          // Scrollable content
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              children: [
                // Tags row
                Wrap(spacing: 8, runSpacing: 6, children: [
                  if (program.level != null) _LevelTag(program.levelLabel),
                  if (program.language != null)
                    _Tag(program.language!, color: _kBlue),
                  if (isExpired)
                    _Tag('Expiree', color: const Color(0xFFDC2626)),
                ]),
                const SizedBox(height: 14),
                // Info rows
                _InfoRow(Icons.location_on_outlined,   program.country ?? 'Non precise'),
                _InfoRow(Icons.schedule_outlined,       program.duration ?? 'Duree non precisee'),
                _InfoRow(Icons.calendar_today_outlined, 'Limite : ${program.deadlineLabel}',
                    color: isExpired ? const Color(0xFFDC2626) : null),
                _InfoRow(Icons.payments_outlined,       '${program.costLabel} / an',
                    color: const Color(0xFF059669)),
                // Description
                if (program.description != null && program.description!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Description',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kNavy)),
                  const SizedBox(height: 6),
                  Text(
                    program.description!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5),
                  ),
                ],
                // Requirements
                if (program.requirements != null && program.requirements!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Documents requis',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kNavy)),
                  const SizedBox(height: 8),
                  ...program.requirements!.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: _kBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                      ),
                    ]),
                  )),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
            child: isExpired
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Text(
                      'Candidature fermee — delai depasse',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1852), Color(0xFF4880FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4880FF).withValues(alpha: 0.3),
                          blurRadius: 12, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Selectionner ce programme',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  final Color?   color;
  const _InfoRow(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF4B5563);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: c))),
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
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              Text(program.programName,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.3,
                  )),
              const SizedBox(height: 4),
              Text(program.universityName,
                  style: TextStyle(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  )),
            ]),
          ),
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
  final Program      program;
  final bool         selected;
  final bool         isTaken;
  final VoidCallback onTap;
  const _ProgramTile({
    required this.program,
    required this.selected,
    required this.isTaken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isTaken
        ? const Color(0xFFD1D5DB)
        : selected ? _kBlue : _kBorder;
    final bgColor = isTaken
        ? const Color(0xFFF9FAFB)
        : selected ? _kBlue.withValues(alpha: 0.05) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isTaken ? 0.65 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
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
                      color: isTaken ? _kGrey : (selected ? _kBlue : _kNavy),
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
                  if (isTaken)
                    _Tag('Candidature en cours', color: _kGrey)
                  else ...[
                    if (program.level != null) _LevelTag(program.levelLabel),
                    _Tag(program.costLabel, color: const Color(0xFF059669)),
                  ],
                ]),
              ]),
            ),
            const SizedBox(width: 10),
            if (isTaken)
              const Icon(Icons.lock_outline_rounded, size: 18, color: _kGrey)
            else
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
      data: (docs) {
        final requirements  = program?.requirements ?? <String>[];
        final selectedDocs  = docs.where((d) => selected.contains(d.id)).toList();
        final coveredCount  = requirements.where((req) =>
          selectedDocs.any((d) => _matchesRequirement(d.typeLabel, req))
        ).length;
        final allCovered    = requirements.isNotEmpty && coveredCount == requirements.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Checklist des documents requis ──
            if (requirements.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(child: _SectionLabel('Documents requis')),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: allCovered
                          ? _kGreen.withValues(alpha: 0.1)
                          : _kOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: allCovered
                            ? _kGreen.withValues(alpha: 0.3)
                            : _kOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$coveredCount / ${requirements.length}',
                      style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800,
                        color: allCovered ? _kGreen : _kOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _RequiredDocsChecklist(
                requirements:   requirements,
                selectedDocs:   selectedDocs,
                selectedDocIds: selected,
                onToggle:       onToggle,
              ),
              const SizedBox(height: 22),
            ],

            // ── Section documents disponibles ──
            const _SectionLabel('Votre dossier'),
            Text(
              requirements.isNotEmpty
                  ? 'Selectionnez les documents ci-dessous pour couvrir les requis.'
                  : 'Selectionnez les documents a joindre a votre candidature.',
              style: const TextStyle(fontSize: 13.5, color: _kGrey, height: 1.5),
            ),
            const SizedBox(height: 16),

            if (docs.isEmpty) ...[
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
                      child: const Icon(Icons.folder_open_outlined, color: _kOrange, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Aucun document disponible',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          )),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    requirements.isNotEmpty
                        ? 'Utilisez les boutons "Ajouter" ci-dessus pour uploader vos documents directement.'
                        : 'Ajoutez vos documents dans votre profil avant de soumettre une candidature.',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF92400E), height: 1.5),
                  ),
                ]),
              ),
            ] else ...[
              ...docs.map((d) => _DocumentRow(
                doc: d,
                isSelected: selected.contains(d.id),
                onToggle: onToggle,
              )),
              const SizedBox(height: 14),

              // ── Compteur dynamique ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected.isEmpty
                      ? _kGrey.withValues(alpha: 0.08)
                      : allCovered
                          ? _kGreen.withValues(alpha: 0.07)
                          : _kBlue.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected.isEmpty
                        ? _kBorder
                        : allCovered
                            ? _kGreen.withValues(alpha: 0.25)
                            : _kBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    selected.isEmpty
                        ? Icons.info_outline_rounded
                        : allCovered
                            ? Icons.check_circle_outline_rounded
                            : Icons.check_circle_outline_rounded,
                    color: selected.isEmpty
                        ? _kGrey
                        : allCovered ? _kGreen : _kBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: requirements.isNotEmpty
                        ? RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600,
                                color: selected.isEmpty ? _kGrey : allCovered ? _kGreen : _kBlue,
                              ),
                              children: [
                                TextSpan(text: '$coveredCount/${requirements.length}',
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                                const TextSpan(text: ' requis couverts'),
                                if (selected.length > coveredCount)
                                  TextSpan(
                                    text: ' · ${selected.length} selectionne(s)',
                                    style: TextStyle(
                                      color: selected.isEmpty ? _kGrey : _kBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Text(
                            selected.isEmpty
                                ? 'Aucun document selectionne'
                                : '${selected.length} document(s) selectionne(s)',
                            style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600,
                              color: selected.isEmpty ? _kGrey : _kBlue,
                            ),
                          ),
                  ),
                ]),
              ),
            ],
          ]),
        );
      },
    );
  }
}

// ─── Checklist des requis ─────────────────────────────────────────────────────

class _RequiredDocsChecklist extends ConsumerStatefulWidget {
  final List<String>     requirements;
  final List<Document>   selectedDocs;
  final Set<String>      selectedDocIds;
  final ValueChanged<String> onToggle;

  const _RequiredDocsChecklist({
    required this.requirements,
    required this.selectedDocs,
    required this.selectedDocIds,
    required this.onToggle,
  });

  @override
  ConsumerState<_RequiredDocsChecklist> createState() =>
      _RequiredDocsChecklistState();
}

class _RequiredDocsChecklistState
    extends ConsumerState<_RequiredDocsChecklist> {
  final Map<String, bool> _uploading = {};

  Document? _matchedDoc(String req) {
    try {
      return widget.selectedDocs
          .firstWhere((d) => _matchesRequirement(d.typeLabel, req));
    } catch (_) {
      return null;
    }
  }

  DocumentType _typeFromReq(String req) {
    const map = {
      DocumentType.cv:               'CV',
      DocumentType.transcript:       'Releve de notes',
      DocumentType.recommendation:   'Lettre de recommandation',
      DocumentType.passport:         'Passeport',
      DocumentType.motivationLetter: 'Lettre de motivation',
      DocumentType.diploma:          'Diplome',
      DocumentType.languageCert:     'Attestation de langue',
      DocumentType.financialProof:   'Justificatif de financement',
    };
    for (final entry in map.entries) {
      if (_matchesRequirement(entry.value, req)) return entry.key;
    }
    return DocumentType.other;
  }

  Future<void> _uploadForReq(String req) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final docType  = _typeFromReq(req);

    // Capture les IDs existants du même type avant upload
    final docsBefore = ref.read(documentsProvider).valueOrNull ?? [];
    final idsBefore  = docsBefore
        .where((d) => d.type == docType)
        .map((d) => d.id)
        .toSet();

    setState(() => _uploading[req] = true);
    try {
      await ref.read(documentsProvider.notifier).upload(
        type:     docType,
        filePath: filePath,
      );
      // Force le rechargement et récupère le nouvel état
      final docsAfter = await ref.refresh(documentsProvider.future);
      // Trouve le doc nouvellement uploadé
      final newDoc = docsAfter
          .where((d) => d.type == docType && !idsBefore.contains(d.id))
          .firstOrNull;
      if (newDoc != null && !widget.selectedDocIds.contains(newDoc.id)) {
        widget.onToggle(newDoc.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading.remove(req));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: widget.requirements.asMap().entries.map((entry) {
          final i       = entry.key;
          final req     = entry.value;
          final doc     = _matchedDoc(req);
          final covered = doc != null;
          final loading = _uploading[req] ?? false;
          final color   = covered ? _kGreen : _kOrange;
          final isLast  = i == widget.requirements.length - 1;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: covered
                  ? _kGreen.withValues(alpha: 0.03)
                  : loading
                      ? _kOrange.withValues(alpha: 0.03)
                      : Colors.white,
              border: isLast
                  ? null
                  : const Border(bottom: BorderSide(color: _kBorder)),
              borderRadius: isLast
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              // Icone statut
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(7),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kOrange),
                      )
                    : Icon(
                        covered
                            ? Icons.check_rounded
                            : Icons.warning_amber_rounded,
                        color: color, size: 15,
                      ),
              ),
              const SizedBox(width: 12),
              // Label + sous-titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req,
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: covered ? _kNavy : _kGrey,
                      )),
                    const SizedBox(height: 2),
                    Text(
                      loading   ? 'Upload en cours...'
                          : covered ? doc.fileName
                          : 'Non fourni',
                      style: TextStyle(
                        fontSize: 11,
                        color: loading ? _kOrange
                            : covered ? _kGreen
                            : _kOrange,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge "OK" ou bouton "+ Ajouter"
              if (covered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('OK',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: _kGreen)),
                )
              else if (loading)
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _kOrange),
                )
              else
                GestureDetector(
                  onTap: () => _uploadForReq(req),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4880FF), Color(0xFF2D56E0)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withValues(alpha: 0.22),
                          blurRadius: 6, offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Ajouter',
                          style: TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                      ],
                    ),
                  ),
                ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Step 3 : Récapitulatif ───────────────────────────────────────────────────

class _StepRecap extends StatelessWidget {
  final Program? program;
  final TextEditingController motivationCtrl;
  final Set<String> selectedDocIds;
  final bool        canSubmit;
  final List<String> missingReqs;
  const _StepRecap({
    required this.program,
    required this.motivationCtrl,
    required this.selectedDocIds,
    required this.canSubmit,
    required this.missingReqs,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Recapitulatif').animate().fadeIn(delay: 50.ms),

        // Banner dossier incomplet
        if (!canSubmit) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFCA5A5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.block_rounded,
                      color: Color(0xFFEF4444), size: 17),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Soumission bloquee — dossier incomplet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                ...missingReqs.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(children: [
                    Container(
                      width: 5, height: 5,
                      margin: const EdgeInsets.only(right: 8, top: 1),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(req,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        )),
                    ),
                  ]),
                )),
                const SizedBox(height: 8),
                const Text(
                  'Revenez a l\'etape precedente pour ajouter les documents manquants, ou sauvegardez en brouillon pour completer plus tard.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 40.ms).slideY(begin: .04),
        ],

        if (program != null) ...[
          _ProgramCard(program: program!).animate().fadeIn(delay: 80.ms).slideY(begin: .03),
          const SizedBox(height: 20),
        ],

        const _SectionLabel('Checklist de completude'),
        _ChecklistCard(
          program: program,
          docCount: selectedDocIds.length,
          motivationCtrl: motivationCtrl,
        ).animate().fadeIn(delay: 120.ms),
        const SizedBox(height: 20),

        const _SectionLabel('Lettre de motivation pour ce programme'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Pré-remplie depuis votre modèle de profil : adaptez-la à ce programme précis avant de soumettre.',
            style: TextStyle(fontSize: 12, color: _kGrey, height: 1.4),
          ),
        ),
        TextField(
          controller: motivationCtrl,
          maxLines: 8,
          maxLength: 2000,
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
                style: TextStyle(fontSize: 13, color: _kBlue, height: 1.5),
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
    final reqCount      = widget.program?.requirements?.length ?? 0;
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
            ? reqCount > 0
                ? '${widget.docCount} document(s) sur $reqCount requis'
                : '${widget.docCount} document(s)'
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

// ─── Document row ─────────────────────────────────────────────────────────────

class _DocumentRow extends StatelessWidget {
  final Document doc;
  final bool isSelected;
  final ValueChanged<String> onToggle;
  const _DocumentRow({required this.doc, required this.isSelected, required this.onToggle});

  bool get _isRejected => doc.status == DocumentStatus.rejected;

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
    return Opacity(
      opacity: _isRejected ? 0.50 : 1.0,
      child: GestureDetector(
        onTap: _isRejected ? null : () => onToggle(doc.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _isRejected
                ? const Color(0xFFFEF2F2)
                : (isSelected ? _kBlue.withValues(alpha: 0.05) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isRejected
                  ? const Color(0xFFFCA5A5)
                  : (isSelected ? _kBlue : _kBorder),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _isRejected
                      ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                      : (isSelected
                          ? _kBlue.withValues(alpha: 0.12)
                          : _kGrey.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon,
                    color: _isRejected
                        ? const Color(0xFFEF4444)
                        : (isSelected ? _kBlue : _kGrey),
                    size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doc.typeLabel,
                      style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700, color: _kNavy,
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
              if (!_isRejected) ...[
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
              ] else ...[
                const SizedBox(width: 8),
                const Icon(Icons.block_rounded, size: 20, color: Color(0xFFEF4444)),
              ],
            ]),
            if (_isRejected) ...[
              const SizedBox(height: 7),
              const Text(
                'Ce document a ete rejete et ne peut pas etre joint.',
                style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), height: 1.4),
              ),
            ],
          ]),
        ),
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
            color: _kBlue, borderRadius: BorderRadius.circular(2),
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
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _LevelTag extends StatelessWidget {
  final String label;
  const _LevelTag(this.label);

  Color get _color {
    if (label.toLowerCase().contains('master')) return const Color(0xFF7C3AED);
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
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _color)),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool loading;
  final bool disabled;
  final IconData? icon;
  const _GradientButton({
    required this.onTap,
    required this.label,
    this.loading  = false,
    this.disabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null && !disabled;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFF4880FF), Color(0xFF2D56E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(14),
        boxShadow: active
            ? [BoxShadow(
                color: _kBlue.withValues(alpha: 0.35),
                blurRadius: 14, offset: const Offset(0, 5),
              )]
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
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          )),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 6),
                      Icon(icon,
                          color: active ? Colors.white : Colors.white70,
                          size: 18),
                    ],
                  ]),
          ),
        ),
      ),
    );
  }
}
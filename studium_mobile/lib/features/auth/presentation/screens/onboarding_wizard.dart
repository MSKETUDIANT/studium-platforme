import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/auth_provider.dart';

// Design tokens
const _kNavy   = Color(0xFF08122E);
const _kBlue   = Color(0xFF4880FF);
const _kGreen  = Color(0xFF10B981);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);
const _kFill   = Color(0xFFF8F9FC);

class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  final _pageCtrl       = PageController();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _motivationCtrl = TextEditingController();

  int     _step        = 0;
  bool    _saving      = false;
  bool    _saveSuccess = false;
  String? _nationality;

  // Validation
  bool _firstNameTouched = false;
  bool _lastNameTouched  = false;

  Timer? _draftDebounce;

  static const _total = 4;

  @override
  void initState() {
    super.initState();
    _loadExistingDraft();
    _motivationCtrl.addListener(_scheduleDraftSave);
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _motivationCtrl.removeListener(_scheduleDraftSave);
    _pageCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _motivationCtrl.dispose();
    super.dispose();
  }

  // Pré-remplit le wizard si l'étudiant avait déjà commencé son profil
  // (ex : app fermée en cours d'onboarding avant `_saveAndFinish`).
  Future<void> _loadExistingDraft() async {
    try {
      final client = Supabase.instance.client;
      final uid    = client.auth.currentUser?.id;
      if (uid == null) return;
      final data = await client
          .from('student_profiles')
          .select('first_name, last_name, nationality, motivation_letter')
          .eq('id', uid)
          .maybeSingle();
      if (data == null || !mounted) return;
      setState(() {
        _firstNameCtrl.text  = (data['first_name'] as String?) ?? '';
        _lastNameCtrl.text   = (data['last_name'] as String?) ?? '';
        _nationality         = data['nationality'] as String?;
        _motivationCtrl.text = (data['motivation_letter'] as String?) ?? '';
      });
    } catch (_) {
      // Non bloquant : l'onboarding démarre simplement vide si la lecture échoue.
    }
  }

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 1200), _saveDraft);
  }

  // Sauvegarde partielle (identité + motivation), appelée à chaque étape
  // franchie et en continu pendant la saisie (debounce), pour ne rien perdre
  // si l'app est fermée avant `_saveAndFinish`.
  Future<void> _saveDraft() async {
    final client = Supabase.instance.client;
    final uid    = client.auth.currentUser?.id;
    if (uid == null) return;
    final payload = <String, dynamic>{'id': uid};
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    final mt = _motivationCtrl.text.trim();
    if (fn.isNotEmpty) payload['first_name']        = fn;
    if (ln.isNotEmpty) payload['last_name']         = ln;
    if (_nationality != null) payload['nationality'] = _nationality;
    if (mt.isNotEmpty) payload['motivation_letter'] = mt;
    if (payload.length == 1) return;
    try {
      await client.from('student_profiles').upsert(payload);
    } catch (_) {
      // Sauvegarde silencieuse : un échec ponctuel ne doit pas interrompre l'onboarding.
    }
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  bool get _identityValid =>
      _firstNameCtrl.text.trim().isNotEmpty &&
      _lastNameCtrl.text.trim().isNotEmpty;

  void _tryNextFromIdentity() {
    setState(() {
      _firstNameTouched = true;
      _lastNameTouched  = true;
    });
    if (_identityValid) {
      _goTo(2);
      _draftDebounce?.cancel();
      _saveDraft();
    }
  }

  void _goToDone() {
    _goTo(3);
    _draftDebounce?.cancel();
    _saveDraft();
  }

  Future<void> _saveAndFinish() async {
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final uid    = client.auth.currentUser?.id;
      if (uid != null) {
        final payload = <String, dynamic>{'id': uid};
        final fn = _firstNameCtrl.text.trim();
        final ln = _lastNameCtrl.text.trim();
        final mt = _motivationCtrl.text.trim();
        if (fn.isNotEmpty) payload['first_name']        = fn;
        if (ln.isNotEmpty) payload['last_name']         = ln;
        if (_nationality != null) payload['nationality'] = _nationality;
        if (mt.isNotEmpty) payload['motivation_letter'] = mt;
        // Score initial basé sur ce qui est renseigné lors de l'onboarding
        final hasIdentity = fn.isNotEmpty && ln.isNotEmpty && _nationality != null;
        payload['completeness_score'] = hasIdentity ? 25 : 0;

        await client.from('student_profiles').upsert(payload);
        await client.auth.updateUser(
          UserAttributes(data: {'onboarding_done': true}),
        );
        ref.invalidate(profileNotifierProvider);
        if (mounted) setState(() => _saveSuccess = true);
        await Future.delayed(const Duration(milliseconds: 1400));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Erreur lors de l\'enregistrement : $e',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        setState(() => _saving = false);
        return;
      }
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: _step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _step > 0) _goTo(_step - 1);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(children: [
            Column(children: [
            if (_step > 0 && _step < _total - 1)
              _StepHeader(
                step:   _step,
                total:  _total,
                onBack: () => _goTo(_step - 1),
                onSkip: () => _goTo(_step + 1),
              ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onNext: () => _goTo(1)),
                  _IdentityPage(
                    firstNameCtrl:    _firstNameCtrl,
                    lastNameCtrl:     _lastNameCtrl,
                    nationality:      _nationality,
                    onNationality:    (v) {
                      setState(() => _nationality = v);
                      _scheduleDraftSave();
                    },
                    firstNameTouched: _firstNameTouched,
                    lastNameTouched:  _lastNameTouched,
                    onFieldChanged:   () {
                      setState(() {});
                      _scheduleDraftSave();
                    },
                    onNext:           _tryNextFromIdentity,
                  ),
                  _MotivationPage(
                    ctrl:   _motivationCtrl,
                    onNext: _goToDone,
                  ),
                  _DonePage(
                    saving:       _saving,
                    saveSuccess:  _saveSuccess,
                    onFinish:     _saveAndFinish,
                    hasIdentity:  _identityValid && _nationality != null,
                    hasMotivation: _motivationCtrl.text.trim().isNotEmpty,
                  ),
                ],
              ),
            ),
          ]),
          if (_step == 0)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).signOut();
                  },
                  child: const Text('Se déconnecter',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                ),
              ),
            ),
        ]),
      ),
    ),
  );
  }
}

// ─── Step header (étapes 2 et 3) ─────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  const _StepHeader({
    required this.step,
    required this.total,
    required this.onBack,
    required this.onSkip,
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
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 14),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: step / (total - 1),
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Étape $step sur ${total - 1}',
                    style: TextStyle(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text('Passer',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 13, fontWeight: FontWeight.w500,
                    )),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Page 1 : Bienvenue ───────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Hero gradient
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF07112B), Color(0xFF1A3A8F), Color(0xFF1A67D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.school_rounded, color: Colors.white, size: 30),
                )
                .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenue\nsur Studium',
                  style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.15, letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                const SizedBox(height: 10),
                Text(
                  'Configurons votre profil en quelques étapes pour maximiser vos chances d\'admission.',
                  style: TextStyle(
                    fontSize: 14, color: Colors.white.withValues(alpha: 0.75),
                    height: 1.55,
                  ),
                ).animate().fadeIn(delay: 180.ms),
              ],
            ),
          ),
        ),
      ),

      // Corps
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ce que nous allons faire',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _kNavy, letterSpacing: 0.1,
                ),
              ).animate().fadeIn(delay: 260.ms),
              const SizedBox(height: 16),
              ...[
                (Icons.person_outline_rounded,
                 'Votre identité',
                 'Prénom, nom, nationalité'),
                (Icons.edit_note_rounded,
                 'Lettre de motivation',
                 'Présentez votre projet académique'),
                (Icons.rocket_launch_outlined,
                 'Prêt à candidater',
                 'Explorez les programmes et postulez'),
              ].asMap().entries.map((e) {
                final i    = e.key;
                final item = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.$1, color: _kBlue, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$2,
                              style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w700,
                                color: _kNavy,
                              )),
                            const SizedBox(height: 2),
                            Text(item.$3,
                              style: const TextStyle(
                                  fontSize: 12, color: _kGrey)),
                          ],
                        ),
                      ),
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                            style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: _kBlue,
                            )),
                        ),
                      ),
                    ]),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 300 + i * 70))
                 .slideY(begin: 0.08);
              }),
              const SizedBox(height: 28),
              _PrimaryBtn(label: 'Commencer', onPressed: onNext)
                .animate().fadeIn(delay: 560.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Moins de 2 minutes · Modifiable à tout moment',
                  style: TextStyle(fontSize: 12, color: _kGrey.withValues(alpha: 0.8)),
                ),
              ).animate().fadeIn(delay: 620.ms),
            ],
          ),
        ),
      ),
    ]);
  }
}

// ─── Page 2 : Identité ────────────────────────────────────────────────────────

class _IdentityPage extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final String? nationality;
  final ValueChanged<String> onNationality;
  final bool firstNameTouched;
  final bool lastNameTouched;
  final VoidCallback onFieldChanged;
  final VoidCallback onNext;

  const _IdentityPage({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.nationality,
    required this.onNationality,
    required this.firstNameTouched,
    required this.lastNameTouched,
    required this.onFieldChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final firstEmpty = firstNameTouched && firstNameCtrl.text.trim().isEmpty;
    final lastEmpty  = lastNameTouched  && lastNameCtrl.text.trim().isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Votre identité',
          style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: _kNavy, letterSpacing: -0.3,
          )).animate().fadeIn().slideY(begin: 0.12),
        const SizedBox(height: 6),
        const Text(
          'Ces informations apparaîtront sur vos dossiers de candidature.',
          style: TextStyle(fontSize: 13.5, color: _kGrey, height: 1.5),
        ).animate().fadeIn(delay: 60.ms),
        const SizedBox(height: 28),

        Row(children: [
          Expanded(
            child: _FormField(
              label: 'Prénom',
              ctrl:  firstNameCtrl,
              hint:  'Mohammed',
              icon:  Icons.person_outline_rounded,
              error: firstEmpty ? 'Requis' : null,
              onChanged: (_) => onFieldChanged(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FormField(
              label: 'Nom',
              ctrl:  lastNameCtrl,
              hint:  'Sansy',
              icon:  Icons.badge_outlined,
              error: lastEmpty ? 'Requis' : null,
              onChanged: (_) => onFieldChanged(),
            ),
          ),
        ]).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
        const SizedBox(height: 16),

        // Nationalité
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _FieldLabel('Nationalité'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => showCountryPicker(
              context: context,
              showPhoneCode: false,
              onSelect: (c) => onNationality(c.name),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _kFill,
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.flag_outlined,
                    size: 18,
                    color: nationality != null ? _kBlue : _kGrey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nationality ?? 'Sélectionner une nationalité',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: nationality != null ? _kNavy : _kGrey,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: _kGrey, size: 20),
              ]),
            ),
          ),
        ]).animate().fadeIn(delay: 160.ms).slideY(begin: 0.08),
        const SizedBox(height: 32),

        _PrimaryBtn(label: 'Continuer', onPressed: onNext)
          .animate().fadeIn(delay: 220.ms),
      ]),
    );
  }
}

// ─── Page 3 : Lettre de motivation ───────────────────────────────────────────

class _MotivationPage extends ConsumerStatefulWidget {
  final TextEditingController ctrl;
  final VoidCallback onNext;
  const _MotivationPage({required this.ctrl, required this.onNext});

  @override
  ConsumerState<_MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends ConsumerState<_MotivationPage> {
  int _words = 0;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_updateCount);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_updateCount);
    super.dispose();
  }

  void _updateCount() {
    final t = widget.ctrl.text.trim();
    setState(() => _words = t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length);
  }

  @override
  Widget build(BuildContext context) {
    final minWords = ref.watch(motivationMinWordsProvider).valueOrNull ?? 300;
    final progress = (_words / minWords).clamp(0.0, 1.0);
    final isDone   = _words >= minWords;
    final barColor = isDone ? _kGreen : _kBlue;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Modèle de lettre de motivation',
          style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: _kNavy, letterSpacing: -0.3,
          )).animate().fadeIn().slideY(begin: 0.12),
        const SizedBox(height: 6),
        const Text(
          'Un point de départ réutilisé pour chaque candidature : vous '
          'l\'adapterez ensuite au programme précis visé, directement '
          'depuis l\'assistant de candidature.',
          style: TextStyle(fontSize: 13.5, color: _kGrey, height: 1.5),
        ).animate().fadeIn(delay: 60.ms),
        const SizedBox(height: 20),

        // Textarea
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: _kFill,
            border: Border.all(
              color: _words > 0 ? _kBlue.withValues(alpha: 0.50) : _kBorder,
              width: _words > 0 ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: widget.ctrl,
            maxLines: 9,
            minLines: 6,
            style: const TextStyle(
                fontSize: 14, height: 1.65, color: _kNavy),
            decoration: const InputDecoration(
              hintText: 'Je souhaite poursuivre mes études en… '
                  'Présentez vos motivations, votre projet académique et professionnel.',
              hintStyle: TextStyle(color: _kGrey, fontSize: 13.5, height: 1.5),
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 10),

        // Barre de progression mots
        Column(children: [
          Row(children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isDone ? _kGreen : _kGrey,
              ),
              child: Text('$_words mots'),
            ),
            const Spacer(),
            Text(
              isDone ? 'Excellent !' : '$minWords mots recommandés',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: isDone ? _kGreen : _kGrey,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: _kBorder,
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 4,
              ),
            ),
          ),
        ]).animate().fadeIn(delay: 140.ms),
        const SizedBox(height: 20),

        // Conseil
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBlue.withValues(alpha: 0.15)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lightbulb_outline_rounded,
                color: _kBlue, size: 16),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mentionnez vos motivations, votre parcours et ce que vous apporterez au programme.',
                style: TextStyle(
                  fontSize: 12.5, color: _kBlue, height: 1.5),
              ),
            ),
          ]),
        ).animate().fadeIn(delay: 180.ms),
        const SizedBox(height: 28),

        _PrimaryBtn(label: 'Continuer', onPressed: widget.onNext)
          .animate().fadeIn(delay: 240.ms),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: widget.onNext,
            child: const Text('Passer cette étape',
              style: TextStyle(color: _kGrey, fontSize: 13)),
          ),
        ).animate().fadeIn(delay: 280.ms),
      ]),
    );
  }
}

// ─── Page 4 : Terminé ─────────────────────────────────────────────────────────

class _DonePage extends StatelessWidget {
  final bool saving;
  final bool saveSuccess;
  final VoidCallback onFinish;
  final bool hasIdentity;
  final bool hasMotivation;
  const _DonePage({
    required this.saving,
    required this.saveSuccess,
    required this.onFinish,
    required this.hasIdentity,
    required this.hasMotivation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header gradient
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF07112B), Color(0xFF1A3A8F), Color(0xFF1A67D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
            child: Column(children: [
              // Cercle succès
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30), width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded, color: Colors.white, size: 44),
              )
              .animate().scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              const Text(
                'Profil configuré !',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                'Votre profil est prêt.\nExplorez les programmes et candidatez dès maintenant.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, color: Colors.white.withValues(alpha: 0.75),
                  height: 1.55,
                ),
              ).animate().fadeIn(delay: 300.ms),
            ]),
          ),
        ),
      ),

      // Récap
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(children: [
            ...[
              (Icons.person_rounded,       'Identité renseignée',  'Prénom, nom et nationalité', 'Étape passée  à compléter plus tard', hasIdentity),
              (Icons.edit_note_rounded,    'Lettre de motivation', 'Modèle de base enregistré',  'Étape passée  à compléter plus tard', hasMotivation),
              (Icons.folder_open_outlined, 'Dossier en attente',   'Ajoutez vos documents pour candidater', 'Ajoutez vos documents pour candidater', false),
            ].asMap().entries.map((e) {
              final i    = e.key;
              final item = e.value;
              final done = item.$5;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: done
                        ? _kGreen.withValues(alpha: 0.05)
                        : _kFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: done
                          ? _kGreen.withValues(alpha: 0.25)
                          : _kBorder,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: done
                            ? _kGreen.withValues(alpha: 0.12)
                            : _kBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(item.$1,
                        color: done ? _kGreen : _kBlue, size: 19),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2,
                            style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700,
                              color: done ? _kNavy : _kGrey,
                            )),
                          const SizedBox(height: 2),
                          Text(done ? item.$3 : item.$4,
                            style: const TextStyle(
                                fontSize: 11.5, color: _kGrey)),
                        ],
                      ),
                    ),
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: done ? _kGreen : _kGrey,
                      size: 20,
                    ),
                  ]),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 400 + i * 80))
               .slideY(begin: 0.06);
            }),
            const SizedBox(height: 28),
            _PrimaryBtn(
              label:     saving
                  ? (saveSuccess ? 'Profil enregistre !' : 'Enregistrement...')
                  : 'Découvrir les programmes',
              onPressed: saving ? null : onFinish,
              loading:   saving && !saveSuccess,
              success:   saveSuccess,
            ).animate().fadeIn(delay: 680.ms).slideY(begin: 0.2),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Widgets communs ──────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: Color(0xFF374151), letterSpacing: 0.2,
    ),
  );
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final String? error;
  final ValueChanged<String>? onChanged;
  const _FormField({
    required this.label,
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.error,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        onChanged:  onChanged,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: _kNavy),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kGrey, fontSize: 13.5),
          prefixIcon: Icon(icon, size: 17, color: _kGrey),
          filled: true,
          fillColor: error != null
              ? const Color(0xFFFEF2F2)
              : _kFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: error != null
                  ? const Color(0xFFFCA5A5)
                  : _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: error != null
                  ? const Color(0xFFFCA5A5)
                  : _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: error != null
                  ? const Color(0xFFEF4444)
                  : _kBlue,
              width: 1.5,
            ),
          ),
          errorText:   error,
          errorStyle:  const TextStyle(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
        ),
      ),
    ],
  );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool success;
  const _PrimaryBtn({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: active && !success
              ? const LinearGradient(
                  colors: [Color(0xFF08122E), Color(0xFF1250A8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: success
              ? _kGreen
              : active ? null : _kBorder,
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [BoxShadow(
                  color: const Color(0xFF08122E).withValues(alpha: 0.22),
                  blurRadius: 16, offset: const Offset(0, 6),
                )]
              : [],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor:     Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (success) ...[
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: active ? Colors.white : _kGrey,
                    ),
                  ),
                  if (!success && active) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ],
                ]),
        ),
      ),
    );
  }
}
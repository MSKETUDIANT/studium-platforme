import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/academic_background.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/student_profile.dart';
import '../providers/profile_providers.dart';
import 'add_academic_page.dart';
import 'add_experience_page.dart';

// ─────────────────────────────────────────────
// 🗓️  _fmt — top-level concise date helper
// ─────────────────────────────────────────────
String _fmt(DateTime? date) {
  if (date == null) return '';
  const months = [
    'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
    'jul', 'aoû', 'sep', 'oct', 'nov', 'déc',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

// Short DD/MM/YYYY variant used in the infos step
String _fmtFull(DateTime? date) {
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

// ─────────────────────────────────────────────
// 🔔  Stylized floating SnackBar helper
// ─────────────────────────────────────────────
void _showFloatingSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.info_outline_rounded,
  Color color = _AppColors.primaryDark,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 3),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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
}

// ─────────────────────────────────────────────
// 🏫  ProfilePage
// ─────────────────────────────────────────────
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int _currentStep = 0;

  void _goToStep(int step, {required bool hasAcademics}) {
    if (step == 2 && !hasAcademics) return;
    setState(() => _currentStep = step);
  }

  void _goNext({required bool hasAcademics}) {
    if (_currentStep == 1 && !hasAcademics) {
      // ✅ Stylized floating SnackBar
      _showFloatingSnackBar(
        context,
        'Ajoutez au moins une formation pour continuer.',
        icon: Icons.school_outlined,
      );
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      HapticFeedback.selectionClick();
    } else {
      context.go('/home');
    }
  }

  void _goPrevious() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync   = ref.watch(profileNotifierProvider);
    final academicsAsync = ref.watch(academicBackgroundsProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Une erreur est survenue.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
      data: (profile) {
        final score        = profile?.completenessScore ?? 0;
        final hasAcademics = academicsAsync.valueOrNull?.isNotEmpty ?? false;

        return Scaffold(
          backgroundColor: _AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _AppColors.textPrimary,
                size: 18,
              ),
              onPressed: () => context.go('/home'),
            ),
            title: const Text(
              'Profil Étudiant',
              style: TextStyle(
                color: _AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                // ✅ Avatar cliquable → /profile/edit
                child: GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundImage: profile?.photoUrl != null
                        ? NetworkImage(profile!.photoUrl!)
                        : null,
                    backgroundColor: _AppColors.primaryDark,
                    child: profile?.photoUrl == null
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _ProfileHeader(
                currentStep: _currentStep,
                score: score,
                hasAcademics: hasAcademics,
                onStepTap: (step) =>
                    _goToStep(step, hasAcademics: hasAcademics),
              ),
              Expanded(
                // ✅ AnimatedSwitcher — fade entre les steps
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: IndexedStack(
                    key: ValueKey(_currentStep),
                    index: _currentStep,
                    children: [
                      _InfosStep(profile: profile),
                      const _AcademicStep(),
                      hasAcademics
                          ? const _ExperienceStep()
                          : const _LockedStep(
                              message:
                                  'Terminez la section académique\npour débloquer les expériences.',
                            ),
                    ],
                  ),
                ),
              ),
              // ✅ _BottomNav — nom court
              _BottomNav(
                currentStep: _currentStep,
                onPrevious: _goPrevious,
                onNext: () => _goNext(hasAcademics: hasAcademics),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final int currentStep;
  final int score;
  final bool hasAcademics;
  final ValueChanged<int> onStepTap;

  const _ProfileHeader({
    required this.currentStep,
    required this.score,
    required this.hasAcademics,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = score >= 80 ? _AppColors.success : _AppColors.primary;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // barre gradient top
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1F42), Color(0xFF4880FF)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // score + ring
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Étape ${currentStep + 1} sur 3',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: score),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Text(
                              '$v% complété',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: score / 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: v,
                              strokeWidth: 5,
                              backgroundColor: _AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                            Center(
                              child: Text(
                                '${(v * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // barre de progression
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 7,
                      backgroundColor: _AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // étapes
                Row(children: [
                  _StepIndicator(
                    label: 'Infos',
                    index: 0,
                    current: currentStep,
                    done: score > 0,
                    onTap: () => onStepTap(0),
                  ),
                  const _StepConnector(done: true),
                  _StepIndicator(
                    label: 'Parcours',
                    index: 1,
                    current: currentStep,
                    done: hasAcademics,
                    onTap: () => onStepTap(1),
                  ),
                  _StepConnector(done: hasAcademics),
                  _StepIndicator(
                    label: 'Expériences',
                    index: 2,
                    current: currentStep,
                    done: false,
                    locked: !hasAcademics,
                    onTap: hasAcademics ? () => onStepTap(2) : null,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

// ✅ _BottomNav — nom court (was _BottomNavigationBarSection)
class _BottomNav extends StatelessWidget {
  final int currentStep;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _BottomNav({
    required this.currentStep,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: _AppColors.textMuted,
                ),
                label: const Text(
                  'Précédent',
                  style: TextStyle(
                    color: _AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: _AppColors.border),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: _AppColors.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentStep < 2 ? 'Continuer' : 'Terminer',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    currentStep < 2
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final bool done;
  final bool locked;
  final VoidCallback? onTap;

  const _StepIndicator({
    required this.label,
    required this.index,
    required this.current,
    required this.done,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;

    final Color bg = locked
        ? const Color(0xFFF3F4F6)
        : done && !isActive
            ? _AppColors.primary
            : isActive
                ? Colors.white
                : const Color(0xFFF3F4F6);

    final Color borderColor = locked
        ? _AppColors.border
        : (done || isActive)
            ? _AppColors.primary
            : _AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.2),
              boxShadow: isActive
                  ? [BoxShadow(
                      color: _AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 12, spreadRadius: 2,
                    )]
                  : [],
            ),
            child: Center(
              child: locked
                  ? const Icon(Icons.lock_outline_rounded,
                      size: 14, color: _AppColors.textLight)
                  : done && !isActive
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isActive
                                ? _AppColors.primary
                                : _AppColors.textLight,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? _AppColors.primary
                  : done
                      ? _AppColors.textMuted
                      : _AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool done;
  const _StepConnector({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: done ? _AppColors.primary : _AppColors.border,
        ),
      ),
    );
  }
}

// ─── Step 1 : Infos ───────────────────────────────────────────────────────────

class _InfosStep extends ConsumerWidget {
  final StudentProfile? profile;
  const _InfosStep({this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carte héro profil ──
          GestureDetector(
            onTap: () => context.push('/profile/edit'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D1F42), Color(0xFF1E5298)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A3C6E).withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        backgroundImage: profile?.photoUrl != null
                            ? NetworkImage(profile!.photoUrl!)
                            : null,
                        child: profile?.photoUrl == null
                            ? const Icon(Icons.person, color: Colors.white, size: 32)
                            : null,
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: _AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.fullName.isNotEmpty == true
                              ? profile!.fullName
                              : 'Étudiant',
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (profile?.email != null) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.verified_rounded,
                                size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                profile!.email!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ],
                        if (profile?.nationality != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            '🏳 ${profile!.nationality}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // flèche modifier
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 22),

          const _StepTitle('Informations personnelles'),
          const SizedBox(height: 16),

          _InfoSection(
            title: 'Contact',
            items: [
              _InfoItem(Icons.phone_outlined, 'Téléphone', profile?.phone),
              _InfoItem(Icons.cake_outlined, 'Date de naissance',
                  _fmtFull(profile?.birthDate)),
            ],
          ),
          const SizedBox(height: 14),
          _InfoSection(
            title: 'Localisation & origine',
            items: [
              _InfoItem(Icons.flag_outlined, 'Nationalité',
                  profile?.nationality),
              _InfoItem(Icons.public_outlined, 'Pays de résidence',
                  profile?.countryResidence),
              _InfoItem(Icons.location_on_outlined, 'Adresse',
                  profile?.address),
            ],
          ),
          if ((profile?.motivationLetter ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _InfoSection(
              title: 'Lettre de motivation',
              items: [
                _InfoItem(Icons.description_outlined, null,
                    profile?.motivationLetter),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // ── Bouton modifier ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit_outlined,
                  size: 17, color: _AppColors.primary),
              label: const Text(
                'Modifier mes informations',
                style: TextStyle(
                    color: _AppColors.primary, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: _AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Bouton déconnexion ──
          Consumer(builder: (context, ref, _) {
            return SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (!context.mounted) return;
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded,
                    size: 17, color: Color(0xFFEF4444)),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(
                      color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Step 2 : Parcours ────────────────────────────────────────────────────────

class _AcademicStep extends ConsumerWidget {
  const _AcademicStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicsAsync = ref.watch(academicBackgroundsProvider);

    return academicsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Erreur : $e', textAlign: TextAlign.center),
        ),
      ),
      data: (academics) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle('Parcours académique'),
            const SizedBox(height: 6),
            Text(
              '${academics.length} diplôme${academics.length > 1 ? 's' : ''} '
              'ajouté${academics.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: _AppColors.textLight),
            ),
            const SizedBox(height: 18),
            if (academics.isEmpty)
              const _EmptyStateCard(
                icon: Icons.school_outlined,
                title: 'Aucune formation ajoutée',
                subtitle:
                    'Ajoutez votre parcours académique pour compléter votre profil.',
              )
            else
              ...academics.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AcademicCard(a),
                ),
              ),
            const SizedBox(height: 4),
            _AddCard(
              label: 'Ajouter une formation',
              icon: Icons.school_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddAcademicPage()),
              ).then(
                  (_) => ref.invalidate(academicBackgroundsProvider)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3 : Expériences ─────────────────────────────────────────────────────

class _ExperienceStep extends ConsumerWidget {
  const _ExperienceStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experiencesAsync = ref.watch(experiencesProvider);

    return experiencesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Erreur : $e', textAlign: TextAlign.center),
        ),
      ),
      data: (experiences) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle('Expériences professionnelles'),
            const SizedBox(height: 6),
            Text(
              '${experiences.length} expérience'
              '${experiences.length > 1 ? 's' : ''} '
              'ajoutée${experiences.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: _AppColors.textLight),
            ),
            const SizedBox(height: 18),
            if (experiences.isEmpty)
              const _EmptyStateCard(
                icon: Icons.work_outline,
                title: 'Aucune expérience ajoutée',
                subtitle:
                    'Ajoutez un stage, un job ou une mission pour enrichir votre profil.',
              )
            else
              ...experiences.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  // ✅ _fmt top-level — plus besoin de la passer en paramètre
                  child: _ExperienceCard(e),
                ),
              ),
            const SizedBox(height: 4),
            _AddCard(
              label: 'Ajouter une expérience',
              icon: Icons.work_outline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddExperiencePage()),
              ).then((_) => ref.invalidate(experiencesProvider)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Locked Step ─────────────────────────────────────────────────────────────

class _LockedStep extends StatelessWidget {
  final String message;
  const _LockedStep({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: _AppColors.textLight, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _AppColors.textLight,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget helpers ───────────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  final String text;
  const _StepTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String? label;
  final String? value;
  _InfoItem(this.icon, this.label, this.value);
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final visible = items
        .where((i) => i.value != null && i.value!.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: visible.asMap().entries.map((entry) {
              final item   = entry.value;
              final isLast = entry.key == visible.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _AppColors.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(item.icon,
                              size: 17, color: _AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (item.label != null)
                                Text(item.label!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: _AppColors.textLight)),
                              Text(item.value!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _AppColors.textPrimary,
                                    height: 1.45,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, indent: 62, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

enum _CardAction { details, edit, delete }

class _AcademicCard extends ConsumerWidget {
  final AcademicBackground academic;
  const _AcademicCard(this.academic);

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              const _LeadingIconBox(
                  icon: Icons.school_outlined, color: _AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(academic.degree,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _AppColors.textPrimary)),
                    Text(academic.university,
                        style: const TextStyle(
                            fontSize: 13, color: _AppColors.textMuted)),
                  ],
                ),
              ),
            ]),
            if (academic.year != null || academic.average != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              if (academic.year != null)
                _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Année d\'obtention',
                    value: '${academic.year}'),
              if (academic.average != null)
                _DetailRow(
                    icon: Icons.grade_outlined,
                    label: 'Moyenne',
                    value: '${academic.average}'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, _CardAction action) async {
    if (action == _CardAction.details) {
      _showDetails(context);
    } else if (action == _CardAction.edit) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddAcademicPage(existing: academic)),
      );
      ref.invalidate(academicBackgroundsProvider);
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Supprimer la formation',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Supprimer',
                    style: TextStyle(color: Color(0xFFEF4444)))),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(academicBackgroundsProvider.notifier).delete(academic.id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LeadingIconBox(
              icon: Icons.school_outlined, color: _AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(academic.degree,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _AppColors.textPrimary,
                    )),
                const SizedBox(height: 3),
                Text(academic.university,
                    style: const TextStyle(
                        fontSize: 12, color: _AppColors.textMuted)),
                if (academic.year != null || academic.average != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (academic.year != null)
                          _Chip(Icons.calendar_today_outlined,
                              '${academic.year}'),
                        if (academic.average != null)
                          _Chip(Icons.grade_outlined,
                              'Moy: ${academic.average}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<_CardAction>(
            onSelected: (a) => _handleAction(context, ref, a),
            icon: const Icon(Icons.more_vert,
                size: 18, color: _AppColors.textLight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _CardAction.details,
                child: Row(children: [
                  Icon(Icons.info_outline, size: 16),
                  SizedBox(width: 10),
                  Text('Voir les détails'),
                ]),
              ),
              PopupMenuItem(
                value: _CardAction.edit,
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 16),
                  SizedBox(width: 10),
                  Text('Modifier'),
                ]),
              ),
              PopupMenuItem(
                value: _CardAction.delete,
                child: Row(children: [
                  Icon(Icons.delete_outline,
                      size: 16, color: Color(0xFFEF4444)),
                  SizedBox(width: 10),
                  Text('Supprimer',
                      style: TextStyle(color: Color(0xFFEF4444))),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExperienceCard extends ConsumerWidget {
  final Experience experience;
  const _ExperienceCard(this.experience);

  void _showDetails(BuildContext context) {
    final start = _fmt(experience.startDate);
    final end = experience.isCurrent
        ? 'Présent'
        : experience.endDate != null
            ? _fmt(experience.endDate)
            : 'Non définie';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              const _LeadingIconBox(
                  icon: Icons.work_outline, color: _AppColors.primaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(experience.position,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _AppColors.textPrimary)),
                    Text(experience.company,
                        style: const TextStyle(
                            fontSize: 13, color: _AppColors.textMuted)),
                  ],
                ),
              ),
              if (experience.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _AppColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('En cours',
                      style: TextStyle(
                          fontSize: 11,
                          color: _AppColors.success,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (start.isNotEmpty)
              _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Période',
                  value: '$start → $end'),
            if (experience.description != null &&
                experience.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Description',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textMuted)),
              const SizedBox(height: 6),
              Text(experience.description!,
                  style: const TextStyle(
                      fontSize: 14, color: _AppColors.textPrimary,
                      height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, _CardAction action) async {
    if (action == _CardAction.details) {
      _showDetails(context);
    } else if (action == _CardAction.edit) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddExperiencePage(existing: experience)),
      );
      ref.invalidate(experiencesProvider);
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Supprimer l\'expérience',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Supprimer',
                    style: TextStyle(color: Color(0xFFEF4444)))),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(experiencesProvider.notifier).delete(experience.id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = _fmt(experience.startDate);
    final end = experience.isCurrent
        ? 'Présent'
        : experience.endDate != null
            ? _fmt(experience.endDate)
            : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LeadingIconBox(
              icon: Icons.work_outline, color: _AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(experience.position,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _AppColors.textPrimary,
                    )),
                const SizedBox(height: 3),
                Text(experience.company,
                    style: const TextStyle(
                        fontSize: 12, color: _AppColors.textMuted)),
                if (start.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Chip(Icons.calendar_today_outlined,
                            '$start → $end'),
                        if (experience.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _AppColors.success
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'En cours',
                              style: TextStyle(
                                fontSize: 10,
                                color: _AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<_CardAction>(
            onSelected: (a) => _handleAction(context, ref, a),
            icon: const Icon(Icons.more_vert,
                size: 18, color: _AppColors.textLight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _CardAction.details,
                child: Row(children: [
                  Icon(Icons.info_outline, size: 16),
                  SizedBox(width: 10),
                  Text('Voir les détails'),
                ]),
              ),
              PopupMenuItem(
                value: _CardAction.edit,
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 16),
                  SizedBox(width: 10),
                  Text('Modifier'),
                ]),
              ),
              PopupMenuItem(
                value: _CardAction.delete,
                child: Row(children: [
                  Icon(Icons.delete_outline,
                      size: 16, color: Color(0xFFEF4444)),
                  SizedBox(width: 10),
                  Text('Supprimer',
                      style: TextStyle(color: Color(0xFFEF4444))),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _AddCard(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                  color: _AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                )),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _AppColors.textLight),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11, color: _AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _LeadingIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _LeadingIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _AppColors.primary, size: 26),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _AppColors.textPrimary,
              )),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: _AppColors.textMuted,
                height: 1.5,
              )),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _AppColors.textLight),
          const SizedBox(width: 10),
          Text('$label : ',
              style: const TextStyle(
                  fontSize: 13,
                  color: _AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: _AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Design tokens ────────────────────────────────────────────────────────────

class _AppColors {
  static const Color background  = Color(0xFFF4F6FB);
  static const Color primary     = Color(0xFF4880FF);
  static const Color primaryDark = Color(0xFF1A3C6E);
  static const Color success     = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textMuted   = Color(0xFF6B7280);
  static const Color textLight   = Color(0xFF9CA3AF);
  static const Color border      = Color(0xFFE5E7EB);
}
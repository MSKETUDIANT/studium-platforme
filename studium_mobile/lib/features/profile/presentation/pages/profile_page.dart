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

// ─── Date helpers ────────────────────────────────────────────────────────────
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
// Stylized floating SnackBar helper
// ─── ProfilePage ─────────────────────────────────────────────────────────────
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
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: _AppColors.background,
            body: Column(
              children: [
                _GradientProfileBanner(
                  profile:     profile,
                  score:       score,
                  currentStep: _currentStep,
                  hasAcademics: hasAcademics,
                  onStepTap:   (step) =>
                      _goToStep(step, hasAcademics: hasAcademics),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation, child: child,
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
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Gradient Profile Banner ─────────────────────────────────────────────────

class _GradientProfileBanner extends StatelessWidget {
  final StudentProfile? profile;
  final int score;
  final int currentStep;
  final bool hasAcademics;
  final ValueChanged<int> onStepTap;

  const _GradientProfileBanner({
    required this.profile,
    required this.score,
    required this.currentStep,
    required this.hasAcademics,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = score >= 80 ? _AppColors.success : _AppColors.primary;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B1A3D), Color(0xFF1250A8), Color(0xFF1A4FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x440B1A3D),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Cercles décoratifs fond
            Positioned(right: -30, top: -30,
              child: _DecorCircle(size: 130, opacity: 0.07)),
            Positioned(right: 60, bottom: 30,
              child: _DecorCircle(size: 80, opacity: 0.05)),
            Positioned(left: -20, bottom: 10,
              child: _DecorCircle(size: 90, opacity: 0.04)),

            Column(
              children: [
                // ── Avatar + nom + score ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () => context.push('/profile/edit'),
                        child: Stack(children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 2.5),
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                              backgroundImage: profile?.photoUrl != null
                                  ? NetworkImage(profile!.photoUrl!)
                                  : null,
                              child: profile?.photoUrl == null
                                  ? const Icon(Icons.person,
                                      color: Colors.white, size: 30)
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: _AppColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 14),

                      // Nom + barre de progression
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName.isNotEmpty == true
                                  ? profile!.fullName
                                  : 'Profil Étudiant',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Mini progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: score / 100),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) =>
                                    LinearProgressIndicator(
                                  value: v,
                                  minHeight: 5,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.18),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(accent),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              score >= 80
                                  ? '✓ Profil complet'
                                  : '$score% complété',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Score ring
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: score / 100),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => SizedBox(
                          width: 58, height: 58,
                          child: Stack(fit: StackFit.expand, children: [
                            CircularProgressIndicator(
                              value: v,
                              strokeWidth: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accent),
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(v * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tab bar ──
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      _StepTab(
                        label: 'Infos',
                        index: 0,
                        current: currentStep,
                        onTap: () => onStepTap(0),
                      ),
                      _StepTab(
                        label: 'Parcours',
                        index: 1,
                        current: currentStep,
                        onTap: () => onStepTap(1),
                      ),
                      _StepTab(
                        label: 'Expériences',
                        index: 2,
                        current: currentStep,
                        locked: !hasAcademics,
                        onTap: hasAcademics ? () => onStepTap(2) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTab extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final bool locked;
  final VoidCallback? onTap;

  const _StepTab({
    required this.label,
    required this.index,
    required this.current,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.lock_outline_rounded,
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.40)),
                ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
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
    final bottomPad = MediaQuery.of(context).padding.bottom + 72;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle('Informations personnelles')
              .animate().fadeIn(delay: 60.ms).slideY(begin: .04),
          const SizedBox(height: 16),

          _InfoSection(
            title: 'Contact',
            items: [
              _InfoItem(Icons.phone_outlined, 'Téléphone', profile?.phone),
              _InfoItem(Icons.cake_outlined, 'Date de naissance',
                  _fmtFull(profile?.birthDate)),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: .04),
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
          ).animate().fadeIn(delay: 150.ms).slideY(begin: .04),
          if ((profile?.motivationLetter ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _InfoSection(
              title: 'Lettre de motivation',
              items: [
                _InfoItem(Icons.description_outlined, null,
                    profile?.motivationLetter),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: .04),
          ],
          if ((profile?.academicGoals ?? '').trim().isNotEmpty ||
              (profile?.careerGoals ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _InfoSection(
              title: 'Objectifs',
              items: [
                _InfoItem(Icons.school_outlined, 'Objectifs académiques',
                    profile?.academicGoals),
                _InfoItem(Icons.work_outline, 'Objectifs professionnels',
                    profile?.careerGoals),
              ],
            ).animate().fadeIn(delay: 240.ms).slideY(begin: .04),
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
          ).animate().fadeIn(delay: 280.ms).slideY(begin: .04),
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
          }).animate().fadeIn(delay: 320.ms).slideY(begin: .04),
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
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).padding.bottom + 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle('Parcours académique')
                .animate().fadeIn(delay: 60.ms).slideY(begin: .04),
            const SizedBox(height: 6),
            Text(
              '${academics.length} diplôme${academics.length > 1 ? 's' : ''} '
              'ajouté${academics.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: _AppColors.textLight),
            ).animate().fadeIn(delay: 90.ms),
            const SizedBox(height: 18),
            if (academics.isEmpty)
              const _EmptyStateCard(
                icon: Icons.school_outlined,
                title: 'Aucune formation ajoutée',
                subtitle:
                    'Ajoutez votre parcours académique pour compléter votre profil.',
              ).animate().fadeIn(delay: 120.ms).slideY(begin: .04)
            else
              ...academics.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AcademicCard(entry.value)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 120 + entry.key * 60))
                      .slideY(begin: .04),
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
            ).animate().fadeIn(delay: 200.ms).slideY(begin: .04),
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
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).padding.bottom + 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle('Expériences professionnelles')
                .animate().fadeIn(delay: 60.ms).slideY(begin: .04),
            const SizedBox(height: 6),
            Text(
              '${experiences.length} expérience'
              '${experiences.length > 1 ? 's' : ''} '
              'ajoutée${experiences.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: _AppColors.textLight),
            ).animate().fadeIn(delay: 90.ms),
            const SizedBox(height: 18),
            if (experiences.isEmpty)
              const _EmptyStateCard(
                icon: Icons.work_outline,
                title: 'Aucune expérience ajoutée',
                subtitle:
                    'Ajoutez un stage, un job ou une mission pour enrichir votre profil.',
              ).animate().fadeIn(delay: 120.ms).slideY(begin: .04)
            else
              ...experiences.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExperienceCard(entry.value)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 120 + entry.key * 60))
                      .slideY(begin: .04),
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
            ).animate().fadeIn(delay: 200.ms).slideY(begin: .04),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).padding.bottom + 24),
            child: Column(
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).padding.bottom + 24),
            child: Column(
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
                  const SizedBox(height: 16),
                  Row(children: [
                    Container(
                      width: 3, height: 16,
                      decoration: BoxDecoration(
                        color: _AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.textPrimary)),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8ECF8)),
                    ),
                    child: Text(experience.description!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: _AppColors.textPrimary,
                            height: 1.6)),
                  ),
                ],
              ],
            ),
          ),
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
                if (experience.description != null &&
                    experience.description!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      experience.description!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _AppColors.textMuted,
                        height: 1.5,
                      ),
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

// ─── Shared decorative helpers ───────────────────────────────────────────────

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: Container(
          width: size, height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
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
}
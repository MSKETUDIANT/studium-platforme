import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/presentation/providers/profile_providers.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _kNavy   = Color(0xFF0D1F42);
const _kBlue   = Color(0xFF1A3C6E);
const _kAccent = Color(0xFF4880FF);
const _kBg     = Color(0xFFF4F6FB);
const _kText   = Color(0xFF1A1D2E);
const _kMuted  = Color(0xFF9CA3AF);
const _kDanger = Color(0xFFEF4444);

// ─── DashboardPage ────────────────────────────────────────────────────────────
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: profileAsync.when(
            loading: () => const _LoadingView(key: ValueKey('loading')),
            error:   (e, _) => _ErrorView(
              key: const ValueKey('error'),
              error: e.toString(),
              onRetry: () => ref.invalidate(profileNotifierProvider),
            ),
            data: (profile) {
              final score    = profile?.completenessScore ?? 0;
              final docCount = ref.watch(documentCountProvider).valueOrNull ?? 0;
              return RefreshIndicator(
                key: const ValueKey('data'),
                color: _kAccent,
                onRefresh: () => ref.refresh(profileNotifierProvider.future),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(profile: profile, docCount: docCount),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([

                          // ── Complétion du profil ──
                          _ProfileCompletionCard(score: score)
                            .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 30),

                          // ── Actions rapides ──
                          const _SectionLabel(title: 'Actions rapides'),
                          const SizedBox(height: 14),
                          _QuickActionsGrid(score: score, docCount: docCount)
                            .animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0),
                          const SizedBox(height: 30),

                          // ── Mes espaces ──
                          const _SectionLabel(title: 'Mes espaces'),
                          const SizedBox(height: 14),
                          ..._buildSpaces(context, docCount)
                            .asMap()
                            .entries
                            .map((e) => e.value
                              .animate()
                              .fadeIn(duration: 350.ms, delay: Duration(milliseconds: 160 + e.key * 60))
                              .slideX(begin: 0.04, end: 0)),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSpaces(BuildContext context, int docCount) => [
    _SpaceCard(
      icon: Icons.folder_outlined,
      label: 'Mes Documents',
      description: 'CV, relevés de notes, recommandations',
      color: const Color(0xFFF59E0B),
      badge: docCount > 0 ? '$docCount' : null,
      onTap: () => context.push('/documents'),
    ),
    const SizedBox(height: 10),
    _SpaceCard(
      icon: Icons.send_outlined,
      label: 'Mes Candidatures',
      description: "Suivez l'état de vos dossiers",
      color: const Color(0xFF10B981),
      onTap: () => context.go('/applications'),
    ),
    const SizedBox(height: 10),
    _SpaceCard(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Messages',
      description: 'Communiquer avec votre équipe',
      color: _kAccent,
      onTap: () => context.go('/messages'),
    ),
    const SizedBox(height: 10),
  ];
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  final dynamic profile;
  final int     docCount;
  const _Header({required this.profile, required this.docCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = profile?.firstName?.toString().trim();
    final photoUrl  = profile?.photoUrl?.toString();
    final score     = profile?.completenessScore ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [_kNavy, _kBlue, Color(0xFF1E5298)],
          stops:  [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // décorations circulaires
          Positioned(top: -50, right: -50,
            child: _DecorCircle(size: 200, opacity: 0.06)),
          Positioned(bottom: 10, right: 60,
            child: _DecorCircle(size: 90,  opacity: 0.05)),
          Positioned(top: 100, left: -30,
            child: _DecorCircle(size: 120, opacity: 0.04)),
          Positioned(bottom: -20, left: 100,
            child: _DecorCircle(size: 60,  opacity: 0.04)),

          Padding(
            padding: EdgeInsets.only(
              top:    MediaQuery.of(context).padding.top + 14,
              left:   20,
              right:  20,
              bottom: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──
                Row(children: [
                  GestureDetector(
                    onTap: () => context.push('/profile/edit'),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 22)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Studium',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: 0.4,
                    )),
                  const Spacer(),
                  const _NotificationBell(),
                ]).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // ── Greeting ──
                Text(
                  'Bonjour, ${firstName?.isNotEmpty == true ? firstName : 'Étudiant'}',
                  style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.2,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 80.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 7),
                Text(
                  "Continuez à avancer vers vos objectifs académiques.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 140.ms),

                const SizedBox(height: 24),

                // ── Stats glass card ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(children: [
                    _StatChip(
                      icon: Icons.person_outline_rounded,
                      label: 'Profil',
                      value: '$score%',
                    ),
                    _StatDivider(),
                    _StatChip(
                      icon: Icons.folder_outlined,
                      label: 'Documents',
                      value: '$docCount',
                    ),
                    _StatDivider(),
                    const _StatChip(
                      icon: Icons.send_outlined,
                      label: 'Candidatures',
                      value: '—',
                    ),
                  ]),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.06, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.60)),
            const SizedBox(width: 4),
            Text(label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.60),
                fontWeight: FontWeight.w500,
              )),
          ],
        ),
        const SizedBox(height: 5),
        Text(value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          )),
      ],
    ),
  );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 34,
    color: Colors.white.withValues(alpha: 0.15),
  );
}

// ─── Notification bell ────────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        onPressed: () {},
        splashRadius: 22,
        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
      ),
      Positioned(
        right: 10, top: 10,
        child: Container(
          width: 9, height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4757),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ],
  );
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: _kText,
      letterSpacing: 0.1,
    ),
  );
}

// ─── Quick actions 2×2 grid ───────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final int score;
  final int docCount;
  const _QuickActionsGrid({required this.score, required this.docCount});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionItem(
        icon:    Icons.person_outline_rounded,
        label:   'Mon Profil',
        value:   '$score% complété',
        color:   _kAccent,
        onTap:   () => context.go('/profile'),
      ),
      _ActionItem(
        icon:    Icons.school_outlined,
        label:   'Programmes',
        value:   '100+ cursus',
        color:   const Color(0xFF7C3AED),
        onTap:   () => context.go('/programs'),
      ),
      _ActionItem(
        icon:    Icons.folder_outlined,
        label:   'Documents',
        value:   '$docCount fichier${docCount != 1 ? 's' : ''}',
        color:   const Color(0xFFF59E0B),
        onTap:   () => context.push('/documents'),
      ),
      _ActionItem(
        icon:    Icons.send_outlined,
        label:   'Candidatures',
        value:   'Bientôt',
        color:   const Color(0xFF10B981),
        onTap:   () => context.go('/applications'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.08,
      children: items.map((item) => _ActionTile(item: item)).toList(),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });
}

class _ActionTile extends StatelessWidget {
  final _ActionItem item;
  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: item.onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const Spacer(),
            Text(item.label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _kText,
              )),
            const SizedBox(height: 3),
            Text(item.value,
              style: const TextStyle(
                fontSize: 11.5,
                color: _kMuted,
                fontWeight: FontWeight.w500,
              )),
          ],
        ),
      ),
    ),
  );
}

// ─── Space card ───────────────────────────────────────────────────────────────
class _SpaceCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   description;
  final Color    color;
  final String?  badge;
  final VoidCallback onTap;

  const _SpaceCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // accent bar
            Container(
              width: 4,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // icon box
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kText,
                    )),
                  const SizedBox(height: 3),
                  Text(description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kMuted,
                      height: 1.35,
                    )),
                ],
              ),
            ),

            // badge ou chevron
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
              ),
            ] else ...[
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.40), size: 22),
            ],
            const SizedBox(width: 14),
          ],
        ),
      ),
    ),
  );
}

// ─── Profile completion card ──────────────────────────────────────────────────
class _ProfileCompletionCard extends StatelessWidget {
  final int score;
  const _ProfileCompletionCard({required this.score});

  static const _steps = ['Infos', 'Études', 'Expér.', 'Docs'];

  @override
  Widget build(BuildContext context) {
    final safe  = score.clamp(0, 100);
    final done  = (safe / 25).ceil().clamp(0, _steps.length);
    final isOk  = safe >= 100;

    final Color accent = safe >= 80
        ? const Color(0xFF10B981)
        : safe >= 50
            ? _kAccent
            : const Color(0xFFF59E0B);

    final String msg = safe == 0
        ? 'Commencez à compléter votre profil'
        : safe < 50
            ? 'Continuez — vous êtes bien parti.'
            : safe < 80
                ? 'Bon travail, encore un effort.'
                : safe < 100
                    ? 'Presque terminé, continuez.'
                    : 'Profil complet.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOk ? '✓ COMPLET' : 'EN COURS',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: accent, letterSpacing: 0.8,
                      )),
                  ),
                  const SizedBox(height: 10),
                  const Text('Complétion du profil',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
                  const SizedBox(height: 4),
                  Text(msg,
                    style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280), height: 1.45)),
                  const SizedBox(height: 14),

                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: safe / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v, minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: safe),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text('$v% complété',
                      style: TextStyle(
                        fontSize: 12, color: accent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 72, height: 72,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: safe / 100),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: v, strokeWidth: 7,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                    Center(
                      child: Text('${(v * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isEven) {
                final idx    = i ~/ 2;
                final isDone = idx < done;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 400 + idx * 80),
                  curve: Curves.easeOut,
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? accent : const Color(0xFFE5E7EB),
                    boxShadow: isDone
                        ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text('${idx + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                  ),
                );
              }
              final lineIdx = i ~/ 2;
              final filled  = lineIdx + 1 < done;
              return Expanded(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 500 + lineIdx * 80),
                  curve: Curves.easeOut,
                  height: 3,
                  decoration: BoxDecoration(
                    color: filled ? accent : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: _steps.asMap().entries.map((e) {
              final isDone = e.key < done;
              return Expanded(
                child: Text(e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: isDone ? accent : _kMuted,
                  )),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(color: _kAccent),
  );
}

// ─── Error ────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 42, color: _kDanger),
          const SizedBox(height: 12),
          const Text('Une erreur est survenue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kMuted, height: 1.4)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.white),
          ),
        ],
      ),
    ),
  );
}

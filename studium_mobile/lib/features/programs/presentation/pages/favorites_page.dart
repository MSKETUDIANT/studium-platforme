import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/program.dart';
import '../providers/program_providers.dart';
import 'program_detail_page.dart';

const _kBg     = Color(0xFFF4F6FB);
const _kNavy   = Color(0xFF1A1D2E);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);
const _kRed    = Color(0xFFEF4444);

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync  = ref.watch(programsProvider);
    final favoritesAsync = ref.watch(favoriteProgramIdsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
        child: programsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: Colors.red))),
          data: (programs) {
            final favIds = favoritesAsync.valueOrNull ?? {};
            final favPrograms = programs.where((p) => favIds.contains(p.id)).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, favPrograms.length)
                      .animate().fadeIn(duration: 400.ms).slideY(begin: -0.06),
                ),
                if (favPrograms.isEmpty)
                  SliverFillRemaining(child: _buildEmpty(context))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _FavoriteCard(program: favPrograms[i])
                            .animate(delay: Duration(milliseconds: 60 * i))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05),
                        childCount: favPrograms.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
  }

  Widget _buildHeader(BuildContext context, int count) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C1D2E), Color(0xFFC0152D), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C1D2E).withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(right: -16, top: -16, child: _DecorCircle(size: 110, opacity: 0.08)),
              Positioned(right: 50, bottom: -20, child: _DecorCircle(size: 70, opacity: 0.06)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Favoris',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Mes Programmes\nFavoris',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatPill(
                    icon: Icons.favorite_rounded,
                    label: '$count programme${count > 1 ? 's' : ''} sauvegardé${count > 1 ? 's' : ''}',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border_rounded, size: 72, color: _kGrey),
              const SizedBox(height: 16),
              const Text(
                'Aucun favori',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kNavy),
              ),
              const SizedBox(height: 8),
              const Text(
                'Appuyez sur le cœur d\'un programme pour l\'ajouter à vos favoris.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: _kGrey, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Explorer les programmes'),
                style: TextButton.styleFrom(
                  foregroundColor: _kRed,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Favorite Card ────────────────────────────────────────────────────────────

class _FavoriteCard extends ConsumerWidget {
  final Program program;
  const _FavoriteCard({required this.program});

  Color get _accentColor => switch (program.level) {
    'bachelor' => const Color(0xFF4880FF),
    'master'   => const Color(0xFF7C3AED),
    'phd'      => const Color(0xFF059669),
    _          => const Color(0xFF4880FF),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds    = ref.watch(favoriteProgramIdsProvider).valueOrNull ?? {};
    final isFav     = favIds.contains(program.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProgramDetailPage(program: program)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bande colorée gauche
            Container(
              width: 5,
              height: 80,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            const SizedBox(width: 14),
            // Icône université
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_rounded, color: _accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.programName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      program.universityName,
                      style: const TextStyle(fontSize: 12, color: _kGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (program.country != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: _kGrey),
                        const SizedBox(width: 2),
                        Text(
                          program.country!,
                          style: const TextStyle(fontSize: 11, color: _kGrey),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            // Bouton cœur
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? _kRed : _kGrey,
                size: 22,
              ),
              onPressed: () => ref.read(favoriteProgramIdsProvider.notifier).toggle(program.id),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

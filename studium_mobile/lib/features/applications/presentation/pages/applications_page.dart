import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/application.dart';
import '../providers/application_providers.dart';

const _kBg     = Color(0xFFF4F6FB);
const _kNavy   = Color(0xFF1A1D2E);
const _kBlue   = Color(0xFF4880FF);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);

class ApplicationsPage extends ConsumerWidget {
  const ApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
        child: applicationsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: _kBlue)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(e.toString(),
                  style: const TextStyle(color: Colors.red)),
            ),
          ),
          data: (apps) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(apps)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.06),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: _NewCandidatureButton(
                    onTap: () => context.push('/applications/new'),
                  ),
                ).animate().fadeIn(delay: 120.ms).slideY(begin: .04),
              ),
              apps.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _ApplicationCard(app: apps[i])
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 80 + i * 55),
                                duration: const Duration(milliseconds: 260),
                              )
                              .slideY(
                                begin: .05,
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                              ),
                          childCount: apps.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  // ─── Header card (même pattern que ProgramsPage) ──────────────────────────

  Widget _buildHeader(List<Application> apps) {
    final total     = apps.length;
    final enCours   = apps.where((a) => a.isActive).length;
    final acceptees =
        apps.where((a) => a.status == ApplicationStatus.accepted).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0D1F42),
              Color(0xFF1565C0),
              Color(0xFF1E5298),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1F42).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Cercles décoratifs
            const Positioned(
              right: -16, top: -16,
              child: _DecorCircle(size: 110, opacity: 0.08),
            ),
            const Positioned(
              right: 50, bottom: -20,
              child: _DecorCircle(size: 70, opacity: 0.06),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge icône + label
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dossiers',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                const Text(
                  'Mes candidatures',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                // Stats pills
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatPill(
                      icon: Icons.send_outlined,
                      label: '$total dossier${total > 1 ? 's' : ''}',
                    ),
                    _StatPill(
                      icon: Icons.schedule_outlined,
                      label: '$enCours en cours',
                    ),
                    _StatPill(
                      icon: Icons.check_circle_outline,
                      label:
                          '$acceptees acceptée${acceptees > 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            40, 24, 40, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_outlined,
                  size: 36, color: _kBlue),
            ),
            const SizedBox(height: 20),
            const Text('Aucune candidature',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kNavy)),
            const SizedBox(height: 8),
            const Text(
              'Explorez les programmes et soumettez\nvotre première candidature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: _kGrey, height: 1.5),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms),
      ),
    );
  }
}

// ─── Application card ─────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final Application app;
  const _ApplicationCard({required this.app});

  Color get _statusColor => switch (app.status) {
    ApplicationStatus.accepted        => const Color(0xFF10B981),
    ApplicationStatus.rejected        => const Color(0xFFEF4444),
    ApplicationStatus.needsFix        => const Color(0xFFF59E0B),
    ApplicationStatus.verified ||
    ApplicationStatus.sent            => _kBlue,
    ApplicationStatus.submitted ||
    ApplicationStatus.pendingDecision => const Color(0xFF6366F1),
    _                                 => const Color(0xFFD1D5DB),
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/applications/${app.id}', extra: app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.school_outlined,
                      color: _statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.programName ?? 'Programme',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kNavy),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        app.universityName ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: _kGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (app.country != null) ...[
                        const SizedBox(height: 2),
                        Text(app.country!,
                            style: const TextStyle(
                                fontSize: 11, color: _kGrey)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    app.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor),
                  ),
                ),
              ],
            ),
          ),
          if (app.submittedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: _kGrey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(app.submittedAt!),
                  style: const TextStyle(fontSize: 11, color: _kGrey),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ─── Header helpers (même que ProgramsPage) ───────────────────────────────────

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

class _NewCandidatureButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewCandidatureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4880FF), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.28),
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
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Nouvelle candidature',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

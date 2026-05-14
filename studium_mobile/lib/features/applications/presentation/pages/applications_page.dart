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
        body: applicationsAsync.when(
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
              _buildSliverHeader(apps),
              apps.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState(context))
                  : SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _ApplicationCard(app: apps[i])
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 60 + i * 50),
                                duration: const Duration(milliseconds: 260),
                              )
                              .slideY(
                                begin: .06,
                                duration:
                                    const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                              ),
                          childCount: apps.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/applications/new'),
          label: const Text('Nouvelle candidature',
              style: TextStyle(fontWeight: FontWeight.w700)),
          icon: const Icon(Icons.add),
          backgroundColor: _kBlue,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
    );
  }

  // ─── Sliver header ──────────────────────────────────────────────────────────

  Widget _buildSliverHeader(List<Application> apps) {
    final total     = apps.length;
    final enCours   = apps.where((a) => a.isActive).length;
    final acceptees =
        apps.where((a) => a.status == ApplicationStatus.accepted).length;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1D2E), Color(0xFF2D3150)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes candidatures',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -.3,
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Aucune candidature pour l\'instant'
                      : '$total candidature${total > 1 ? 's' : ''} au total',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
                const SizedBox(height: 20),
                Row(children: [
                  _StatChip(
                    value: total,
                    label: 'Total',
                    color: Colors.white,
                    bg:    Colors.white.withValues(alpha: 0.12),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(width: 10),
                  _StatChip(
                    value: enCours,
                    label: 'En cours',
                    color: const Color(0xFFFBBF24),
                    bg:    const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  ).animate().fadeIn(delay: 140.ms),
                  const SizedBox(width: 10),
                  _StatChip(
                    value: acceptees,
                    label: 'Acceptées',
                    color: const Color(0xFF34D399),
                    bg:    const Color(0xFF34D399).withValues(alpha: 0.15),
                  ).animate().fadeIn(delay: 180.ms),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final int    value;
  final String label;
  final Color  color;
  final Color  bg;
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(children: [
          Text(
            '$value',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w600)),
        ]),
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
          // Colored accent bar
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
                        style:
                            const TextStyle(fontSize: 12, color: _kGrey),
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
                Icon(Icons.calendar_today_outlined,
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

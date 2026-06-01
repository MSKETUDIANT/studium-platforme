import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/program.dart';
import '../providers/program_providers.dart';

const _kBg     = Color(0xFFF4F6FB);
const _kText   = Color(0xFF1A1D2E);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);

class ProgramDetailPage extends ConsumerWidget {
  final Program program;
  const ProgramDetailPage({super.key, required this.program});

  Color get _accentColor => switch (program.level) {
        'bachelor' => const Color(0xFF4880FF),
        'master'   => const Color(0xFF7C3AED),
        'phd'      => const Color(0xFF059669),
        _          => const Color(0xFF4880FF),
      };

  Color get _accentDark => switch (program.level) {
        'bachelor' => const Color(0xFF2563EB),
        'master'   => const Color(0xFF5B21B6),
        'phd'      => const Color(0xFF047857),
        _          => const Color(0xFF2563EB),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 72;
    final favIds = ref.watch(favoriteProgramIdsProvider).valueOrNull ?? {};
    final isFav  = favIds.contains(program.id);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            // ─── Gradient header ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 210,
              pinned: true,
              backgroundColor: _accentColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border,
                    color: isFav ? const Color(0xFFFF6B6B) : Colors.white,
                  ),
                  onPressed: () => ref
                      .read(favoriteProgramIdsProvider.notifier)
                      .toggle(program.id),
                ),
              ],
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_accentColor, _accentDark],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Text(
                              program.levelLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            program.programName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.account_balance_outlined,
                                  size: 14,
                                  color: Colors.white70),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  program.universityName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Content ──────────────────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick-stats row
                  _QuickStats(program: program, accent: _accentColor)
                      .animate().fadeIn(delay: 80.ms).slideY(begin: .04),
                  const SizedBox(height: 16),

                  // Informations générales
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                            'Informations générales', _accentColor),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Pays',
                          value: program.country,
                        ),
                        _InfoRow(
                          icon: Icons.translate_outlined,
                          label: 'Langue',
                          value: program.language,
                        ),
                        _InfoRow(
                          icon: Icons.access_time_outlined,
                          label: 'Durée',
                          value: program.duration,
                        ),
                        _InfoRow(
                          icon: Icons.euro_outlined,
                          label: 'Coût',
                          value: program.costLabel,
                          valueColor: program.cost == null
                              ? null
                              : const Color(0xFF059669),
                        ),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Deadline',
                          value: program.deadlineLabel,
                          isLast: true,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 140.ms).slideY(begin: .04),

                  // Description
                  if (program.description != null &&
                      program.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Description', _accentColor),
                          const SizedBox(height: 10),
                          Text(
                            program.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _kText,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: .04),
                  ],

                  // Documents requis
                  if (program.requirements != null &&
                      program.requirements!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Documents requis', _accentColor),
                          const SizedBox(height: 12),
                          ...program.requirements!.map(
                            (req) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: _accentColor
                                          .withValues(alpha: 0.10),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.check,
                                        size: 11, color: _accentColor),
                                  ),
                                  Expanded(
                                    child: Text(
                                      req,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: _kText,
                                          height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 260.ms).slideY(begin: .04),
                  ],

                  // Contact
                  if (program.contactEmail != null &&
                      program.contactEmail!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Card(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.email_outlined,
                                size: 18, color: _accentColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Contact',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _kGrey,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  program.contactEmail!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: .04),
                  ],

                  const SizedBox(height: 24),

                  // Bouton candidater
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentColor, _accentDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/applications/new', extra: program),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_outlined,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'Soumettre une candidature',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 340.ms).slideY(begin: .04),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/* ─── Widgets helpers ─────────────────────────────────────────────────────── */

class _QuickStats extends StatelessWidget {
  final Program program;
  final Color accent;
  const _QuickStats({required this.program, required this.accent});

  @override
  Widget build(BuildContext context) {
    final items = <_StatItem>[
      _StatItem(Icons.location_on_outlined, program.country ?? '—'),
      _StatItem(Icons.translate_outlined, program.language ?? '—'),
      _StatItem(Icons.access_time_outlined, program.duration ?? '—'),
    ];

    return Row(
      children: items
          .map(
            (s) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                    right: s == items.last ? 0 : 8),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(s.icon, size: 18, color: accent),
                    const SizedBox(height: 6),
                    Text(
                      s.value,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String value;
  _StatItem(this.icon, this.value);
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color accent;
  const _SectionTitle(this.text, this.accent);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: _kGrey),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: _kGrey),
              ),
              const Spacer(),
              Text(
                value ?? '—',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? _kText,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(color: _kBorder, height: 1),
      ],
    );
  }
}
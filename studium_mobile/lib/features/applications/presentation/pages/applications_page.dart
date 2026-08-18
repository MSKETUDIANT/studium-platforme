import '../../../../core/i18n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/application.dart';
import '../providers/application_providers.dart';
import '../../../programs/presentation/providers/program_providers.dart';

const _kNavy   = Color(0xFF1A1D2E);
const _kBlue   = Color(0xFF4880FF);
const _kGrey   = Color(0xFF9CA3AF);

enum _StatusFilter { all, pending, needsFix, sent, accepted, rejected }

extension on _StatusFilter {
  String get label => switch (this) {
    _StatusFilter.all      => 'Toutes',
    _StatusFilter.pending  => 'En attente',
    _StatusFilter.needsFix => 'À corriger',
    _StatusFilter.sent     => 'Envoyée',
    _StatusFilter.accepted => 'Acceptée',
    _StatusFilter.rejected => 'Refusée',
  };

  bool matches(ApplicationStatus s) => switch (this) {
    _StatusFilter.all      => true,
    _StatusFilter.pending  => s == ApplicationStatus.submitted ||
        s == ApplicationStatus.verified ||
        s == ApplicationStatus.pendingDecision,
    _StatusFilter.needsFix => s == ApplicationStatus.needsFix,
    _StatusFilter.sent     => s == ApplicationStatus.sent,
    _StatusFilter.accepted => s == ApplicationStatus.accepted,
    _StatusFilter.rejected => s == ApplicationStatus.rejected ||
        s == ApplicationStatus.archived,
  };
}

class ApplicationsPage extends ConsumerStatefulWidget {
  const ApplicationsPage({super.key});

  @override
  ConsumerState<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends ConsumerState<ApplicationsPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _StatusFilter _filter = _StatusFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Application> _applyFilters(List<Application> apps) {
    final query = _query.trim().toLowerCase();
    return apps.where((a) {
      if (!_filter.matches(a.status)) return false;
      if (query.isEmpty) return true;
      final haystack =
          '${a.programName ?? ''} ${a.universityName ?? ''} ${a.country ?? ''}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  bool get _hasActiveFilter => _query.trim().isNotEmpty || _filter != _StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
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
          data: (apps) {
            final visible = _applyFilters(apps);
            return RefreshIndicator(
              color: _kBlue,
              backgroundColor: Colors.white,
              onRefresh: () async => ref.invalidate(myApplicationsProvider),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(context, apps)
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
                  if (apps.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSearchAndFilterBar()
                          .animate()
                          .fadeIn(delay: 160.ms)
                          .slideY(begin: .04),
                    ),
                  if (apps.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    )
                  else if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildNoResultsState(),
                    )
                  else
                    _buildList(context, visible,
                        showSections: !_hasActiveFilter),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  //  Barre de recherche + filtres de statut

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Rechercher un programme, une université...',
                hintStyle: const TextStyle(fontSize: 13, color: _kGrey),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 19, color: _kGrey),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: _kGrey),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _query = '';
                        }),
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _StatusFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _StatusFilter.values[i];
                final selected = f == _filter;
                return ChoiceChip(
                  label: Text(f.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _kNavy,
                  ),
                  selectedColor: _kBlue,
                  backgroundColor: const Color(0xFFF3F4F6),
                  showCheckmark: false,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: _kGrey),
            const SizedBox(height: 14),
            const Text('Aucun résultat',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _kNavy)),
            const SizedBox(height: 6),
            const Text(
              'Aucune candidature ne correspond à ta recherche.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _kGrey),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() {
                _searchCtrl.clear();
                _query  = '';
                _filter = _StatusFilter.all;
              }),
              child: const Text('Réinitialiser les filtres',
                  style: TextStyle(
                      color: _kBlue, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  //  Header card (même pattern que ProgramsPage)

  Widget _buildHeader(BuildContext context, List<Application> apps) {
    final total     = apps.length;
    final enCours   = apps.where((a) => a.isActive).length;
    final acceptees =
        apps.where((a) => a.status == ApplicationStatus.accepted).length;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF08122E), Color(0xFF153EA8), Color(0xFF1A67D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                right: -20, top: -20,
                child: _DecorCircle(size: 130, opacity: 0.07),
              ),
              const Positioned(
                right: 60, bottom: -30,
                child: _DecorCircle(size: 80, opacity: 0.05),
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
                  Text(
                    context.s.navDossiers,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(
                  context.s.myApplications,
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
    ),
  );
  }

  //  Liste principale avec section brouillons

  Widget _buildList(BuildContext context, List<Application> apps,
      {required bool showSections}) {
    final bottom = MediaQuery.of(context).padding.bottom + 90;

    if (!showSections) {
      // Vue filtrée/recherchée : liste plate, sans en-têtes de section,
      // dans l'ordre renvoyé par le filtre.
      final items = <Widget>[
        ...apps.asMap().entries.map((e) {
          final app   = e.value;
          final delay = Duration(milliseconds: 60 + e.key * 50);
          final card  = app.status == ApplicationStatus.draft
              ? _DraftCard(app: app)
              : _ApplicationCard(app: app);
          return card
              .animate()
              .fadeIn(delay: delay)
              .slideY(begin: .04, duration: 250.ms, curve: Curves.easeOut);
        }),
        SizedBox(height: bottom),
      ];
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        sliver: SliverList(delegate: SliverChildListDelegate(items)),
      );
    }

    final drafts = apps.where((a) => a.status == ApplicationStatus.draft).toList();
    final others = apps.where((a) => a.status != ApplicationStatus.draft).toList();

    final items = <Widget>[
      if (drafts.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
          child: Row(children: [
            Container(
              width: 3, height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'A COMPLETER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF59E0B),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${drafts.length}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ]),
        ),
        ...drafts.asMap().entries.map((e) =>
          _DraftCard(app: e.value)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 60 + e.key * 50))
            .slideY(begin: .04, duration: 250.ms, curve: Curves.easeOut),
        ),
        if (others.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
            child: Row(children: [
              Container(
                width: 3, height: 13,
                decoration: BoxDecoration(
                  color: _kBlue, borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EN COURS',
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: _kBlue, letterSpacing: 0.6,
                ),
              ),
            ]),
          ),
      ],
      ...others.asMap().entries.map((e) {
        final delay = Duration(
            milliseconds: 60 + (drafts.length + e.key) * 50);
        return _ApplicationCard(app: e.value)
            .animate()
            .fadeIn(delay: delay)
            .slideY(begin: .04, duration: 250.ms, curve: Curves.easeOut);
      }),
      SizedBox(height: bottom),
    ];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(items),
      ),
    );
  }

  //  Empty state

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
            Text(context.s.noApplications,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kNavy)),
            const SizedBox(height: 8),
            Text(
              context.s.noApplicationsDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: _kGrey, height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.go('/programs'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1852), Color(0xFF4880FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Explorer les programmes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms),
      ),
    );
  }
}

// Carte brouillon

class _DraftCard extends ConsumerWidget {
  final Application app;
  const _DraftCard({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const amber = Color(0xFFF59E0B);

    // Retrouve le programme complet pour ouvrir le wizard avec les requis
    final programs = ref.watch(programsProvider).valueOrNull ?? [];
    final program  = programs.where((p) => p.id == app.programId).firstOrNull;

    return GestureDetector(
      onTap: () => context.push(
        '/applications/new',
        extra: {'program': program, 'draftId': app.id, 'motivationLetter': app.motivationText},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: amber.withValues(alpha: 0.10),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: amber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.programName ?? 'Programme',
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _kNavy),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(app.universityName ?? '',
                          style: const TextStyle(fontSize: 12, color: _kGrey),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (app.country != null)
                        Text(app.country!,
                            style: const TextStyle(fontSize: 11, color: _kGrey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Brouillon',
                    style: TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w800, color: amber),
                  ),
                ),
              ],
            ),
          ),
          // Footer "Reprendre"
          Container(
            decoration: const BoxDecoration(
              color: amber,
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Reprendre ma candidature',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

//  Application card

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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? _statusColor.withValues(alpha: 0.20)
                : _statusColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : [
            BoxShadow(
              color: _statusColor.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
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

//  Header helpers (même que ProgramsPage) 

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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  context.s.newApplication,
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

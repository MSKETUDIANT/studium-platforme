import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/program.dart';
import '../providers/program_providers.dart';
import 'program_detail_page.dart';
import 'favorites_page.dart';
import '../../../../core/services/cache_service.dart';

//  Constantes design 

const _kBlue    = Color(0xFF4880FF);
const _kGrey    = Color(0xFF9CA3AF);
const _kBorder  = Color(0xFFE5E7EB);

const _kLevels = [
  {'value': '',         'label': 'Tous'},
  {'value': 'bachelor', 'label': 'Licence'},
  {'value': 'master',   'label': 'Master'},
  {'value': 'phd',      'label': 'Doctorat'},
];

const _kCostRanges = [
  {'value': 'free',  'label': 'Gratuit'},
  {'value': '<1k',   'label': '< 1 000 '},
  {'value': '1-5k',  'label': '1 000  5 000 '},
  {'value': '5-15k', 'label': '5 000  15 000 '},
  {'value': '>15k',  'label': '> 15 000 '},
];

const _kDeadlines = [
  {'value': '1m',   'label': 'Dans 1 mois'},
  {'value': '3m',   'label': 'Dans 3 mois'},
  {'value': '6m',   'label': 'Dans 6 mois'},
  {'value': 'past', 'label': 'Expirée'},
];

const _kDomains = [
  'Informatique', 'Ingénierie', 'Commerce / Gestion', 'Droit',
  'Médecine / Santé', 'Sciences', 'Arts & Humanités',
  'Sciences Sociales', 'Éducation', 'Architecture', 'Autre',
];

// Gradients des bannières par niveau
LinearGradient _bannerGradient(String? level) => switch (level) {
  'master'   => const LinearGradient(
    colors: [Color(0xFF0F4C6E), Color(0xFF1A8C7A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  'bachelor' => const LinearGradient(
    colors: [Color(0xFF6B21A8), Color(0xFF3B82F6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  'phd'      => const LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  _          => const LinearGradient(
    colors: [Color(0xFF374151), Color(0xFF6B7280)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
};

Color _levelColor(String? level) => switch (level) {
  'bachelor' => const Color(0xFF4880FF),
  'master'   => const Color(0xFF059669),
  'phd'      => const Color(0xFF7C3AED),
  _          => _kGrey,
};

String _levelLabel(String? level) => switch (level) {
  'bachelor' => 'LICENCE',
  'master'   => 'MASTER',
  'phd'      => 'DOCTORAT',
  _          => '',
};

//  Page 

class ProgramsPage extends ConsumerStatefulWidget {
  const ProgramsPage({super.key});

  @override
  ConsumerState<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends ConsumerState<ProgramsPage> {
  final _searchCtrl = TextEditingController();
  String _selectedLevel    = '';
  String _selectedCountry  = '';
  String _selectedLang     = '';
  String _selectedDuration = '';
  String _selectedCostRange = '';
  String _selectedDeadline = '';
  String _selectedDomain   = '';
  String _query            = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasActiveSearch =>
      _query.isNotEmpty ||
      _selectedLevel.isNotEmpty ||
      _selectedCountry.isNotEmpty ||
      _selectedLang.isNotEmpty ||
      _selectedDuration.isNotEmpty ||
      _selectedCostRange.isNotEmpty ||
      _selectedDeadline.isNotEmpty ||
      _selectedDomain.isNotEmpty;

  List<Program> _filter(List<Program> programs) => programs.where((p) {
        final matchLevel    = _selectedLevel.isEmpty    || p.level    == _selectedLevel;
        final matchCountry  = _selectedCountry.isEmpty  || p.country  == _selectedCountry;
        final matchLang     = _selectedLang.isEmpty     || p.language == _selectedLang;
        final matchDuration = _selectedDuration.isEmpty || p.duration == _selectedDuration;

        bool matchCost = true;
        if (_selectedCostRange.isNotEmpty) {
          final c = p.cost?.toDouble();
          matchCost = switch (_selectedCostRange) {
            'free'  => c == 0,
            '<1k'   => c != null && c > 0 && c < 1000,
            '1-5k'  => c != null && c >= 1000 && c <= 5000,
            '5-15k' => c != null && c > 5000 && c <= 15000,
            '>15k'  => c != null && c > 15000,
            _       => true,
          };
        }

        bool matchDeadline = true;
        if (_selectedDeadline.isNotEmpty) {
          final now = DateTime.now();
          final dl  = p.deadline;
          matchDeadline = switch (_selectedDeadline) {
            '1m'   => dl != null && dl.isAfter(now) && dl.isBefore(now.add(const Duration(days: 30))),
            '3m'   => dl != null && dl.isAfter(now) && dl.isBefore(now.add(const Duration(days: 90))),
            '6m'   => dl != null && dl.isAfter(now) && dl.isBefore(now.add(const Duration(days: 180))),
            'past' => dl != null && dl.isBefore(now),
            _      => true,
          };
        }

        final matchDomain = _selectedDomain.isEmpty || p.domain == _selectedDomain;

        final matchQuery = _query.isEmpty ||
            p.programName.toLowerCase().contains(_query) ||
            p.universityName.toLowerCase().contains(_query) ||
            (p.country ?? '').toLowerCase().contains(_query);

        return matchLevel && matchCountry && matchLang && matchDuration &&
               matchCost && matchDeadline && matchDomain && matchQuery;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: programsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _kBlue)),
          error: (e, _) => Center(
            child: Text('Erreur : $e',
                style: const TextStyle(color: Colors.red)),
          ),
          data: (programs) {
            final filtered = _filter(programs);
            return RefreshIndicator(
              color: _kBlue,
              backgroundColor: Colors.white,
              onRefresh: () async {
                await CacheService.instance.remove(CacheKeys.programs);
                ref.invalidate(programsProvider);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(programs)
                      .animate().fadeIn(duration: 400.ms).slideY(begin: -0.06),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildSearchBar(),
                  ),
                ),
                SliverToBoxAdapter(child: _buildFilterRow(programs)),
                if (!_hasActiveSearch)
                  SliverToBoxAdapter(child: _buildRecommendedSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                if (filtered.isEmpty)
                  SliverFillRemaining(child: _buildEmpty())
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 90),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ProgramCard(
                          program: filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProgramDetailPage(program: filtered[i]),
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: 60 * i))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(List<Program> programs) {
    final total      = programs.length;
    final countries  = programs.map((p) => p.country).whereType<String>().toSet().length;
    final languages  = programs.map((p) => p.language).whereType<String>().toSet().length;

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
                // Icône + titre
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Programmes',
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
                  'Catalogue des\nFormations',
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
                      icon: Icons.library_books_outlined,
                      label: '$total formation${total > 1 ? 's' : ''}',
                    ),
                    _StatPill(
                      icon: Icons.public_outlined,
                      label: '$countries pay${countries > 1 ? 's' : ''}',
                    ),
                    _StatPill(
                      icon: Icons.translate_outlined,
                      label: '$languages langue${languages > 1 ? 's' : ''}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Bouton Mes Favoris
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFF6B6B)),
                        SizedBox(width: 7),
                        Text(
                          'Mes Favoris',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward_ios, size: 11, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E2A52) : _kBorder,
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Rechercher une formation',
            hintStyle: const TextStyle(fontSize: 13, color: _kGrey),
            prefixIcon: const Icon(Icons.search, size: 18, color: _kGrey),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: _kGrey),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(List<Program> all) {
    final countries = all.map((p) => p.country).whereType<String>().toSet().toList()..sort();
    final langs     = all.map((p) => p.language).whereType<String>().toSet().toList()..sort();
    final durations = all.map((p) => p.duration).whereType<String>().toSet().toList()..sort();
    final anyActive = _selectedLevel.isNotEmpty     || _selectedCountry.isNotEmpty  ||
                      _selectedLang.isNotEmpty      || _selectedDuration.isNotEmpty ||
                      _selectedCostRange.isNotEmpty || _selectedDeadline.isNotEmpty ||
                      _selectedDomain.isNotEmpty;

    String costLabel() {
      if (_selectedCostRange.isEmpty) return 'Coût';
      return _kCostRanges.firstWhere(
        (r) => r['value'] == _selectedCostRange,
        orElse: () => {'label': _selectedCostRange},
      )['label']!;
    }

    String deadlineLabel() {
      if (_selectedDeadline.isEmpty) return 'Deadline';
      return _kDeadlines.firstWhere(
        (d) => d['value'] == _selectedDeadline,
        orElse: () => {'label': _selectedDeadline},
      )['label']!;
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          _FilterBtn(
            icon: anyActive ? Icons.close : Icons.tune,
            label: anyActive ? 'Réinitialiser' : 'Filtres',
            active: anyActive,
            onTap: () {
              if (anyActive) {
                setState(() {
                  _selectedLevel     = '';
                  _selectedCountry   = '';
                  _selectedLang      = '';
                  _selectedDuration  = '';
                  _selectedCostRange = '';
                  _selectedDeadline  = '';
                  _selectedDomain    = '';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          _DropBtn(
            label: _selectedCountry.isEmpty ? 'Pays' : _selectedCountry,
            active: _selectedCountry.isNotEmpty,
            onTap: () => _showPickerSheet(
              title: 'Pays',
              options: countries,
              selected: _selectedCountry,
              onSelect: (v) => setState(() => _selectedCountry = v),
            ),
          ),
          const SizedBox(width: 8),
          _DropBtn(
            label: _selectedLevel.isEmpty
                ? 'Niveau'
                : _kLevels.firstWhere(
                    (l) => l['value'] == _selectedLevel,
                    orElse: () => {'label': _selectedLevel},
                  )['label']!,
            active: _selectedLevel.isNotEmpty,
            onTap: () => _showPickerSheet(
              title: 'Niveau',
              options: _kLevels.skip(1).map((l) => l['value']!).toList(),
              labels: {for (final l in _kLevels) l['value']!: l['label']!},
              selected: _selectedLevel,
              onSelect: (v) => setState(() => _selectedLevel = v),
            ),
          ),
          const SizedBox(width: 8),
          _DropBtn(
            label: _selectedLang.isEmpty ? 'Langue' : _selectedLang,
            active: _selectedLang.isNotEmpty,
            onTap: () => _showPickerSheet(
              title: 'Langue',
              options: langs,
              selected: _selectedLang,
              onSelect: (v) => setState(() => _selectedLang = v),
            ),
          ),
          const SizedBox(width: 8),
          _DropBtn(
            label: _selectedDuration.isEmpty ? 'Durée' : _selectedDuration,
            active: _selectedDuration.isNotEmpty,
            onTap: () => _showPickerSheet(
              title: 'Durée',
              options: durations,
              selected: _selectedDuration,
              onSelect: (v) => setState(() => _selectedDuration = v),
            ),
          ),
          const SizedBox(width: 8),
          _DropBtn(
            label: costLabel(),
            active: _selectedCostRange.isNotEmpty,
            onTap: () => _showPickerSheet(
              title: 'Coût',
              options: _kCostRanges.map((r) => r['value']!).toList(),
              labels: {for (final r in _kCostRanges) r['value']!: r['label']!},
              selected: _selectedCostRange,
              onSelect: (v) => setState(() => _selectedCostRange = v),
            ),
          ),
          const SizedBox(width: 8),
          _DropBtn(
            label: deadlineLabel(),
            active: _selectedDeadline.isNotEmpty,
            onTap: () => _showPickerSheet(
              title: 'Deadline',
              options: _kDeadlines.map((d) => d['value']!).toList(),
              labels: {for (final d in _kDeadlines) d['value']!: d['label']!},
              selected: _selectedDeadline,
              onSelect: (v) => setState(() => _selectedDeadline = v),
            ),
          ),
          const SizedBox(width: 8),
          _DropBtn(
            label: _selectedDomain.isEmpty ? 'Domaine' : _selectedDomain,
            active: _selectedDomain.isNotEmpty,
            onTap: () => _showPickerSheet(
              title: 'Domaine',
              options: _kDomains,
              selected: _selectedDomain,
              onSelect: (v) => setState(() => _selectedDomain = v),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Consumer(
      builder: (context, ref, _) {
        final recoAsync = ref.watch(recommendedProgramsProvider);
        final recos = recoAsync.valueOrNull ?? const <Program>[];

        // Tant que le calcul est en cours (les providers dépendants sont
        // autoDispose et se rechargent à chaque retour sur l'écran), on
        // affiche un skeleton plutôt que de masquer la section : sans ça,
        // la section semblait disparaître aléatoirement selon la vitesse
        // de chargement, alors qu'elle était simplement encore en train
        // de calculer les recommandations.
        if (recoAsync.isLoading && recos.isEmpty) {
          return _RecommendedSectionSkeleton();
        }
        // Erreur silencieuse (réseau, RLS...) : ne pas la confondre avec
        // une absence légitime de recommandations, on la masque quand même
        // ici mais elle reste visible via recoAsync.hasError si besoin de
        // debug plus tard.
        if (recos.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: _kBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Recommandé pour vous',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recos.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _RecommendedCard(
                      program: recos[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProgramDetailPage(program: recos[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPickerSheet({
    required String title,
    required List<String> options,
    Map<String, String>? labels,
    required String selected,
    required void Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.65;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle + titre
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36, height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _kBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Filtrer par $title',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(ctx).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                // liste scrollable
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    children: [
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        title: const Text('Tous',
                            style: TextStyle(fontSize: 14)),
                        trailing: selected.isEmpty
                            ? const Icon(Icons.check_circle, color: _kBlue)
                            : const Icon(Icons.radio_button_unchecked,
                                color: _kGrey),
                        onTap: () {
                          onSelect('');
                          Navigator.pop(ctx);
                        },
                      ),
                      for (final opt in options)
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          title: Text(labels?[opt] ?? opt,
                              style: const TextStyle(fontSize: 14)),
                          trailing: selected == opt
                              ? const Icon(Icons.check_circle, color: _kBlue)
                              : const Icon(Icons.radio_button_unchecked,
                                  color: _kGrey),
                          onTap: () {
                            onSelect(opt);
                            Navigator.pop(ctx);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: _kGrey),
            const SizedBox(height: 16),
            Text(
              _query.isNotEmpty || _selectedLevel.isNotEmpty
                  ? 'Aucun programme trouvé'
                  : 'Aucun programme disponible',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essayez d\'autres critères',
              style: TextStyle(fontSize: 13, color: _kGrey),
            ),
          ],
        ),
      );
}

//  Filter widgets 

class _FilterBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterBtn(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _kBlue : const Color(0xFF1A1D2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      );
}

//  Drop Button (Pays / Niveau / Langue) 

class _DropBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DropBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final surface   = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _kBlue : surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _kBlue : (isDark ? const Color(0xFF1E2A52) : _kBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: active ? Colors.white : _kGrey),
          ],
        ),
      ),
    );
  }
}

//  Programme Card 

class _ProgramCard extends ConsumerWidget {
  final Program program;
  final VoidCallback onTap;
  const _ProgramCard({required this.program, required this.onTap});

  String? _deadlineLabel() {
    final dl = program.deadline;
    if (dl == null) return null;
    final now  = DateTime.now();
    final days = dl.difference(now).inDays;
    if (days < 0)   return 'Expirée';
    if (days == 0)  return 'Aujourd\'hui !';
    if (days <= 7)  return '$days j restants';
    if (days <= 30) return '${(days / 7).ceil()} sem.';
    if (days <= 90) return '${dl.day.toString().padLeft(2,'0')}/${dl.month.toString().padLeft(2,'0')}';
    return null;
  }

  Color _deadlineColor() {
    final dl = program.deadline;
    if (dl == null) return _kGrey;
    final days = dl.difference(DateTime.now()).inDays;
    if (days < 0)  return const Color(0xFF9CA3AF);
    if (days <= 7) return const Color(0xFFEF4444);
    if (days <= 30) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlineText = _deadlineLabel();
    final favIds = ref.watch(favoriteProgramIdsProvider).valueOrNull ?? {};
    final isFav  = favIds.contains(program.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Theme.of(context).brightness == Brightness.dark
              ? Border.all(color: const Color(0xFF1E2A52)) : null,
          boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16, offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Bannière 
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: SizedBox(
                height: 155,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: _bannerGradient(program.level),
                      ),
                    ),
                    // Décors géométriques
                    Positioned(
                      right: -20, top: -20,
                      child: _GeoShape(size: 130, opacity: 0.10),
                    ),
                    Positioned(
                      left: -10, bottom: -10,
                      child: _GeoShape(size: 90, opacity: 0.07),
                    ),
                    Positioned(
                      right: 40, bottom: -30,
                      child: _GeoShape(size: 60, opacity: 0.05),
                    ),
                    // Icône + nom université centré
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.account_balance_rounded,
                                size: 26, color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            program.universityName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Favori
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(favoriteProgramIdsProvider.notifier)
                            .toggle(program.id),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border,
                            size: 17,
                            color: isFav ? const Color(0xFFFF6B6B) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Bas : badge niveau + deadline
                    Positioned(
                      bottom: 12, left: 12, right: 12,
                      child: Row(
                        children: [
                          if (program.level != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _levelColor(program.level),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _levelLabel(program.level),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          if (program.language != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                program.language!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (deadlineText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 11,
                                      color: _deadlineColor()),
                                  const SizedBox(width: 4),
                                  Text(
                                    deadlineText,
                                    style: TextStyle(
                                      color: _deadlineColor(),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //  Infos 
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.programName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    program.universityName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kBlue,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Meta row
                  Row(
                    children: [
                      if (program.country != null)
                        _MetaChip(
                          icon: Icons.location_on_outlined,
                          label: program.country!,
                        ),
                      if (program.country != null && program.duration != null)
                        const SizedBox(width: 10),
                      if (program.duration != null)
                        _MetaChip(
                          icon: Icons.schedule_outlined,
                          label: program.duration!,
                        ),
                      const Spacer(),
                      if (program.cost != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            program.costLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bouton Candidater
                  GestureDetector(
                    onTap: program.isExpired
                        ? null
                        : () => context.push('/applications/new', extra: program),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: program.isExpired
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF0B1852), Color(0xFF4880FF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        color: program.isExpired
                            ? const Color(0xFFF3F4F6)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            program.isExpired
                                ? Icons.lock_outline_rounded
                                : Icons.send_rounded,
                            size: 14,
                            color: program.isExpired
                                ? _kGrey
                                : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            program.isExpired
                                ? 'Candidature fermee'
                                : 'Candidater',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: program.isExpired ? _kGrey : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kGrey),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 12, color: _kGrey)),
        ],
      );
}

//  Header helpers 

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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

//  Motif géométrique décoratif 

class _GeoShape extends StatelessWidget {
  final double size;
  final double opacity;
  const _GeoShape({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
        ),
      );
}

//  Skeleton "Recommandé pour vous" (pendant le calcul des recommandations)

class _RecommendedSectionSkeleton extends StatelessWidget {
  const _RecommendedSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E2A52)
        : const Color(0xFFE9ECF5);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        height: 190,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 170,
              height: 190,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//  Carte "Recommandé pour vous"

class _RecommendedCard extends StatelessWidget {
  final Program program;
  final VoidCallback onTap;
  const _RecommendedCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Theme.of(context).brightness == Brightness.dark
              ? Border.all(color: const Color(0xFF1E2A52))
              : null,
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 78,
                width: double.infinity,
                decoration: BoxDecoration(gradient: _bannerGradient(program.level)),
                child: Stack(
                  children: [
                    Positioned(
                      right: -14, top: -14,
                      child: _GeoShape(size: 60, opacity: 0.12),
                    ),
                    if (program.level != null)
                      Positioned(
                        left: 10, bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _levelColor(program.level),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _levelLabel(program.level),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.programName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    program.universityName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kBlue,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (program.country != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: _kGrey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            program.country!,
                            style: const TextStyle(fontSize: 11, color: _kGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

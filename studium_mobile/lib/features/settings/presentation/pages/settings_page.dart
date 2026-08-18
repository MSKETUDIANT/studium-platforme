import 'dart:convert';

import '../../../../core/i18n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_providers.dart';

const _kNavy   = Color(0xFF1A1D2E);
const _kBlue   = Color(0xFF4880FF);
const _kBorder = Color(0xFFE5E7EB);
const _kGrey   = Color(0xFF9CA3AF);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale    = ref.watch(localeProvider);
    final isDark    = themeMode == ThemeMode.dark;
    final isFr      = locale.languageCode == 'fr';
    final email     = Supabase.instance.client.auth.currentUser?.email ?? '';
    final s         = context.s;
    final isAmbassador = ref.watch(authStateProvider).valueOrNull?.role == 'ambassador';

    final isDarkSystem = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkSystem ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, email, s)
                    .animate().fadeIn(duration: 380.ms).slideY(begin: -0.05),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    if (isAmbassador) ...[
                      _SectionHeader('Parrainage'),
                      _SettingsCard(children: [
                        _ActionTile(
                          icon: Icons.people_alt_outlined,
                          iconColor: const Color(0xFF10B981),
                          title: 'Mon espace ambassadeur',
                          subtitle: 'Lien de parrainage, filleuls, commissions',
                          onTap: () => context.push('/ambassador'),
                        ),
                      ]).animate().fadeIn(delay: 20.ms).slideY(begin: .04),
                      const SizedBox(height: 20),
                    ],

                    _SectionHeader(s.appearance),
                    _SettingsCard(children: [
                      _SwitchTile(
                        icon: Icons.dark_mode_outlined,
                        iconColor: const Color(0xFF6366F1),
                        title: s.darkMode,
                        subtitle: isDark ? s.darkModeOn : s.darkModeOff,
                        value: isDark,
                        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                      ),
                    ]).animate().fadeIn(delay: 60.ms).slideY(begin: .04),
                    const SizedBox(height: 20),

                    _SectionHeader(s.language),
                    _SettingsCard(children: [
                      _RadioTile(
                        icon: Icons.language_outlined,
                        iconColor: const Color(0xFF10B981),
                        title: 'Français',
                        selected: isFr,
                        onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('fr')),
                      ),
                      const _Divider(),
                      _RadioTile(
                        icon: Icons.language_outlined,
                        iconColor: const Color(0xFF10B981),
                        title: 'English',
                        selected: !isFr,
                        onTap: () => ref.read(localeProvider.notifier).setLocale(const Locale('en')),
                      ),
                    ]).animate().fadeIn(delay: 100.ms).slideY(begin: .04),
                    const SizedBox(height: 20),

                    _SectionHeader(s.accountSection),
                    _SettingsCard(children: [
                      _ActionTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: _kBlue,
                        title: s.changePassword,
                        onTap: () => _changePassword(context, email, s),
                      ),
                      const _Divider(),
                      _ActionTile(
                        icon: Icons.download_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        title: s.exportData,
                        onTap: () async => _exportData(context, s),
                      ),
                      const _Divider(),
                      _ActionTile(
                        icon: Icons.delete_outline_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: s.deleteAccount,
                        titleColor: const Color(0xFFEF4444),
                        onTap: () => _deleteAccount(context, ref, s),
                      ),
                    ]).animate().fadeIn(delay: 140.ms).slideY(begin: .04),
                    const SizedBox(height: 20),

                    _SectionHeader(s.supportSection),
                    _SettingsCard(children: [
                      _ActionTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        title: s.faq,
                        onTap: () => _showFaq(context, s),
                      ),
                      const _Divider(),
                      _ActionTile(
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        title: s.contactSupport,
                        subtitle: s.supportEmail,
                        onTap: () => _contactSupport(context, s),
                      ),
                      const _Divider(),
                      _ActionTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: _kGrey,
                        title: s.appVersion,
                        subtitle: '1.0.0',
                        onTap: null,
                      ),
                    ]).animate().fadeIn(delay: 180.ms).slideY(begin: .04),
                    const SizedBox(height: 20),

                    _LogoutButton(label: s.signOut)
                        .animate().fadeIn(delay: 220.ms).slideY(begin: .04),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Header 

  Widget _buildHeader(BuildContext context, String email, AppStrings s) {
    final initials = email.length >= 2
        ? email.substring(0, 2).toUpperCase()
        : email.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF08122E), Color(0xFF1250A8), Color(0xFF1A4FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF08122E).withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(right: -16, top: -16,
              child: _DecorCircle(size: 110, opacity: 0.07)),
            Positioned(right: 50, bottom: -20,
              child: _DecorCircle(size: 70, opacity: 0.05)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  Barre top : retour + icône 
                Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    s.settings,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ]),
                const SizedBox(height: 16),

                //  Avatar + email 
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4880FF), Color(0xFF2546CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.myAccount,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //  Actions 

  void _changePassword(BuildContext context, String email, AppStrings s) async {
    if (email.isEmpty) return;
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
    if (!context.mounted) return;
    _showInfoDialog(context,
      title: s.emailSent,
      body: '${s.resetLinkSent} $email.\n${s.checkEmail}',
    );
  }

  Future<void> _exportData(BuildContext context, AppStrings s) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final supabase = Supabase.instance.client;

    try {
      final profile = await supabase
          .from('student_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      final apps = await supabase
          .from('applications')
          .select('id,status,created_at,program_id')
          .eq('student_profile_id', uid);
      final docs = await supabase
          .from('documents')
          .select('type,status,created_at')
          .eq('student_profile_id', uid);

      final payload = {
        'export_date': DateTime.now().toIso8601String(),
        'profil': profile ?? {},
        'candidatures': apps,
        'documents': docs,
      };
      final rawJson = const JsonEncoder.withIndent('  ').convert(payload);

      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _ExportSheet(
          rawJson: rawJson,
          profile: profile,
          applications: apps,
          documents: docs,
          s: s,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      _showInfoDialog(context,
          title: s.exportTitle, body: 'Erreur lors de la récupération des données.');
    }
  }

  void _deleteAccount(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.deleteTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
        content: Text(s.deleteBody, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: Text(s.cancel, style: const TextStyle(color: _kGrey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.rpc('delete_my_account');
              } catch (_) {
                // continuer même si le RPC échoue (données déjà supprimées ou réseau)
              }
              await ref.read(authStateProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: Text(s.delete,
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showFaq(BuildContext context, AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FaqSheet(s: s),
    );
  }

  void _contactSupport(BuildContext context, AppStrings s) => _showInfoDialog(context,
    title: s.contactTitle,
    body: s.contactBody,
  );

  void _showInfoDialog(BuildContext context, {required String title, required String body}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _kBlue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

//  Composants 

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: _kGrey, letterSpacing: .08,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2A52) : _kBorder,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1, thickness: 1, indent: 54,
      color: isDark ? const Color(0xFF1E2A52) : _kBorder,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _IconBox(icon: icon, color: iconColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: _kGrey)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: _kBlue,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _kBorder,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _RadioTile({
    required this.icon, required this.iconColor,
    required this.title,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: _kBlue, size: 20),
        ]),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon, required this.iconColor,
    required this.title, this.titleColor, this.subtitle, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = titleColor ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: _kGrey)),
            ]),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, size: 20, color: _kGrey),
        ]),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 19, color: color),
  );
}

class _LogoutButton extends ConsumerWidget {
  final String label;
  const _LogoutButton({required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () async {
        await ref.read(authStateProvider.notifier).signOut();
        if (context.mounted) context.go('/login');
      },
      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
      label: Text(label,
          style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 15)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

//  Export Sheet (RGPD)

const _kExportProfileLabels = <String, String>{
  'id': 'Identifiant',
  'first_name': 'Prénom',
  'last_name': 'Nom',
  'birth_date': 'Date de naissance',
  'nationality': 'Nationalité',
  'country_residence': 'Pays de résidence',
  'phone': 'Téléphone',
  'address': 'Adresse',
  'photo_url': 'Photo de profil',
  'completeness_score': 'Score de complétude',
  'motivation_letter': 'Lettre de motivation',
  'academic_goals': 'Objectifs académiques',
  'career_goals': 'Objectifs de carrière',
  'ai_completeness_score': 'Score IA de complétude',
  'ai_summary': 'Résumé généré par IA',
  'ai_score_generated_at': 'Score IA généré le',
  'created_at': 'Compte créé le',
  'updated_at': 'Dernière mise à jour',
  'referral_code': 'Code de parrainage',
};

const _kExportProfileDateKeys = {
  'birth_date', 'ai_score_generated_at', 'created_at', 'updated_at',
};

const _kExportAppStatusLabels = <String, String>{
  'draft': 'Brouillon',
  'submitted': 'Soumise',
  'needs_fix': 'Correction requise',
  'verified': 'Validée',
  'sent': 'Envoyée',
  'accepted': 'Acceptée',
  'rejected': 'Refusée',
  'pending': 'Décision en attente',
  'archived': 'Archivée',
};

const _kExportDocTypeLabels = <String, String>{
  'cv': 'CV',
  'transcript': 'Relevé de notes',
  'recommendation': 'Lettre de recommandation',
  'passport': 'Passeport / Pièce d\'identité',
  'motivation_letter': 'Lettre de motivation',
  'diploma': 'Diplôme',
  'language_cert': 'Attestation de langue',
  'financial_proof': 'Justificatif de financement',
  'other': 'Autre document',
};

const _kExportDocStatusLabels = <String, String>{
  'uploaded': 'Envoyé',
  'under_review': 'En révision',
  'approved': 'Approuvé',
  'rejected': 'Rejeté',
};

String _exportFmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à ${two(local.hour)}:${two(local.minute)}';
}

String _exportFmtValue(String key, Object? value) {
  if (value == null) return '-';
  if (_kExportProfileDateKeys.contains(key)) return _exportFmtDate(value as String);
  if (key.contains('score')) return '$value%';
  return value.toString();
}

class _ExportSheet extends StatefulWidget {
  final String rawJson;
  final Map<String, dynamic>? profile;
  final List<dynamic> applications;
  final List<dynamic> documents;
  final AppStrings s;
  const _ExportSheet({
    required this.rawJson,
    required this.profile,
    required this.applications,
    required this.documents,
    required this.s,
  });

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _generatingPdf = false;

  Future<void> _sharePdf() async {
    setState(() => _generatingPdf = true);
    try {
      final navyPdf   = PdfColor.fromInt(0xFF0B1852);
      final bluePdf   = PdfColor.fromInt(0xFF153EA8);
      final greyPdf   = PdfColor.fromInt(0xFF64748B);
      final mutedPdf  = PdfColor.fromInt(0xFF94A3B8);
      final borderPdf = PdfColor.fromInt(0xFFE5E7EB);
      final bgPdf     = PdfColor.fromInt(0xFFF8FAFC);
      final today     = _exportFmtDate(DateTime.now().toIso8601String());

      pw.Widget sectionTitle(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 18),
          pw.Text(title.toUpperCase(),
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
                  color: mutedPdf, letterSpacing: 1.5)),
          pw.SizedBox(height: 8),
          pw.Divider(color: borderPdf, thickness: 0.5),
          pw.SizedBox(height: 10),
        ],
      );

      pw.Widget infoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 140,
              child: pw.Text(label, style: pw.TextStyle(fontSize: 10, color: greyPdf))),
          pw.Expanded(child: pw.Text(value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: navyPdf))),
        ]),
      );

      pw.Widget card(List<pw.Widget> rows) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bgPdf,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: borderPdf),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows),
      );

      final profileEntries = (widget.profile ?? const <String, dynamic>{})
          .entries
          .where((e) => e.value != null)
          .toList();

      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (ctx) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: bluePdf,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('EXPORT DE DONNEES (RGPD)',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white, letterSpacing: 1.2)),
              pw.SizedBox(height: 6),
              pw.Text('Studium', style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('Genere le $today',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.white)),
            ]),
          ),
          sectionTitle('Profil'),
          for (final e in profileEntries)
            infoRow(_kExportProfileLabels[e.key] ?? e.key, _exportFmtValue(e.key, e.value)),
          sectionTitle('Candidatures (${widget.applications.length})'),
          if (widget.applications.isEmpty)
            pw.Text('Aucune candidature', style: pw.TextStyle(fontSize: 10, color: greyPdf))
          else
            for (final app in widget.applications.cast<Map<String, dynamic>>())
              card([
                infoRow('Statut', _kExportAppStatusLabels[app['status']] ??
                    (app['status']?.toString() ?? '-')),
                infoRow('Creee le', _exportFmtDate(app['created_at'] as String?)),
              ]),
          sectionTitle('Documents (${widget.documents.length})'),
          if (widget.documents.isEmpty)
            pw.Text('Aucun document', style: pw.TextStyle(fontSize: 10, color: greyPdf))
          else
            for (final d in widget.documents.cast<Map<String, dynamic>>())
              card([
                infoRow('Type', _kExportDocTypeLabels[d['type']] ??
                    (d['type']?.toString() ?? '-')),
                infoRow('Statut', _kExportDocStatusLabels[d['status']] ??
                    (d['status']?.toString() ?? '-')),
                infoRow('Ajoute le', _exportFmtDate(d['created_at'] as String?)),
              ]),
        ],
      ));

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'export_donnees_studium.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur PDF : $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final applications = widget.applications;
    final documents = widget.documents;
    final rawJson = widget.rawJson;
    final s = widget.s;
    final profileEntries = (profile ?? const <String, dynamic>{})
        .entries
        .where((e) => e.value != null)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, controller) => Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: _kBorder, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.exportTitle,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: _kNavy)),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: rawJson));
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Données copiées dans le presse-papiers'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18, color: _kGrey),
                    tooltip: 'Copier le JSON',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _generatingPdf ? null : _sharePdf,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _generatingPdf
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                  label: Text(_generatingPdf ? 'Génération…' : 'Télécharger PDF',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              _ExportSection(
                title: 'Profil',
                child: Column(
                  children: [
                    for (final e in profileEntries)
                      _ExportRow(
                        label: _kExportProfileLabels[e.key] ?? e.key,
                        value: _exportFmtValue(e.key, e.value),
                      ),
                  ],
                ),
              ),
              _ExportSection(
                title: 'Candidatures (${applications.length})',
                child: applications.isEmpty
                    ? const _ExportEmpty(text: 'Aucune candidature')
                    : Column(
                        children: [
                          for (final app in applications.cast<Map<String, dynamic>>())
                            _ExportCard(rows: [
                              _ExportRow(
                                label: 'Statut',
                                value: _kExportAppStatusLabels[app['status']] ??
                                    (app['status']?.toString() ?? '-'),
                              ),
                              _ExportRow(
                                label: 'Créée le',
                                value: _exportFmtDate(app['created_at'] as String?),
                              ),
                            ]),
                        ],
                      ),
              ),
              _ExportSection(
                title: 'Documents (${documents.length})',
                child: documents.isEmpty
                    ? const _ExportEmpty(text: 'Aucun document')
                    : Column(
                        children: [
                          for (final doc in documents.cast<Map<String, dynamic>>())
                            _ExportCard(rows: [
                              _ExportRow(
                                label: 'Type',
                                value: _kExportDocTypeLabels[doc['type']] ??
                                    (doc['type']?.toString() ?? '-'),
                              ),
                              _ExportRow(
                                label: 'Statut',
                                value: _kExportDocStatusLabels[doc['status']] ??
                                    (doc['status']?.toString() ?? '-'),
                              ),
                              _ExportRow(
                                label: 'Ajouté le',
                                value: _exportFmtDate(doc['created_at'] as String?),
                              ),
                            ]),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ExportSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _ExportSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _kGrey,
                  letterSpacing: 0.3)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ExportEmpty extends StatelessWidget {
  final String text;
  const _ExportEmpty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 13, color: _kGrey));
  }
}

class _ExportCard extends StatelessWidget {
  final List<_ExportRow> rows;
  const _ExportCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(children: rows),
    );
  }
}

class _ExportRow extends StatelessWidget {
  final String label;
  final String value;
  const _ExportRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: _kGrey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12.5, color: _kNavy, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

//  FAQ Sheet

class _FaqSheet extends StatelessWidget {
  final AppStrings s;
  const _FaqSheet({required this.s});

  @override
  Widget build(BuildContext context) {
    final items = s.faqItems;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Text(s.faqTitle,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
        ),
        Expanded(
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _FaqItem(q: items[i].$1, a: items[i].$2),
          ),
        ),
      ]),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _open ? _kBlue.withValues(alpha: 0.4) : _kBorder),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Text(widget.q,
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600,
                        color: _open ? _kBlue : _kNavy)),
              ),
              Icon(
                _open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: _kGrey, size: 20,
              ),
            ]),
          ),
        ),
        if (_open) ...[
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Text(widget.a,
                style: const TextStyle(fontSize: 13, color: _kGrey, height: 1.5)),
          ),
        ],
      ]),
    );
  }
}

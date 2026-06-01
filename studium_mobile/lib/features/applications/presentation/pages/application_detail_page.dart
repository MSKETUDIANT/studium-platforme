import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/datasources/application_remote_datasource.dart';
import '../../domain/entities/application.dart';
import '../providers/application_providers.dart';

const _kNavy   = Color(0xFF1A1D2E);
const _kBlue   = Color(0xFF4880FF);
const _kGrey   = Color(0xFF9CA3AF);
const _kBg     = Color(0xFFF4F6FB);
const _kBorder = Color(0xFFE5E7EB);

class ApplicationDetailPage extends ConsumerStatefulWidget {
  final Application app;
  const ApplicationDetailPage({super.key, required this.app});

  @override
  ConsumerState<ApplicationDetailPage> createState() =>
      _ApplicationDetailPageState();
}

class _ApplicationDetailPageState
    extends ConsumerState<ApplicationDetailPage> {
  bool _submitting  = false;
  bool _generatingPdf = false;

  Application get app {
    final list = ref.watch(myApplicationsProvider).valueOrNull;
    if (list == null) return widget.app;
    final idx = list.indexWhere((a) => a.id == widget.app.id);
    return idx != -1 ? list[idx] : widget.app;
  }

  Color get _accent => switch (app.status) {
    ApplicationStatus.accepted        => const Color(0xFF10B981),
    ApplicationStatus.rejected        => const Color(0xFFEF4444),
    ApplicationStatus.needsFix        => const Color(0xFFF59E0B),
    ApplicationStatus.verified ||
    ApplicationStatus.sent            => _kBlue,
    _                                 => const Color(0xFF6366F1),
  };

  Color get _accentDark => switch (app.status) {
    ApplicationStatus.accepted        => const Color(0xFF059669),
    ApplicationStatus.rejected        => const Color(0xFFDC2626),
    ApplicationStatus.needsFix        => const Color(0xFFD97706),
    ApplicationStatus.verified ||
    ApplicationStatus.sent            => const Color(0xFF2563EB),
    _                                 => const Color(0xFF4F46E5),
  };

  Future<void> _submitDraft() async {
    setState(() => _submitting = true);
    try {
      await ref.read(myApplicationsProvider.notifier).submitDraft(app.id);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Candidature soumise avec succès'),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _generatingPdf = true);
    try {
      final doc = pw.Document();
      final accentPdf = PdfColor.fromInt(_accent.toARGB32());

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: accentPdf,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    app.statusLabel.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    app.programName ?? 'Programme',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  if (app.universityName != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      [
                        app.universityName!,
                        if (app.country != null) app.country!,
                      ].join(' · '),
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Détails de la candidature',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1A1D2E),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColor.fromInt(0xFFE5E7EB)),
            pw.SizedBox(height: 12),
            _pdfRow('Référence', app.id.substring(0, 8).toUpperCase()),
            _pdfRow('Statut', app.statusLabel),
            if (app.level != null) _pdfRow('Niveau', _levelLabel(app.level!)),
            if (app.submittedAt != null)
              _pdfRow('Date de soumission', _formatDate(app.submittedAt!)),
            if (app.country != null) _pdfRow('Pays', app.country!),
            pw.SizedBox(height: 24),
            pw.Text(
              'Suivi de candidature',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1A1D2E),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColor.fromInt(0xFFE5E7EB)),
            pw.SizedBox(height: 12),
            ..._buildPdfTimeline(),
            pw.Spacer(),
            pw.Divider(color: PdfColor.fromInt(0xFFE5E7EB)),
            pw.SizedBox(height: 8),
            pw.Text(
              'Document généré par Studium · ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          ],
        ),
      ));

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'candidature_${app.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF : $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 140,
              child: pw.Text(
                label,
                style: const pw.TextStyle(color: PdfColors.grey600),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  List<pw.Widget> _buildPdfTimeline() {
    final steps = _buildTimelineSteps();
    return steps.map((step) {
      final icon  = step.done ? '✓' : (step.current ? '●' : '○');
      final color = step.done || step.current
          ? (step.isNegative
              ? PdfColor.fromInt(0xFFEF4444)
              : PdfColor.fromInt(0xFF10B981))
          : PdfColors.grey400;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: step.done || step.current ? color : PdfColors.white,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: color, width: 1.5),
            ),
            child: pw.Center(
              child: pw.Text(
                icon,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: step.done ? PdfColors.white : color,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                step.label,
                style: pw.TextStyle(
                  fontWeight: step.current
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: step.done || step.current
                      ? PdfColor.fromInt(0xFF1A1D2E)
                      : PdfColors.grey500,
                ),
              ),
              if (step.subtitle != null)
                pw.Text(
                  step.subtitle!,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
            ],
          ),
        ]),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = app.status == ApplicationStatus.draft;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatusCard()
                      .animate()
                      .fadeIn(delay: 60.ms)
                      .slideY(begin: .06, duration: 280.ms, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  _buildCompletenessCard()
                      .animate()
                      .fadeIn(delay: 120.ms)
                      .slideY(begin: .06, duration: 280.ms, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  _buildTimeline()
                      .animate()
                      .fadeIn(delay: 180.ms)
                      .slideY(begin: .06, duration: 280.ms, curve: Curves.easeOut),
                  const SizedBox(height: 14),
                  _buildHistoryCard()
                      .animate()
                      .fadeIn(delay: 260.ms)
                      .slideY(begin: .06, duration: 280.ms, curve: Curves.easeOut),
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: isDraft
                ? Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submitDraft,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _submitting ? 'Envoi…' : 'Soumettre',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _generatingPdf ? null : _generatePdf,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kNavy,
                          side: const BorderSide(color: _kBorder, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: _generatingPdf
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                      ),
                    ),
                  ])
                : SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _generatingPdf ? null : _generatePdf,
                      icon: _generatingPdf
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        _generatingPdf ? 'Génération…' : 'Télécharger PDF',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kNavy,
                        side: const BorderSide(color: _kBorder, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Gradient SliverAppBar ─────────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _accent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_accent, _accentDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: Text(
                      app.statusLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    app.programName ?? 'Programme',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (app.universityName != null) app.universityName!,
                      if (app.country != null) app.country!,
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (app.submittedAt != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.70)),
                      const SizedBox(width: 5),
                      Text(
                        'Soumise le ${_formatDate(app.submittedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status card ──────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    return _Card(
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_statusIcon, color: _accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statut actuel',
                  style: TextStyle(fontSize: 12, color: _kGrey)),
              const SizedBox(height: 3),
              Text(
                app.statusLabel,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _accent),
              ),
            ],
          ),
        ),
        if (app.level != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _levelLabel(app.level!),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kBlue),
            ),
          ),
      ]),
    );
  }

  // ─── Completeness card ────────────────────────────────────────────────────

  Widget _buildCompletenessCard() {
    final items = <({String label, bool ok})>[
      (label: 'Candidature soumise',   ok: app.status != ApplicationStatus.draft),
      (label: 'Programme sélectionné', ok: app.programName != null),
      (label: 'Université renseignée', ok: app.universityName != null),
      (label: 'Pays de destination',   ok: app.country != null),
      (label: "Niveau d'études",       ok: app.level != null),
      (label: 'Lettre de motivation',  ok: app.motivationText != null && app.motivationText!.isNotEmpty),
    ];
    final okCount  = items.where((i) => i.ok).length;
    final allOk    = okCount == items.length;
    final badgeColor = allOk
        ? const Color(0xFF10B981)
        : okCount >= 4
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final badgeLabel = allOk
        ? 'Dossier complet'
        : okCount >= 4
            ? 'Presque complet'
            : 'Incomplet';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Complétude du dossier',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kNavy)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$okCount/${items.length} critères remplis',
            style: const TextStyle(fontSize: 12, color: _kGrey),
          ),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: item.ok
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFFEF4444).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.ok ? Icons.check : Icons.close,
                    size: 12,
                    color: item.ok
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: item.ok ? _kNavy : _kGrey,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── Timeline ─────────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    final steps  = _buildTimelineSteps();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suivi de candidature',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kNavy)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i    = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            final stepColor = step.done || step.current
                ? (step.isNegative
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981))
                : _kGrey;
            return _TimelineRow(
              label:    step.label,
              subtitle: step.subtitle,
              done:     step.done,
              current:  step.current,
              isLast:   isLast,
              color:    stepColor,
            );
          }),
        ],
      ),
    );
  }

  List<_TimelineStep> _buildTimelineSteps() {
    final s        = app.status;
    final submitted = s != ApplicationStatus.draft;
    final verified  = {
      ApplicationStatus.verified, ApplicationStatus.sent,
      ApplicationStatus.accepted, ApplicationStatus.rejected,
    }.contains(s);
    final sent     = {
      ApplicationStatus.sent, ApplicationStatus.accepted,
      ApplicationStatus.rejected,
    }.contains(s);
    final accepted = s == ApplicationStatus.accepted;
    final rejected = s == ApplicationStatus.rejected;
    final needsFix = s == ApplicationStatus.needsFix;

    return [
      _TimelineStep(
        label:    'Soumise',
        subtitle: app.submittedAt != null
            ? 'Le ${_formatDate(app.submittedAt!)}'
            : null,
        done:    submitted,
        current: s == ApplicationStatus.submitted,
      ),
      _TimelineStep(
        label:      needsFix ? 'Correction requise' : 'En vérification',
        done:       verified || needsFix,
        current:    needsFix,
        isNegative: needsFix,
      ),
      _TimelineStep(
        label:   'Dossier envoyé',
        done:    sent,
        current: s == ApplicationStatus.sent,
      ),
      _TimelineStep(
        label:      rejected
            ? 'Candidature refusée'
            : (accepted ? 'Candidature acceptée' : 'Résultat'),
        done:       accepted || rejected,
        current:    accepted || rejected,
        isNegative: rejected,
      ),
    ];
  }

  // ─── History card ─────────────────────────────────────────────────────────

  Widget _buildHistoryCard() {
    final historyAsync = ref.watch(statusHistoryProvider(app.id));
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historique des changements',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kNavy)),
          const SizedBox(height: 16),
          historyAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(
                  color: _kBlue, strokeWidth: 2),
            )),
            error: (_, __) => const Text('Impossible de charger l\'historique',
                style: TextStyle(fontSize: 13, color: _kGrey)),
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Aucun changement enregistré pour le moment.',
                    style: TextStyle(fontSize: 13, color: _kGrey),
                  ),
                );
              }
              return Column(
                children: entries.asMap().entries.map((e) {
                  final isLast = e.key == entries.length - 1;
                  return _HistoryRow(
                    entry: e.value,
                    isLast: isLast,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  IconData get _statusIcon => switch (app.status) {
    ApplicationStatus.accepted  => Icons.check_circle_outline,
    ApplicationStatus.rejected  => Icons.cancel_outlined,
    ApplicationStatus.needsFix  => Icons.edit_outlined,
    ApplicationStatus.verified  => Icons.verified_outlined,
    ApplicationStatus.sent      => Icons.send_outlined,
    _                           => Icons.hourglass_empty_outlined,
  };

  String _levelLabel(String level) => switch (level) {
    'bachelor' => 'Licence',
    'master'   => 'Master',
    'phd'      => 'Doctorat (PhD)',
    _          => level,
  };

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ─── Shared card ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

// ─── Timeline row ─────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final String  label;
  final String? subtitle;
  final bool    done;
  final bool    current;
  final bool    isLast;
  final Color   color;
  const _TimelineRow({
    required this.label,
    this.subtitle,
    required this.done,
    required this.current,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: done || current ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: done || current ? color : _kBorder, width: 2),
            ),
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : current
                    ? Center(
                        child: Container(
                          width: 8, height: 8,
                          decoration:
                              BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      )
                    : null,
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 36,
              color: done ? color.withValues(alpha: 0.3) : _kBorder,
            ),
        ]),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: done || current ? _kNavy : _kGrey,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: const TextStyle(fontSize: 12, color: _kGrey)),
              ],
              SizedBox(height: isLast ? 0 : 18),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── History row ──────────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  final StatusHistoryEntry entry;
  final bool isLast;
  const _HistoryRow({required this.entry, required this.isLast});

  static const _statusLabels = <String, String>{
    'draft':            'Brouillon',
    'submitted':        'Soumise',
    'needsfix':         'Correction requise',
    'verified':         'Vérifiée',
    'sent':             'Envoyée',
    'accepted':         'Acceptée',
    'rejected':         'Refusée',
    'pending_decision': 'Décision en attente',
    'archived':         'Archivée',
  };

  String _label(String? s) => s != null ? (_statusLabels[s] ?? s) : '—';

  String _date(DateTime? dt) => dt == null
      ? ''
      : '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 10, height: 10,
            margin: const EdgeInsets.only(top: 3),
            decoration: const BoxDecoration(
              color: _kBlue,
              shape: BoxShape.circle,
            ),
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 40,
              color: _kBorder,
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (entry.fromStatus != null) ...[
                    Text(
                      _label(entry.fromStatus),
                      style: const TextStyle(
                          fontSize: 12, color: _kGrey,
                          fontWeight: FontWeight.w500),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(Icons.arrow_forward,
                          size: 12, color: _kGrey),
                    ),
                  ],
                  Text(
                    _label(entry.toStatus),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kNavy),
                  ),
                ]),
                if (entry.createdAt != null)
                  Text(
                    _date(entry.createdAt),
                    style: const TextStyle(fontSize: 11, color: _kGrey),
                  ),
                if (entry.note != null && entry.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entry.note!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _kNavy,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _TimelineStep {
  final String  label;
  final String? subtitle;
  final bool    done;
  final bool    current;
  final bool    isNegative;
  const _TimelineStep({
    required this.label,
    this.subtitle,
    required this.done,
    required this.current,
    this.isNegative = false,
  });
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/application.dart';
import '../../../documents/domain/entities/document.dart';
import '../../../profile/domain/entities/academic_background.dart';
import '../../../profile/domain/entities/experience.dart';
import '../../../profile/domain/entities/student_profile.dart';

class _TimelineStep {
  final String label;
  final String? subtitle;
  final bool done;
  final bool current;
  final bool isNegative;
  const _TimelineStep({
    required this.label,
    this.subtitle,
    required this.done,
    required this.current,
    this.isNegative = false,
  });
}

List<_TimelineStep> _buildTimelineSteps(Application app, String Function(DateTime) formatDate) {
  final s = app.status;
  final submitted = s != ApplicationStatus.draft;
  final verified = {
    ApplicationStatus.verified, ApplicationStatus.sent,
    ApplicationStatus.accepted, ApplicationStatus.rejected,
  }.contains(s);
  final sent = {
    ApplicationStatus.sent, ApplicationStatus.accepted,
    ApplicationStatus.rejected,
  }.contains(s);
  final accepted = s == ApplicationStatus.accepted;
  final rejected = s == ApplicationStatus.rejected;
  final needsFix = s == ApplicationStatus.needsFix;

  return [
    _TimelineStep(
      label: 'Soumise',
      subtitle: app.submittedAt != null ? 'Le ${formatDate(app.submittedAt!)}' : null,
      done: submitted,
      current: s == ApplicationStatus.submitted,
    ),
    _TimelineStep(
      label: needsFix ? 'Correction requise' : 'En vérification',
      done: verified || needsFix,
      current: needsFix,
      isNegative: needsFix,
    ),
    _TimelineStep(
      label: 'Dossier envoyé',
      done: sent,
      current: s == ApplicationStatus.sent,
    ),
    _TimelineStep(
      label: rejected ? 'Candidature refusée' : (accepted ? 'Candidature acceptée' : 'Résultat'),
      done: accepted || rejected,
      current: accepted || rejected,
      isNegative: rejected,
    ),
  ];
}

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/'
    '${dt.month.toString().padLeft(2, '0')}/'
    '${dt.year}';

String _levelLabel(String level) => switch (level) {
      'bachelor' => 'Licence',
      'master' => 'Master',
      'phd' => 'Doctorat (PhD)',
      _ => level,
    };

/// Builds the multi-page application PDF dossier as raw bytes. Pure data in,
/// bytes out — no [BuildContext], no provider reads, no native share sheet.
/// Called by `_generatePdf()` in `application_detail_page.dart`, which owns
/// fetching the provider data and sharing the resulting bytes.
Future<Uint8List> buildApplicationPdfBytes({
  required Application app,
  required StudentProfile? profile,
  required List<AcademicBackground> academics,
  required List<Experience> experiences,
  required List<Document> documents,
  required String? motivationLetter,
  required Color accent,
}) async {
  final approvedDocs = documents.where((d) => d.status == DocumentStatus.approved).toList();

  final doc = pw.Document();
  final accentPdf = PdfColor.fromInt(accent.toARGB32());
  // Palette partagée avec le pack PDF dashboard (ApplicationPDF.tsx)
  final navyPdf = PdfColor.fromInt(0xFF0B1852);
  final bluePdf = PdfColor.fromInt(0xFF153EA8);
  final greyPdf = PdfColor.fromInt(0xFF64748B);
  final mutedPdf = PdfColor.fromInt(0xFF94A3B8);
  final borderPdf = PdfColor.fromInt(0xFFE5E7EB);
  final bgPdf = PdfColor.fromInt(0xFFF8FAFC);
  final today = _formatDate(DateTime.now());

  pw.Widget footer(int page, int total) => pw.Column(children: [
    pw.Divider(color: borderPdf, thickness: 0.5),
    pw.SizedBox(height: 4),
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Dossier généré par Studium · $today',
            style: pw.TextStyle(fontSize: 7.5, color: mutedPdf)),
        pw.Text('Page $page / $total',
            style: pw.TextStyle(fontSize: 7.5, color: mutedPdf)),
      ],
    ),
  ]);

  pw.Widget sectionTitle(String title) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 20),
      pw.Text(title.toUpperCase(),
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
              color: mutedPdf, letterSpacing: 1.5)),
      pw.SizedBox(height: 8),
      pw.Divider(color: borderPdf, thickness: 0.5),
      pw.SizedBox(height: 10),
    ],
  );

  pw.Widget infoRow(String label, String value, {PdfColor? valueColor}) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 7),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.SizedBox(width: 150,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 11, color: greyPdf))),
      pw.Expanded(child: pw.Text(value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold,
              color: valueColor ?? navyPdf))),
    ]),
  );

  List<pw.Widget> buildPdfTimeline() {
    final steps = _buildTimelineSteps(app, _formatDate);
    return steps.map((step) {
      final icon = step.done ? 'v' : (step.current ? '-' : '');
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
                  fontWeight: step.current ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: step.done || step.current
                      ? PdfColor.fromInt(0xFF0B1852)
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

  // ── PAGE 1 — Fiche candidature ──
  final totalPages = 1
      + (academics.isNotEmpty || experiences.isNotEmpty ? 1 : 0)
      + ((motivationLetter?.isNotEmpty ?? false) ? 1 : 0)
      + (approvedDocs.isNotEmpty ? 1 : 0);

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
    build: (pw.Context ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête coloré
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: accentPdf,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(app.statusLabel.toUpperCase(),
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white, letterSpacing: 1.2)),
            pw.SizedBox(height: 6),
            pw.Text(app.programName ?? 'Programme',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
            if (app.universityName != null) ...[
              pw.SizedBox(height: 4),
              pw.Text([app.universityName!, if (app.country != null) app.country!].join(' · '),
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.white)),
            ],
          ]),
        ),
        // Candidat
        sectionTitle('Candidat'),
        if (profile != null) ...[
          infoRow('Nom complet', profile.fullName),
          if (profile.nationality != null) infoRow('Nationalité', profile.nationality!),
          if (profile.phone != null) infoRow('Téléphone', profile.phone!),
          if (profile.email != null) infoRow('Email', profile.email!),
          if (profile.countryResidence != null)
            infoRow('Pays de résidence', profile.countryResidence!),
        ],
        // Détails candidature
        sectionTitle('Détails de la candidature'),
        infoRow('Référence', app.id.substring(0, 8).toUpperCase()),
        infoRow('Statut', app.statusLabel, valueColor: bluePdf),
        if (app.level != null) infoRow('Niveau', _levelLabel(app.level!)),
        if (app.submittedAt != null) infoRow('Date de soumission', _formatDate(app.submittedAt!)),
        if (app.country != null) infoRow('Pays destination', app.country!),
        // Suivi
        sectionTitle('Suivi de candidature'),
        ...buildPdfTimeline(),
        pw.Spacer(),
        footer(1, totalPages),
      ],
    ),
  ));

  // ── PAGE 2 — Profil académique & Expériences ──
  if (academics.isNotEmpty || experiences.isNotEmpty) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Profil académique',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: navyPdf)),
          if (academics.isNotEmpty) ...[
            sectionTitle('Formations'),
            ...academics.map((a) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: bgPdf,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderPdf),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(a.degree,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: navyPdf)),
                pw.SizedBox(height: 3),
                pw.Text(a.university,
                    style: pw.TextStyle(fontSize: 11, color: greyPdf)),
                if (a.year != null || a.average != null)
                  pw.Text(
                    [if (a.year != null) 'Obtenu en ${a.year}',
                     if (a.average != null) 'Moyenne : ${a.average}'].join(' · '),
                    style: pw.TextStyle(fontSize: 10, color: greyPdf),
                  ),
              ]),
            )),
          ],
          if (experiences.isNotEmpty) ...[
            sectionTitle('Expériences professionnelles'),
            ...experiences.map((e) {
              final period = [
                if (e.startDate != null) _formatDate(e.startDate!),
                e.isCurrent ? 'Présent' : (e.endDate != null ? _formatDate(e.endDate!) : ''),
              ].where((s) => s.isNotEmpty).join(' > ');
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: bgPdf,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderPdf),
                ),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('${e.position} - ${e.company}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: navyPdf)),
                  if (period.isNotEmpty)
                    pw.Text(period, style: pw.TextStyle(fontSize: 10, color: greyPdf)),
                  if (e.description != null && e.description!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(e.description!, style: pw.TextStyle(fontSize: 11, color: navyPdf)),
                  ],
                ]),
              );
            }),
          ],
          pw.Spacer(),
          footer(2, totalPages),
        ],
      ),
    ));
  }

  // ── PAGE 3 — Lettre de motivation ──
  if (motivationLetter?.isNotEmpty ?? false) {
    final pageNum = 2 + (academics.isNotEmpty || experiences.isNotEmpty ? 1 : 0);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Lettre de motivation',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: navyPdf)),
          pw.SizedBox(height: 8),
          pw.Divider(color: borderPdf),
          pw.SizedBox(height: 16),
          pw.Text(motivationLetter!,
              style: pw.TextStyle(fontSize: 11, color: navyPdf, lineSpacing: 3)),
          if (profile?.academicGoals?.isNotEmpty ?? false) ...[
            sectionTitle('Objectifs académiques'),
            pw.Text(profile!.academicGoals!,
                style: pw.TextStyle(fontSize: 11, color: navyPdf, lineSpacing: 3)),
          ],
          if (profile?.careerGoals?.isNotEmpty ?? false) ...[
            sectionTitle('Objectifs professionnels'),
            pw.Text(profile!.careerGoals!,
                style: pw.TextStyle(fontSize: 11, color: navyPdf, lineSpacing: 3)),
          ],
          pw.Spacer(),
          footer(pageNum, totalPages),
        ],
      ),
    ));
  }

  // ── PAGE 4 — Documents soumis ──
  if (approvedDocs.isNotEmpty) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Documents soumis',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: navyPdf)),
          pw.SizedBox(height: 8),
          pw.Divider(color: borderPdf),
          pw.SizedBox(height: 16),
          ...approvedDocs.asMap().entries.map((entry) {
            final i = entry.key;
            final doc2 = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: i.isEven ? bgPdf : PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderPdf),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(doc2.typeLabel,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold,
                            color: navyPdf)),
                    pw.Text(doc2.fileName,
                        style: pw.TextStyle(fontSize: 10, color: greyPdf)),
                  ]),
                  pw.Row(children: [
                    pw.Text(doc2.sizeLabel,
                        style: pw.TextStyle(fontSize: 10, color: greyPdf)),
                    pw.SizedBox(width: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF10B981),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text('Approuvé',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            );
          }),
          pw.Spacer(),
          footer(totalPages, totalPages),
        ],
      ),
    ));
  }

  return doc.save();
}

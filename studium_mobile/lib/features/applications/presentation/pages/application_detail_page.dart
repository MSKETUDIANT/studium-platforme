import 'package:flutter/material.dart';

import '../../domain/entities/application.dart';

const _kNavy  = Color(0xFF1A1D2E);
const _kBlue  = Color(0xFF4880FF);
const _kGrey  = Color(0xFF9CA3AF);
const _kBg    = Color(0xFFF4F6FB);
const _kBorder = Color(0xFFE5E7EB);

class ApplicationDetailPage extends StatelessWidget {
  final Application app;
  const ApplicationDetailPage({super.key, required this.app});

  Color get _statusColor => switch (app.status) {
    ApplicationStatus.accepted        => const Color(0xFF10B981),
    ApplicationStatus.rejected        => const Color(0xFFEF4444),
    ApplicationStatus.needsFix        => const Color(0xFFF59E0B),
    ApplicationStatus.verified ||
    ApplicationStatus.sent            => _kBlue,
    ApplicationStatus.submitted ||
    ApplicationStatus.pendingDecision => const Color(0xFF6B7280),
    _                                 => const Color(0xFFD1D5DB),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Détail candidature',
            style: TextStyle(
                color: _kNavy,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgramCard(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildTimeline(),
            if (app.motivationText != null &&
                app.motivationText!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildMotivation(),
            ],
            if (app.notes != null && app.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildNotes(),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Programme card ─────────────────────────────────────────────────────────

  Widget _buildProgramCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.school_outlined, color: _kBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.programName ?? 'Programme',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kNavy),
                ),
                const SizedBox(height: 4),
                if (app.universityName != null)
                  Text(app.universityName!,
                      style: const TextStyle(fontSize: 14, color: _kGrey)),
                if (app.country != null) ...[
                  const SizedBox(height: 2),
                  Text(app.country!,
                      style: const TextStyle(fontSize: 13, color: _kGrey)),
                ],
                if (app.level != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status card ────────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 22),
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
                      color: _statusColor),
                ),
              ],
            ),
          ),
          if (app.submittedAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Soumise le',
                    style: TextStyle(fontSize: 11, color: _kGrey)),
                const SizedBox(height: 3),
                Text(
                  _formatDate(app.submittedAt!),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kNavy),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Timeline ───────────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    final steps = _buildTimelineSteps();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suivi',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kNavy)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i    = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return _TimelineRow(
              label:    step.label,
              subtitle: step.subtitle,
              done:     step.done,
              current:  step.current,
              isLast:   isLast,
              color:    step.done || step.current
                  ? (step.isNegative
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981))
                  : _kGrey,
            );
          }),
        ],
      ),
    );
  }

  List<_TimelineStep> _buildTimelineSteps() {
    final s = app.status;

    final submitted = s != ApplicationStatus.draft;
    final verified  = {
      ApplicationStatus.verified,
      ApplicationStatus.sent,
      ApplicationStatus.accepted,
      ApplicationStatus.rejected,
    }.contains(s);
    final sent     = {
      ApplicationStatus.sent,
      ApplicationStatus.accepted,
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
        label:    needsFix ? 'Correction requise' : 'En vérification',
        done:     verified || needsFix,
        current:  needsFix,
        isNegative: needsFix,
      ),
      _TimelineStep(
        label:    'Dossier envoyé',
        done:     sent,
        current:  s == ApplicationStatus.sent,
      ),
      _TimelineStep(
        label:    rejected
            ? 'Candidature refusée'
            : (accepted ? 'Candidature acceptée' : 'Résultat'),
        done:     accepted || rejected,
        current:  accepted || rejected,
        isNegative: rejected,
      ),
    ];
  }

  // ─── Motivation ─────────────────────────────────────────────────────────────

  Widget _buildMotivation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Message de motivation',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kNavy)),
          const SizedBox(height: 10),
          Text(
            app.motivationText!,
            style: const TextStyle(
                fontSize: 14, color: _kNavy, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ─── Notes admin ────────────────────────────────────────────────────────────

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.sticky_note_2_outlined,
                color: Color(0xFFD97706), size: 18),
            SizedBox(width: 8),
            Text('Note de l\'équipe',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E))),
          ]),
          const SizedBox(height: 10),
          Text(
            app.notes!,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF78350F),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

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

// ─── Timeline row ─────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool done;
  final bool current;
  final bool isLast;
  final Color color;
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
                  color: done || current ? color : _kBorder,
                  width: 2),
            ),
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : current
                    ? Center(
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
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
                  fontWeight:
                      current ? FontWeight.w700 : FontWeight.w500,
                  color: done || current ? _kNavy : _kGrey,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: _kGrey)),
              ],
              SizedBox(height: isLast ? 0 : 18),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

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

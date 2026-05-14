import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/application.dart';

const _kNavy   = Color(0xFF1A1D2E);
const _kBlue   = Color(0xFF4880FF);
const _kGrey   = Color(0xFF9CA3AF);
const _kBg     = Color(0xFFF4F6FB);
const _kBorder = Color(0xFFE5E7EB);

class ApplicationDetailPage extends StatelessWidget {
  final Application app;
  const ApplicationDetailPage({super.key, required this.app});

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

  @override
  Widget build(BuildContext context) {
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
                  _buildTimeline()
                      .animate()
                      .fadeIn(delay: 140.ms)
                      .slideY(begin: .06, duration: 280.ms, curve: Curves.easeOut),
                ]),
              ),
            ),
          ],
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

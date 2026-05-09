import 'package:flutter/material.dart';
import '../../domain/entities/program.dart';

const _kBlue   = Color(0xFF4880FF);
const _kBg     = Color(0xFFF4F6FB);
const _kText   = Color(0xFF1A1D2E);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);

class ProgramDetailPage extends StatelessWidget {
  final Program program;
  const ProgramDetailPage({super.key, required this.program});

  Color get _levelColor => switch (program.level) {
        'bachelor' => const Color(0xFF4880FF),
        'master'   => const Color(0xFF7C3AED),
        'phd'      => const Color(0xFF059669),
        _          => _kGrey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détail du programme',
          style: TextStyle(
              color: _kText, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Card ───────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (program.level != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: _levelColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        program.levelLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _levelColor,
                        ),
                      ),
                    ),
                  Text(
                    program.programName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_outlined,
                          size: 16, color: _kGrey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          program.universityName,
                          style: const TextStyle(
                              fontSize: 14,
                              color: _kGrey,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Infos rapides ─────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Informations générales'),
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
            ),
            const SizedBox(height: 16),

            // ─── Description ───────────────────────────────────────────
            if (program.description != null &&
                program.description!.trim().isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Description'),
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
              ),
              const SizedBox(height: 16),
            ],

            // ─── Exigences ─────────────────────────────────────────────
            if (program.requirements != null &&
                program.requirements!.isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Documents requis'),
                    const SizedBox(height: 12),
                    ...program.requirements!.map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 5, right: 10),
                              decoration: const BoxDecoration(
                                color: _kBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                req,
                                style: const TextStyle(
                                    fontSize: 14, color: _kText, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Contact ───────────────────────────────────────────────
            if (program.contactEmail != null &&
                program.contactEmail!.trim().isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Contact'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 16, color: _kGrey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            program.contactEmail!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _kBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Bouton candidater ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showComingSoon(context),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text(
                  'Soumettre une candidature',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.info_outline, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Candidatures disponibles prochainement'),
        ]),
        backgroundColor: _kBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/* ─── Widgets helpers ─────────────────────────────────────────────────────── */

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
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _kBlue,
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

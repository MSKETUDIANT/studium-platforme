import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/ambassador_providers.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/commission.dart';

class AmbassadorPage extends ConsumerWidget {
  const AmbassadorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code             = ref.watch(referralCodeProvider).valueOrNull;
    final referralsAsync   = ref.watch(myReferralsProvider);
    final commissionsAsync = ref.watch(myCommissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Parrainage', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(referralCodeProvider);
          ref.invalidate(myReferralsProvider);
          ref.invalidate(myCommissionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ReferralCodeCard(code: code),
            const SizedBox(height: 24),
            _SectionTitle('Filleuls'),
            const SizedBox(height: 10),
            referralsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.blue),
              )),
              error: (_, __) => const _ErrorText('Impossible de charger les filleuls.'),
              data: (referrals) => referrals.isEmpty
                  ? const _EmptyText("Aucun filleul pour l'instant. Partage ton lien pour commencer.")
                  : Column(children: referrals.map((r) => _ReferralTile(referral: r)).toList()),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Commissions'),
            const SizedBox(height: 10),
            commissionsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.blue),
              )),
              error: (_, __) => const _ErrorText('Impossible de charger les commissions.'),
              data: (commissions) => commissions.isEmpty
                  ? const _EmptyText('Aucune commission pour le moment.')
                  : Column(
                      children: commissions
                          .map((c) => _CommissionTile(
                                commission: c,
                                onRequestPayout: () async {
                                  await ref.read(myCommissionsProvider.notifier).requestPayout(c);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Demande envoyée à l\'équipe.')),
                                    );
                                  }
                                },
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  final String? code;
  const _ReferralCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ton code de parrainage',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(10)),
            child: Text(
              code ?? '—',
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Partage le lien ou communique le code : à l'inscription, il sera "
            "pré-rempli automatiquement via le lien, ou saisi manuellement avec le code.",
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text("Copier le lien d'invitation"),
              onPressed: code == null
                  ? null
                  : () async {
                      await Clipboard.setData(
                          ClipboardData(text: 'studium://register?ref=$code'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lien copié !')),
                        );
                      }
                    },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copier le code'),
              onPressed: code == null
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: code!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copié !')),
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary));
  }
}

class _ReferralTile extends StatelessWidget {
  final Referral referral;
  const _ReferralTile({required this.referral});

  Color get _statusColor => switch (referral.status) {
    ReferralStatus.converted  => AppColors.success,
    ReferralStatus.registered => AppColors.blue,
    ReferralStatus.clicked    => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              referral.studentName?.isNotEmpty == true ? referral.studentName! : 'Étudiant',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
            child: Text(referral.statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
          ),
        ],
      ),
    );
  }
}

class _CommissionTile extends StatelessWidget {
  final Commission commission;
  final VoidCallback onRequestPayout;
  const _CommissionTile({required this.commission, required this.onRequestPayout});

  Color get _statusColor => switch (commission.status) {
    CommissionStatus.paid    => AppColors.success,
    CommissionStatus.payable => AppColors.warning,
    CommissionStatus.pending => AppColors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final period = commission.periodStart;
    final periodLabel = period != null
        ? '${period.month.toString().padLeft(2, '0')}/${period.year}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(periodLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('${commission.amount}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
            child: Text(commission.statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
          ),
          if (commission.status == CommissionStatus.payable) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRequestPayout,
              child: const Text('Demander', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.danger), textAlign: TextAlign.center),
    );
  }
}

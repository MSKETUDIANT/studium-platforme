import '../../../../core/i18n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notifications_providers.dart';
import '../../domain/entities/app_notification.dart';

const _kNavy   = Color(0xFF1A1D2E);
const _kBlue   = Color(0xFF4880FF);
const _kBorder = Color(0xFFE5E7EB);
const _kGrey   = Color(0xFF9CA3AF);

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              pinned: true,
              backgroundColor: _kNavy,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              actions: [
                notifAsync.when(
                  data: (list) {
                    final hasUnread = list.any((n) => !n.isRead);
                    if (!hasUnread) return const SizedBox.shrink();
                    return TextButton(
                      onPressed: () =>
                          ref.read(notificationsProvider.notifier).markAllRead(),
                      child: Text(
                        context.s.markAllRead,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error:   (_, __) => const SizedBox.shrink(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                title: Text(
                  context.s.notifications,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                      colors: [Color(0xFF08122E), Color(0xFF153EA8)],
                    ),
                  ),
                ),
              ),
            ),
            notifAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _kBlue)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: _kGrey),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger les notifications',
                        style: TextStyle(color: _kGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyState());
                }

                // Grouper non lus / lus
                final unread = list.where((n) => !n.isRead).toList();
                final read   = list.where((n) =>  n.isRead).toList();

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (unread.isNotEmpty) ...[
                        _SectionHeader(
                          label: 'Non lues',
                          count: unread.length,
                          accent: _kBlue,
                        ),
                        const SizedBox(height: 8),
                        ...unread.asMap().entries.map((e) =>
                          _NotificationTile(
                            notif: e.value,
                            onTap: () {
                              ref.read(notificationsProvider.notifier)
                                  .markRead(e.value.id);
                              _navigate(context, e.value);
                            },
                          )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 40 * e.key), duration: 260.ms),
                        ),
                        if (read.isNotEmpty) const SizedBox(height: 20),
                      ],
                      if (read.isNotEmpty) ...[
                        _SectionHeader(
                          label: 'Lues',
                          count: read.length,
                          accent: _kGrey,
                        ),
                        const SizedBox(height: 8),
                        ...read.asMap().entries.map((e) =>
                          _NotificationTile(
                            notif: e.value,
                            onTap: () => _navigate(context, e.value),
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 40 * (unread.length + e.key)),
                            duration: 260.ms,
                          ),
                        ),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, AppNotification notif) {
    switch (notif.type) {
      case 'app_status':
        context.go('/applications');
      case 'doc_approved':
      case 'doc_rejected':
        context.go('/documents');
      case 'message_received':
        context.go('/messages');
      default:
        break;
    }
  }
}

// Section header

class _SectionHeader extends StatelessWidget {
  final String label;
  final int    count;
  final Color  accent;
  const _SectionHeader({required this.label, required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
        ),
      ),
    ]);
  }
}

// Tuile notification

class _NotificationTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback    onTap;
  const _NotificationTile({required this.notif, required this.onTap});

  _NotifMeta get _meta => switch (notif.type) {
    'app_status'       => _NotifMeta(
        icon:       Icons.update_rounded,
        iconColor:  _kBlue,
        label:      'Candidature',
        navHint:    'Voir mes candidatures',
        navIcon:    Icons.chevron_right_rounded,
      ),
    'doc_rejected'     => _NotifMeta(
        icon:       Icons.cancel_outlined,
        iconColor:  const Color(0xFFEF4444),
        label:      'Document',
        navHint:    'Voir mon dossier',
        navIcon:    Icons.chevron_right_rounded,
      ),
    'doc_approved'     => _NotifMeta(
        icon:       Icons.check_circle_outline_rounded,
        iconColor:  const Color(0xFF10B981),
        label:      'Document',
        navHint:    'Voir mon dossier',
        navIcon:    Icons.chevron_right_rounded,
      ),
    'message_received' => _NotifMeta(
        icon:       Icons.chat_bubble_outline_rounded,
        iconColor:  const Color(0xFF8B5CF6),
        label:      'Message',
        navHint:    'Ouvrir la conversation',
        navIcon:    Icons.chevron_right_rounded,
      ),
    'deadline'         => _NotifMeta(
        icon:       Icons.alarm_outlined,
        iconColor:  const Color(0xFFF59E0B),
        label:      'Echeance',
        navHint:    null,
        navIcon:    null,
      ),
    _                  => _NotifMeta(
        icon:       Icons.notifications_outlined,
        iconColor:  _kGrey,
        label:      'Notification',
        navHint:    null,
        navIcon:    null,
      ),
  };

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'A l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1)    return 'Hier';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread   = !notif.isRead;
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final cardColor  = Theme.of(context).colorScheme.surface;
    final meta       = _meta;
    final borderColor = isUnread
        ? meta.iconColor.withValues(alpha: 0.30)
        : (isDark ? const Color(0xFF1E2A52) : _kBorder);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isUnread
              ? meta.iconColor.withValues(alpha: 0.05)
              : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isUnread ? 1.5 : 1),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isUnread ? 0.06 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Corps principal
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icone
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: meta.iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(meta.icon, color: meta.iconColor, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge + dot non lu
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: meta.iconColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                meta.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: meta.iconColor,
                                  letterSpacing: .3,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isUnread)
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: meta.iconColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Titre
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : _kNavy,
                            height: 1.3,
                          ),
                        ),
                        // Corps complet
                        if (notif.body != null && notif.body!.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            notif.body!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF4B5563),
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Date
                        Text(
                          _formatDate(notif.createdAt),
                          style: const TextStyle(fontSize: 11, color: _kGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer navigation (uniquement si type navigable)
            if (meta.navHint != null)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF1E2A52)
                          : meta.iconColor.withValues(alpha: 0.10),
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(children: [
                    Text(
                      meta.navHint!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: meta.iconColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(meta.navIcon, size: 16, color: meta.iconColor),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Meta donnees par type

class _NotifMeta {
  final IconData  icon;
  final Color     iconColor;
  final String    label;
  final String?   navHint;
  final IconData? navIcon;
  const _NotifMeta({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.navHint,
    required this.navIcon,
  });
}

// Etat vide

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 40, color: _kBlue),
          )
          .animate()
          .scale(delay: 60.ms, duration: 320.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vous serez notifie des mises a jour\nde vos candidatures ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _kGrey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
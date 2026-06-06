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
                      onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
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
                child: Center(
                  child: CircularProgressIndicator(color: _kBlue),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: _kGrey),
                      const SizedBox(height: 12),
                      Text(
                        'Impossible de charger les notifications',
                        style: const TextStyle(color: _kGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    child: _EmptyState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _NotificationTile(
                        notif: list[i],
                        onTap: () => ref
                            .read(notificationsProvider.notifier)
                            .markRead(list[i].id),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 40 * i),
                            duration: 260.ms,
                          ),
                      childCount: list.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

//  Tuile notification 

class _NotificationTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback    onTap;
  const _NotificationTile({required this.notif, required this.onTap});

  IconData get _icon => switch (notif.type) {
    'status_change'     => Icons.update_rounded,
    'document_rejected' => Icons.cancel_outlined,
    'message'           => Icons.chat_bubble_outline_rounded,
    'deadline'          => Icons.alarm_outlined,
    _                   => Icons.notifications_outlined,
  };

  Color get _iconColor => switch (notif.type) {
    'status_change'     => _kBlue,
    'document_rejected' => const Color(0xFFEF4444),
    'message'           => const Color(0xFF10B981),
    'deadline'          => const Color(0xFFF59E0B),
    _                   => _kGrey,
  };

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1)    return 'Hier';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread  = !notif.isRead;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final borderColor = isUnread
        ? _kBlue.withValues(alpha: 0.25)
        : (isDark ? const Color(0xFF1E2A52) : _kBorder);
    return GestureDetector(
      onTap: () { if (isUnread) onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? _kBlue.withValues(alpha: 0.08) : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isUnread ? 1.5 : 1),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _kNavy,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: _kBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ]),
                  if (notif.body != null && notif.body!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notif.body!,
                      style: const TextStyle(fontSize: 13, color: _kGrey, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 5),
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
    );
  }
}

//  État vide 

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
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40, color: _kBlue,
            ),
          )
              .animate()
              .scale(delay: 60.ms, duration: 320.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            context.s.noNotifications,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.s.noNotificationsDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _kGrey, height: 1.5),
          ),
        ],
      ),
    );
  }
}

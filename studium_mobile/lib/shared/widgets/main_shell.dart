import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/strings.dart';
import '../../features/messaging/presentation/providers/messaging_providers.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

List<_NavItem> _navItems(AppStrings s) => [
  _NavItem(Icons.dashboard_outlined,          Icons.dashboard_rounded,       s.navHome),
  _NavItem(Icons.school_outlined,             Icons.school_rounded,          s.navPrograms),
  _NavItem(Icons.folder_outlined,             Icons.folder_rounded,          s.navDossiers),
  _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded,     s.navMessages),
  _NavItem(Icons.person_outline_rounded,      Icons.person_rounded,          s.navProfile),
];

const _kBlue     = Color(0xFF4880FF);
const _kInactive = Color(0xFFB0B7C3);

// Index de l'onglet Messages dans la barre de navigation
const _kMessagesIndex = 3;

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad  = MediaQuery.of(context).padding.bottom;
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final items      = _navItems(context.s);
    final barColor   = isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;
    final unreadMsgs = ref.watch(unreadStudentProvider).valueOrNull ?? 0;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPad > 0 ? bottomPad : 10),
        color: Colors.transparent,
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(26),
            border: isDark ? Border.all(color: const Color(0xFF1E2A52)) : null,
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28, spreadRadius: 0, offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == navigationShell.currentIndex;
              return Expanded(
                child: _NavButton(
                  item: items[i],
                  isActive: isActive,
                  badge: i == _kMessagesIndex ? unreadMsgs : 0,
                  onTap: () => _onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem     item;
  final bool         isActive;
  final int          badge;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 46, height: 30,
              decoration: BoxDecoration(
                color: isActive ? _kBlue.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        key: ValueKey(isActive),
                        size: 22,
                        color: isActive ? _kBlue : _kInactive,
                      ),
                    ),
                    if (badge > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 14),
                          height: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              badge > 99 ? '99+' : '$badge',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _kBlue : _kInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
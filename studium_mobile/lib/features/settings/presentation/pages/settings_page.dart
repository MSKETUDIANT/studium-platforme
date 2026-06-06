import '../../../../core/i18n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                        onTap: () => _exportData(context, s),
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

  void _exportData(BuildContext context, AppStrings s) => _showInfoDialog(context,
    title: s.exportTitle,
    body: s.exportBody,
  );

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

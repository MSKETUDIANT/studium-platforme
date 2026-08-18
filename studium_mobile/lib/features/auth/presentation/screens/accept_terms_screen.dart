import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

// Interstitiel de consentement RGPD affiché une seule fois, avant
// l'onboarding, pour tout compte dont le user_metadata ne porte pas
// encore `terms_accepted` — en pratique les comptes créés via Google ou
// Apple, qui ne passent pas par la case à cocher de l'écran d'inscription
// email/mot de passe (register_screen.dart).
class AcceptTermsScreen extends ConsumerStatefulWidget {
  const AcceptTermsScreen({super.key});

  @override
  ConsumerState<AcceptTermsScreen> createState() => _AcceptTermsScreenState();
}

class _AcceptTermsScreenState extends ConsumerState<AcceptTermsScreen> {
  bool _accepted = false;
  bool _saving   = false;

  Future<void> _continue() async {
    if (!_accepted || _saving) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'terms_accepted': true}),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    // Le redirect du router (app_router.dart) prend le relais vers
    // /onboarding ou /home selon l'état du compte.
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).signOut();
                  },
                  child: const Text('Se déconnecter',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Avant de continuer',
                  style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 10),
              const Text(
                'Pour utiliser Studium, merci de confirmer que vous acceptez '
                'nos conditions d\'utilisation et notre politique de '
                'confidentialité.',
                style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _accepted = !_accepted),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accepted
                        ? AppColors.blue.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _accepted
                          ? AppColors.blue.withValues(alpha: 0.35)
                          : AppColors.borderInput,
                    ),
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _accepted ? AppColors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _accepted
                              ? AppColors.blue
                              : AppColors.borderInput,
                          width: 1.5,
                        ),
                      ),
                      child: _accepted
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'J\'accepte les conditions d\'utilisation et la '
                        'politique de confidentialité',
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_accepted && !_saving) ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    disabledBackgroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Continuer',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool   _obscurePw      = true;
  bool   _emailTouched   = false;
  bool   _showResendBtn  = false;
  int    _failedAttempts = 0;
  int    _cooldownSecs   = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSecs = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldownSecs--;
        if (_cooldownSecs <= 0) {
          _cooldownSecs = 0;
          t.cancel();
        }
      });
    });
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Email ou mot de passe incorrect.';
    } else if (msg.contains('non autorisé') ||
               msg.contains('réservée aux étudiants')) {
      return 'Accès réservé aux étudiants et ambassadeurs.';
    } else if (msg.contains('Profil introuvable')) {
      return 'Compte non configuré. Contactez le support.';
    } else if (msg.contains('network') ||
               msg.contains('connection') ||
               msg.contains('SocketException')) {
      return 'Vérifiez votre connexion internet.';
    } else if (msg.contains('too_many_requests')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    } else if (msg.contains('email_not_confirmed')) {
      return 'Veuillez confirmer votre adresse email.';
    } else if (msg.contains('Google annulée')) {
      return 'Connexion Google annulée.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  void _showError(Object e) {
    final msg = e.toString();
    if (msg.contains('email_not_confirmed')) {
      setState(() => _showResendBtn = true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(_parseError(e))),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ✅ Renvoyer l'email de confirmation
  Future<void> _resendConfirmationEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Entrez votre email d'abord."),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (!mounted) return;
      setState(() => _showResendBtn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Email de confirmation renvoyé !')),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _signIn() async {
    if (_cooldownSecs > 0) return;
    setState(() {
      _emailTouched  = true;
      _showResendBtn = false;
    });
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    ref.read(authStateProvider).whenOrNull(
      data: (user) {
        if (user != null) {
          setState(() => _failedAttempts = 0);
          context.go('/home');
        }
      },
      error: (e, _) {
        _failedAttempts++;
        if (_failedAttempts >= 3) {
          _failedAttempts = 0;
          _startCooldown();
        }
        _showError(e);
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authStateProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    ref.read(authStateProvider).whenOrNull(
      data: (user) { if (user != null) context.go('/home'); },
      error: (e, _) => _showError(e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;
    final isWide    = MediaQuery.sizeOf(context).width > 700;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: isWide ? _WideLayout(buildForm: _buildForm(isLoading))
                   : _MobileLayout(buildForm: _buildForm(isLoading)),
    );
  }

  Widget _buildForm(bool isLoading) => _LoginForm(
    emailCtrl:       _emailCtrl,
    passwordCtrl:    _passwordCtrl,
    formKey:         _formKey,
    obscurePw:       _obscurePw,
    emailTouched:    _emailTouched,
    isLoading:       isLoading,
    showResendBtn:   _showResendBtn,
    cooldownSecs:    _cooldownSecs,
    onTogglePw:      () => setState(() => _obscurePw = !_obscurePw),
    onSignIn:        _signIn,
    onGoogleSignIn:  _signInWithGoogle,
    onResendEmail:   _resendConfirmationEmail,
  );
}

class _WideLayout extends StatelessWidget {
  final Widget buildForm;
  const _WideLayout({required this.buildForm});
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(flex: 4, child: _LeftPanel()),
    Expanded(flex: 5, child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: buildForm,
        ),
      ),
    )),
  ]);
}

class _MobileLayout extends StatelessWidget {
  final Widget buildForm;
  const _MobileLayout({required this.buildForm});
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final headerFlex = screenH < 700 ? 2 : 3;
    final formFlex   = screenH < 700 ? 8 : 7;
    return Column(children: [
      Expanded(flex: headerFlex, child: const _MobileHeader()),
      Expanded(flex: formFlex, child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: buildForm,
      )),
    ]);
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl, passwordCtrl;
  final GlobalKey<FormState> formKey;
  final bool obscurePw, emailTouched, isLoading, showResendBtn;
  final int cooldownSecs;
  final VoidCallback onTogglePw, onSignIn, onGoogleSignIn, onResendEmail;

  const _LoginForm({
    required this.emailCtrl, required this.passwordCtrl,
    required this.formKey, required this.obscurePw,
    required this.emailTouched, required this.isLoading,
    required this.showResendBtn,
    required this.cooldownSecs,
    required this.onTogglePw, required this.onSignIn,
    required this.onGoogleSignIn, required this.onResendEmail,
  });

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Connexion', style: Theme.of(context).textTheme.headlineLarge)
          .animate().fadeIn(duration: 400.ms).slideY(begin: 0.25, end: 0),
        const SizedBox(height: 6),
        Text(
          'Connectez-vous pour continuer votre parcours',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ).animate().fadeIn(duration: 400.ms, delay: 60.ms).slideY(begin: 0.25, end: 0),
        const SizedBox(height: 20),

        const _FieldLabel('Adresse email'),
        const SizedBox(height: 6),
        TextFormField(
          controller:      emailCtrl,
          keyboardType:    TextInputType.emailAddress,
          autocorrect:     false,
          textInputAction: TextInputAction.next,
          style:           const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText:    'prenom@email.com',
            prefixIcon:  Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
          ),
          validator: (v) {
            if (!emailTouched) return null;
            if (v == null || v.isEmpty) return 'Ce champ est requis';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return "Format d'email invalide";
            return null;
          },
          onChanged: (_) { if (emailTouched) formKey.currentState?.validate(); },
        ).animate().fadeIn(duration: 400.ms, delay: 120.ms).slideY(begin: 0.25, end: 0),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _FieldLabel('Mot de passe'),
            GestureDetector(
              onTap: () => context.go('/forgot-password'),
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(fontSize: 12.5, color: AppColors.blue, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller:      passwordCtrl,
          obscureText:     obscurePw,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => isLoading ? null : onSignIn(),
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outlined, color: AppColors.textMuted, size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePw ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textMuted, size: 20,
              ),
              onPressed: onTogglePw,
              tooltip: obscurePw ? 'Afficher' : 'Masquer',
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
        ).animate().fadeIn(duration: 400.ms, delay: 180.ms).slideY(begin: 0.25, end: 0),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: (isLoading || cooldownSecs > 0) ? null : onSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: cooldownSecs > 0 ? AppColors.textMuted : AppColors.navy,
            foregroundColor: Colors.white,
            elevation:       (isLoading || cooldownSecs > 0) ? 0 : 2,
            shadowColor:     AppColors.navy.withValues(alpha: 0.3),
          ),
          child: isLoading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : cooldownSecs > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Réessayer dans ${cooldownSecs}s',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Se connecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ).animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.25, end: 0),

        // ✅ Bouton renvoyer email — visible uniquement après erreur email_not_confirmed
        if (showResendBtn) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onResendEmail,
            icon: const Icon(Icons.mark_email_unread_outlined, size: 18),
            label: const Text(
              "Renvoyer l'email de confirmation",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue,
              side: const BorderSide(color: AppColors.blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
        ],

        const SizedBox(height: 18),

        Row(children: [
          const Expanded(child: Divider(color: AppColors.borderInput)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('ou', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const Expanded(child: Divider(color: AppColors.borderInput)),
        ]),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onGoogleSignIn,
            icon: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
              child: const Center(
                child: Text('G', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
              ),
            ),
            label: const Text('Continuer avec Google',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderInput),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 280.ms).slideY(begin: 0.25, end: 0),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nouveau sur Studium ? ',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: const Text('Créer un compte',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.blue)),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        const SizedBox(height: 24),
        const Center(child: Text('© 2025 Studium Platform',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
      letterSpacing: 0.10, color: AppColors.textSecondary),
  );
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel();
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.navy,
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      Positioned(top: -80, right: -80, child: _Orb(size: 320, opacity: 0.22)),
      Positioned(bottom: -40, left: -60, child: _Orb(size: 220, opacity: 0.14)),
      SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 52),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset('assets/images/stlogo.png', width: 170, color: Colors.white)
            .animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 28),
          Container(width: 36, height: 2, color: Colors.white24)
            .animate().fadeIn(duration: 600.ms, delay: 100.ms),
          const SizedBox(height: 28),
          Text.rich(TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xB3FFFFFF), height: 1.85),
            children: [
              const TextSpan(text: 'Espace réservé à '),
              const TextSpan(text: "l'équipe Studium",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const TextSpan(text: ' — gestion et suivi\ndes dossiers académiques internationaux.'),
            ],
          ), textAlign: TextAlign.center).animate().fadeIn(duration: 600.ms, delay: 180.ms),
        ]),
      )),
    ]),
  );
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.navy,
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      Positioned(top: -40, right: -40, child: _Orb(size: 180, opacity: 0.18)),
      SafeArea(bottom: false, child: Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Image.asset('assets/images/stlogo.png', width: 110, color: Colors.white)
            .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0)),
          const SizedBox(height: 8),
          Container(width: 28, height: 2, color: Colors.white24),
        ]),
      ))),
    ]),
  );
}

class _Orb extends StatelessWidget {
  final double size, opacity;
  const _Orb({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [
        const Color(0xFF4880FF).withValues(alpha: opacity),
        Colors.transparent,
      ]),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.035)..strokeWidth = 1;
    const s = 52.0;
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
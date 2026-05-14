import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscurePw      = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms  = false;
  int  _pwStrength     = 0;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_updateStrength);
  }

  void _updateStrength() {
    final pw = _passwordCtrl.text;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#$%^&*()\-_=+,.?":{}|<>]'))) score++;
    setState(() => _pwStrength = score);
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_updateStrength);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('already registered') ||
        msg.contains('already_exists') ||
        msg.contains('User already registered')) {
      return 'Cet email est déjà utilisé.';
    } else if (msg.contains('weak_password')) {
      return 'Mot de passe trop faible. Minimum 8 caractères.';
    } else if (msg.contains('invalid_email') || msg.contains('Invalid email')) {
      return 'Adresse email invalide.';
    } else if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Vérifiez votre connexion internet.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(_parseError(e))),
      ]),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_unread_outlined,
                color: AppColors.blue, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Confirmez votre email',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(
            'Un lien de confirmation a été envoyé à :\n${_emailCtrl.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cliquez sur le lien pour activer votre compte.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _GradientButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
              child: const Text('Aller à la connexion',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.warning_outlined, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Acceptez les conditions d\'utilisation'),
        ]),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      ref.read(authStateProvider).when(
        data: (_) => _showConfirmationDialog(),
        error: (e, _) => _showError(e),
        loading: () {},
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
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
    final screenH   = MediaQuery.sizeOf(context).height;
    final headerFlex = screenH < 700 ? 2 : 3;
    final formFlex   = screenH < 700 ? 8 : 7;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(children: [
        Expanded(flex: headerFlex, child: const _BrandedHeader()),
        Expanded(flex: formFlex, child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text('Créer un compte',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary))
                  .animate().fadeIn(duration: 400.ms).slideY(begin: 0.25, end: 0),
                const SizedBox(height: 4),
                const Text('Rejoignez Studium pour gérer vos candidatures',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary))
                  .animate().fadeIn(duration: 400.ms, delay: 60.ms).slideY(begin: 0.25, end: 0),
                const SizedBox(height: 20),

                // Email
                _FieldLabel('Adresse email'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'prenom@email.com',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.textMuted, size: 20),
                    prefixIconConstraints: const BoxConstraints(minWidth: 48),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Format d\'email invalide';
                    }
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.25, end: 0),
                const SizedBox(height: 14),

                // Mot de passe
                _FieldLabel('Mot de passe'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePw,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outlined,
                        color: AppColors.textMuted, size: 20),
                    prefixIconConstraints: const BoxConstraints(minWidth: 48),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePw
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textMuted, size: 20),
                      onPressed: () =>
                          setState(() => _obscurePw = !_obscurePw),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 140.ms).slideY(begin: 0.25, end: 0),
                if (_pwStrength > 0) ...[
                  const SizedBox(height: 8),
                  _PasswordStrengthBar(strength: _pwStrength),
                ],
                const SizedBox(height: 14),

                // Confirmer mot de passe
                _FieldLabel('Confirmer le mot de passe'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signUp(),
                  style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outlined,
                        color: AppColors.textMuted, size: 20),
                    prefixIconConstraints: const BoxConstraints(minWidth: 48),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textMuted, size: 20),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 180.ms).slideY(begin: 0.25, end: 0),
                const SizedBox(height: 16),

                // Terms checkbox
                GestureDetector(
                  onTap: () =>
                      setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _acceptedTerms
                          ? AppColors.blue.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _acceptedTerms
                            ? AppColors.blue.withValues(alpha: 0.35)
                            : AppColors.borderInput,
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: _acceptedTerms
                              ? AppColors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _acceptedTerms
                                ? AppColors.blue
                                : AppColors.borderInput,
                            width: 1.5,
                          ),
                        ),
                        child: _acceptedTerms
                            ? const Icon(Icons.check, size: 13,
                                color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ]),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                const SizedBox(height: 20),

                // Bouton S'inscrire
                _GradientButton(
                  onPressed: isLoading ? null : _signUp,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('S\'inscrire',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                size: 18, color: Colors.white),
                          ],
                        ),
                ).animate().fadeIn(duration: 400.ms, delay: 220.ms).slideY(begin: 0.25, end: 0),
                const SizedBox(height: 18),

                // Divider
                Row(children: [
                  const Expanded(child: Divider(color: AppColors.borderInput)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderInput)),
                ]),
                const SizedBox(height: 16),

                // Google button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderInput),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isLoading ? null : _signInWithGoogle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F3FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text('G',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  )),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Continuer avec Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 260.ms).slideY(begin: 0.25, end: 0),
                const SizedBox(height: 16),

                // Déjà un compte
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Déjà un compte ? ',
                      style: TextStyle(
                          fontSize: 13.5, color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Se connecter',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue)),
                  ),
                ]).animate().fadeIn(duration: 400.ms, delay: 280.ms),

                const SizedBox(height: 20),
                const Center(
                  child: Text('© 2025 Studium Platform',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        )),
      ]),
    );
  }
}

/* ─── Widgets internes ───────────────────────────────────────────────────── */

class _BrandedHeader extends StatelessWidget {
  const _BrandedHeader();

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _BottomWaveClipper(),
    child: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF162270)],
        ),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        Positioned(top: -40, right: -40, child: _Orb(size: 200, opacity: 0.20)),
        Positioned(bottom: 20, left: -30, child: _Orb(size: 120, opacity: 0.12)),
        SafeArea(bottom: false, child: Center(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Image.asset('assets/images/stlogo.png',
                  width: 120, color: Colors.white)
                .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
            ),
            const SizedBox(height: 10),
            Container(
              width: 32, height: 2,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Étudiez sans frontières',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white54,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          ]),
        ))),
      ]),
    ),
  );
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _GradientButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : const LinearGradient(
                colors: [AppColors.navyLight, AppColors.blue],
              ),
        color: disabled ? AppColors.textMuted : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.10,
      color: AppColors.textSecondary,
    ),
  );
}

class _PasswordStrengthBar extends StatelessWidget {
  final int strength;
  const _PasswordStrengthBar({required this.strength});

  static const _labels = ['Faible', 'Acceptable', 'Fort', 'Très fort'];
  static const _colors = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    final idx   = (strength - 1).clamp(0, 3);
    final color = _colors[idx];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < strength ? color : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text(
          _labels[idx],
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 28)
      ..quadraticBezierTo(
        size.width / 2, size.height + 28,
        size.width, size.height - 28,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
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
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
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
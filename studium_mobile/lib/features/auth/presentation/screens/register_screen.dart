import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey        = GlobalKey<FormState>();
  bool _obscurePassword   = true;
  bool _acceptedTerms     = false;
  int  _passwordStrength  = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrength);
  }

  void _updateStrength() {
    final pw = _passwordController.text;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#$%^&*()\-_=+,.?":{}|<>]'))) score++;
    setState(() => _passwordStrength = score);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updateStrength);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _parseError(Object e) {
    final msg = e.toString();
    debugPrint('=== REGISTER ERROR: $msg'); // debug
    if (msg.contains('already registered') ||
        msg.contains('already_exists') ||
        msg.contains('déjà utilisé') ||
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
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showEmailConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.mark_email_unread_outlined, color: Colors.blue, size: 28),
          SizedBox(width: 12),
          Expanded(child: Text('Confirmez votre email', style: TextStyle(fontSize: 18))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Un email de confirmation a été envoyé à :\n${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Cliquez sur le lien dans l\'email pour activer votre compte, puis connectez-vous.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Aller à la connexion'),
          ),
        ],
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
          Text('Veuillez accepter les conditions d\'utilisation'),
        ]),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      // ✅ Vérifier l'état après inscription
      final state = ref.read(authStateProvider);
      state.when(
        data: (_) {
          // ✅ Inscription réussie (avec ou sans session) → dialog confirmation
          _showEmailConfirmationDialog();
        },
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
    final state = ref.read(authStateProvider);
    state.whenOrNull(
      data: (user) { if (user != null) context.go('/home'); },
      error: (e, _) => _showError(e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Créer un compte',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Rejoignez Studium pour gérer vos candidatures',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Mot de passe requis';
                      if (v.length < 8) return 'Minimum 8 caractères';
                      return null;
                    },
                  ),
                  if (_passwordStrength > 0) ...[
                    const SizedBox(height: 8),
                    _PasswordStrengthBar(strength: _passwordStrength),
                  ],
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                        child: const Text(
                          'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('S\'inscrire'),
                  ),
                  const SizedBox(height: 16),

                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithGoogle,
                      icon: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
                        child: const Center(
                          child: Text('G', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
                        ),
                      ),
                      label: const Text('Continuer avec Google', style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Déjà un compte ?'),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final int strength; // 1–4

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
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
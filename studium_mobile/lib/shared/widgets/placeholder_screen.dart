import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

/* ─── SplashScreen ───────────────────────────────────────────────────────── */
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); _checkAuth(); }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    context.go(session != null ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1A3C6E),
    body: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      Positioned(top: -80,  right: -80, child: _Orb(size: 300, opacity: 0.20)),
      Positioned(bottom: -60, left: -80, child: _Orb(size: 240, opacity: 0.14)),
      SafeArea(child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/stlogo.png', width: 200,
            color: Colors.white, colorBlendMode: BlendMode.srcIn)
            .animate().fadeIn(duration: 700.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Container(width: 36, height: 2,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2)))
            .animate().fadeIn(duration: 500.ms, delay: 400.ms),
          const SizedBox(height: 48),
          SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.6))))
            .animate().fadeIn(duration: 400.ms, delay: 800.ms),
        ],
      ))),
    ]),
  );
}

/* ─── Stubs — à remplacer par feature ───────────────────────────────────── */

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
    title: 'Candidatures',
    icon: Icons.folder_open_outlined,
    color: Color(0xFFF59E0B),
  );
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
    title: 'Messages',
    icon: Icons.chat_bubble_outline,
    color: Color(0xFF10B981),
  );
}

/* ─── Placeholder générique ──────────────────────────────────────────────── */

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _PlaceholderPage({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FB),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1A1D2E),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 38, color: color),
          )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D2E),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 8),
          const Text(
            'Cette section arrive bientôt',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction_outlined, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  'En cours de développement',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    ),
  );
}

/* ─── Helpers ────────────────────────────────────────────────────────────── */

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
      ..color = Colors.white.withValues(alpha: 0.03)
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
import '../../../../core/i18n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../providers/messaging_providers.dart';

//  Palette (identique aux autres pages) 
const _kNavy   = Color(0xFF08122E);
const _kAccent = Color(0xFF4880FF);
const _kText   = Color(0xFF1A1D2E);
const _kMuted  = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);

//  MessagesPage 
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});
  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool  _sending    = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();
    _controller.clear();
    setState(() => _sending = true);
    await ref.read(messagesProvider.notifier).send(text);
    setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider);
    messagesAsync.whenData((_) => _scrollToBottom());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              //  Header gradient 
              _Header().animate().fadeIn(duration: 400.ms).slideY(begin: -0.06),

              //  Messages 
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
                  ),
                  error: (e, _) => _ErrorState(
                    error:   e.toString(),
                    onRetry: () => ref.invalidate(messagesProvider),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) return const _EmptyState();
                    return ListView.builder(
                      controller:  _scrollCtrl,
                      padding:     const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount:   messages.length,
                      itemBuilder: (_, i) {
                        final msg    = messages[i];
                        final sameNext = i + 1 < messages.length &&
                            messages[i + 1].senderType == msg.senderType;
                        return _MessageBubble(
                          message:  msg,
                          isLast:   !sameNext,
                          showTime: !sameNext || i == messages.length - 1,
                        ).animate().fadeIn(
                          delay:    Duration(milliseconds: i < 15 ? i * 30 : 0),
                          duration: 200.ms,
                        );
                      },
                    );
                  },
                ),
              ),

              //  Zone de saisie 
              _ReplyBox(
                controller: _controller,
                sending:    _sending,
                onSend:     _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  Header 
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF08122E), Color(0xFF153EA8), Color(0xFF1A67D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Row(
            children: [
              // Avatar équipe
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.s.studiumTeam,
                      style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800,
                        fontSize: 17, letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.4), blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.s.online,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kAccent.withValues(alpha: 0.12), const Color(0xFF7C3AED).withValues(alpha: 0.10)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: _kAccent, size: 34),
            ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
            const SizedBox(height: 20),
            Text(
              context.s.noConversation,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _kText),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              context.s.noConversationDesc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _kMuted, height: 1.5),
            ).animate().fadeIn(delay: 150.ms),
          ],
        ),
      ),
    );
  }
}

//  État erreur 
class _ErrorState extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kText),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
              ),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: AppColors.danger, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ' Si l\'erreur mentionne "relation does not exist",\napplique les migrations SQL dans Supabase.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _kMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kNavy, Color(0xFF153EA8)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Réessayer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Bulle de message 
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isLast;
  final bool showTime;

  const _MessageBubble({
    required this.message,
    required this.isLast,
    required this.showTime,
  });

  @override
  Widget build(BuildContext context) {
    final isStudent = !message.isStaff;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 14 : 3),
      child: Column(
        crossAxisAlignment: isStudent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isStudent ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar staff
              if (!isStudent) ...[
                if (isLast)
                  Container(
                    width: 30, height: 30,
                    margin: const EdgeInsets.only(right: 8, bottom: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kAccent, Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 15),
                  )
                else
                  const SizedBox(width: 38),
              ],

              // Bulle
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isStudent
                        ? const LinearGradient(
                            colors: [_kAccent, Color(0xFF1E40AF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isStudent ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(!isStudent && isLast ? 4 : 16),
                      bottomRight: Radius.circular(isStudent && isLast ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isStudent ? _kAccent : Colors.black).withValues(alpha: 0.10),
                        blurRadius: 8, offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14.5,
                      color:    isStudent ? Colors.white : _kText,
                      height:   1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (showTime)
            Padding(
              padding: EdgeInsets.only(top: 4, left: isStudent ? 0 : 38),
              child: Text(
                _fmtTime(message.createdAt),
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
            ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays    == 1) return 'Hier ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

//  Zone de saisie 
class _ReplyBox extends StatelessWidget {
  final TextEditingController controller;
  final bool         sending;
  final VoidCallback onSend;
  const _ReplyBox({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1121) : const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? const Color(0xFF1E2A52) : _kBorder),
              ),
              child: TextField(
                controller:      controller,
                maxLines:        null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 14.5, color: _kText),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  hintText:  context.s.writeMessage,
                  hintStyle: TextStyle(color: _kMuted, fontSize: 14.5),
                  border:    InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: sending
                    ? null
                    : const LinearGradient(
                        colors: [_kAccent, Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color:        sending ? _kBorder : null,
                borderRadius: BorderRadius.circular(23),
                boxShadow: sending ? [] : [
                  BoxShadow(color: _kAccent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

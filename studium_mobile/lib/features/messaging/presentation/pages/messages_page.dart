import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../providers/messaging_providers.dart';

const _kNavy = Color(0xFF1A1D2E);
const _kBlue = Color(0xFF4880FF);
const _kBg   = Color(0xFFF4F6FB);

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool  _sending     = false;

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

    // Scroll auto à chaque nouveau message
    messagesAsync.whenData((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withValues(alpha: 0.08), height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── En-tête équipe ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kBlue, Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Équipe Studium',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kNavy),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'En ligne',
                          style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderInput),

          // ── Messages ──
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
                    const SizedBox(height: 8),
                    Text('Erreur de chargement', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: _kBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: _kBlue, size: 32),
                        ).animate().fadeIn().scale(),
                        const SizedBox(height: 16),
                        const Text(
                          'Commencez la conversation',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kNavy),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 6),
                        const Text(
                          'Posez vos questions à l\'équipe Studium',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg    = messages[i];
                    final isNext = i + 1 < messages.length && messages[i + 1].senderType == msg.senderType;
                    return _MessageBubble(
                      message:   msg,
                      isLast:    !isNext,
                      showTime:  !isNext || i == messages.length - 1,
                    );
                  },
                );
              },
            ),
          ),

          // ── Zone de saisie ──
          _ReplyBox(
            controller: _controller,
            sending:    _sending,
            onSend:     _send,
          ),
        ],
      ),
    );
  }
}

/* ─── Bulle de message ──────────────────────────────────────────────────────── */
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
    final time = _fmtTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 12 : 3),
      child: Column(
        crossAxisAlignment:
            isStudent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isStudent ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar staff
              if (!isStudent && isLast) ...[
                Container(
                  width: 28, height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kBlue, Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 14),
                ),
              ] else if (!isStudent) ...[
                const SizedBox(width: 36),
              ],

              // Bulle
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isStudent ? _kBlue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isStudent ? 16 : (isLast ? 4 : 16)),
                      bottomRight: Radius.circular(isStudent ? (isLast ? 4 : 16) : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color:    isStudent ? Colors.white : _kNavy,
                      height:   1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Horodatage
          if (showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isStudent ? 0 : 36,
                right: 0,
              ),
              child: Text(
                time,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  String _fmtTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inHours < 1)    return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1)     return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    if (diff.inDays == 1)    return 'Hier ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}';
  }
}

/* ─── Zone de saisie ────────────────────────────────────────────────────────── */
class _ReplyBox extends StatelessWidget {
  final TextEditingController controller;
  final bool         sending;
  final VoidCallback onSend;

  const _ReplyBox({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve:    Curves.easeOut,
      padding:  EdgeInsets.only(bottom: bottom),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderInput),
                  ),
                  child: TextField(
                    controller:    controller,
                    maxLines:      null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 14, color: _kNavy),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      hintText:    'Écrivez un message…',
                      hintStyle:   TextStyle(color: AppColors.textMuted, fontSize: 14),
                      border:      InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: sending ? null : onSend,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: sending
                        ? null
                        : const LinearGradient(
                            colors: [_kBlue, Color(0xFF1E40AF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color:        sending ? AppColors.borderInput : null,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/document.dart';
import '../providers/document_providers.dart';

const _kBlue = Color(0xFF4880FF);
const _kGrey = Color(0xFF9CA3AF);

// Etat par type de document
class _TypeState {
  final String? fileName;
  final String? filePath; // conservé pour permettre un retry sans re-sélection
  final bool    uploading;
  final bool    done;
  final String? error;
  final double  progress; // 0..1, valide seulement si uploading == true

  const _TypeState({
    this.fileName,
    this.filePath,
    this.uploading = false,
    this.done      = false,
    this.error,
    this.progress  = 0,
  });
}

class UploadDocumentPage extends ConsumerStatefulWidget {
  const UploadDocumentPage({super.key});

  @override
  ConsumerState<UploadDocumentPage> createState() =>
      _UploadDocumentPageState();
}

class _UploadDocumentPageState
    extends ConsumerState<UploadDocumentPage> {
  final Map<DocumentType, _TypeState> _states = {
    for (final t in DocumentType.values) t: const _TypeState(),
  };

  bool get _anyDone => _states.values.any((s) => s.done);

  Future<void> _onTapType(DocumentType type) async {
    final s = _states[type]!;
    if (s.uploading) return;

    String filePath;
    String fileName;

    // Après un échec, on relance directement le même fichier déjà
    // sélectionné (reprise) au lieu de rouvrir le sélecteur de fichiers.
    if (s.error != null && s.filePath != null && s.fileName != null) {
      filePath = s.filePath!;
      fileName = s.fileName!;
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );
      if (result == null || result.files.single.path == null) return;
      filePath = result.files.single.path!;
      fileName = result.files.single.name;
    }

    setState(() {
      _states[type] = _TypeState(
        fileName:  fileName,
        filePath:  filePath,
        uploading: true,
      );
    });

    try {
      await ref.read(documentsProvider.notifier).upload(
        type:     type,
        filePath: filePath,
        onProgress: (sent, total) {
          if (!mounted) return;
          setState(() {
            _states[type] = _TypeState(
              fileName:  fileName,
              filePath:  filePath,
              uploading: true,
              progress:  total > 0 ? sent / total : 0,
            );
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _states[type] = _TypeState(
          fileName: fileName,
          done:     true,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _states[type] = _TypeState(
          fileName: fileName,
          filePath: filePath,
          error:    e.toString(),
        );
      });
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior:        SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation:       0,
        margin:          const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:         const Color(0xFFEF4444),
            borderRadius:  BorderRadius.circular(16),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Erreur : $msg',
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(children: [
          _Header(onBack: () => Navigator.pop(context)),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instruction
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _kBlue.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.touch_app_outlined,
                            size: 18, color: _kBlue),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Appuyez sur un type de document pour\nselectionner et uploader directement.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _kBlue,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ]),
                    )
                    .animate().fadeIn(delay: 60.ms).slideY(begin: .04),
                    const SizedBox(height: 20),

                    // Liste des types
                    ...DocumentType.values.asMap().entries.map((entry) {
                      final i    = entry.key;
                      final type = entry.value;
                      return _TypeRow(
                        type:    type,
                        state:   _states[type]!,
                        onTap:   () => _onTapType(type),
                      )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 80 + i * 50))
                      .slideY(begin: .04, duration: 260.ms, curve: Curves.easeOut);
                    }),

                    const SizedBox(height: 24),

                    // Bouton fermer (visible si au moins 1 upload fait)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _anyDone
                          ? _DoneButton(onTap: () => Navigator.pop(context))
                              .animate().fadeIn().slideY(begin: .06)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// Header gradient

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF08122E), Color(0xFF153EA8), Color(0xFF1A67D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(right: -20, top: -20,
                child: _DecorCircle(size: 100, opacity: 0.07)),
            Positioned(right: 40, bottom: -10,
                child: _DecorCircle(size: 60, opacity: 0.05)),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 18),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouveau document',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Uploader un fichier',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ]).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05),
            ),
          ],
        ),
      ),
    );
  }
}

// Ligne par type de document

class _TypeRow extends StatelessWidget {
  final DocumentType type;
  final _TypeState   state;
  final VoidCallback onTap;
  const _TypeRow({
    required this.type,
    required this.state,
    required this.onTap,
  });

  Color get _color => switch (type) {
    DocumentType.cv               => _kBlue,
    DocumentType.transcript       => const Color(0xFF8B5CF6),
    DocumentType.recommendation   => const Color(0xFF10B981),
    DocumentType.passport         => const Color(0xFFF59E0B),
    DocumentType.motivationLetter => const Color(0xFFEC4899),
    DocumentType.diploma          => const Color(0xFF0891B2),
    DocumentType.languageCert     => const Color(0xFF7C3AED),
    DocumentType.financialProof   => const Color(0xFF059669),
    DocumentType.other            => const Color(0xFF6B7280),
  };

  IconData get _icon => switch (type) {
    DocumentType.cv               => Icons.description_outlined,
    DocumentType.transcript       => Icons.school_outlined,
    DocumentType.recommendation   => Icons.recommend_outlined,
    DocumentType.passport         => Icons.badge_outlined,
    DocumentType.motivationLetter => Icons.edit_note_outlined,
    DocumentType.diploma          => Icons.workspace_premium_outlined,
    DocumentType.languageCert     => Icons.translate_outlined,
    DocumentType.financialProof   => Icons.account_balance_outlined,
    DocumentType.other            => Icons.attach_file_outlined,
  };

  String get _label => switch (type) {
    DocumentType.cv               => 'CV',
    DocumentType.transcript       => 'Releve de notes',
    DocumentType.recommendation   => 'Lettre de recommandation',
    DocumentType.passport         => 'Passeport',
    DocumentType.motivationLetter => 'Lettre de motivation',
    DocumentType.diploma          => 'Diplome',
    DocumentType.languageCert     => 'Attestation de langue',
    DocumentType.financialProof   => 'Justificatif de financement',
    DocumentType.other            => 'Autre',
  };

  @override
  Widget build(BuildContext context) {
    final isDone      = state.done;
    final isUploading = state.uploading;
    final hasError    = state.error != null;
    final color       = isDone
        ? const Color(0xFF10B981)
        : hasError
            ? const Color(0xFFEF4444)
            : _color;

    return GestureDetector(
      onTap: (isUploading || isDone) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.06)
              : hasError
                  ? const Color(0xFFEF4444).withValues(alpha: 0.05)
                  : isUploading
                      ? color.withValues(alpha: 0.05)
                      : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                : hasError
                    ? const Color(0xFFEF4444).withValues(alpha: 0.30)
                    : isUploading
                        ? color.withValues(alpha: 0.30)
                        : const Color(0xFFE5E7EB),
            width: (isDone || isUploading || hasError) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDone ? 0.05 : 0.03),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Icone type
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDone ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Color(0xFF10B981), size: 22)
                    : Icon(_icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              // Label + sous-titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDone
                            ? const Color(0xFF10B981)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (state.fileName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        state.fileName!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDone ? const Color(0xFF10B981) : _kGrey,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Etat a droite
              if (isUploading)
                Text(
                  '${(state.progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
                )
              else if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Uploade',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                )
              else if (hasError)
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Reessayer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: color),
                ),
            ]),
            // Barre de progression pendant l'upload
            if (isUploading) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress > 0 ? state.progress : null,
                  backgroundColor: color.withValues(alpha: 0.12),
                  color: color,
                  minHeight: 3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Bouton "Terminer"

class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.28),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Terminer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Shared

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Container(
      width: size, height: size,
      decoration: const BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
      ),
    ),
  );
}
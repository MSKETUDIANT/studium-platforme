import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/document.dart';
import '../providers/document_providers.dart';

const _kNavy  = Color(0xFF1A1D2E);
const _kBlue  = Color(0xFF4880FF);
const _kGrey  = Color(0xFF9CA3AF);
const _kBg    = Color(0xFFF4F6FB);

class UploadDocumentPage extends ConsumerStatefulWidget {
  const UploadDocumentPage({super.key});

  @override
  ConsumerState<UploadDocumentPage> createState() =>
      _UploadDocumentPageState();
}

class _UploadDocumentPageState extends ConsumerState<UploadDocumentPage> {
  DocumentType _selectedType = DocumentType.cv;
  String? _filePath;
  String? _fileName;
  bool _loading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(children: [
              Icon(Icons.warning_outlined, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Veuillez selectionner un fichier',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(documentsProvider.notifier).upload(
            type: _selectedType,
            filePath: _filePath!,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Erreur : $e',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = _filePath != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(children: [
          _buildHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Type de document')
                        .animate().fadeIn(delay: 60.ms).slideY(begin: .04),
                    const SizedBox(height: 12),
                    _TypeGrid(
                      selected: _selectedType,
                      onSelect: (t) => setState(() => _selectedType = t),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: .04),
                    const SizedBox(height: 28),
                    const _SectionLabel('Fichier')
                        .animate().fadeIn(delay: 140.ms).slideY(begin: .04),
                    const SizedBox(height: 12),
                    _FilePicker(
                      fileName: _fileName,
                      onPick: _pickFile,
                    ).animate().fadeIn(delay: 180.ms).slideY(begin: .04),
                    const SizedBox(height: 32),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: canUpload
                            ? const LinearGradient(
                                colors: [Color(0xFF4880FF), Color(0xFF2563EB)])
                            : null,
                        color: canUpload ? null : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canUpload
                            ? [
                                BoxShadow(
                                  color: _kBlue.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canUpload && !_loading ? _upload : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: _loading
                                ? const Center(
                                    child: SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          size: 18,
                                          color: canUpload
                                              ? Colors.white
                                              : _kGrey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Enregistrer le document',
                                        style: TextStyle(
                                          color: canUpload
                                              ? Colors.white
                                              : _kGrey,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 220.ms).slideY(begin: .04),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1F42), Color(0xFF1565C0), Color(0xFF1E5298)],
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
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
                ],
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(
          color: _kBlue, borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kNavy)),
    ]);
  }
}

// ─── Type Grid ─────────────────────────────────────────────────────────────────

class _TypeGrid extends StatelessWidget {
  final DocumentType selected;
  final ValueChanged<DocumentType> onSelect;
  const _TypeGrid({required this.selected, required this.onSelect});

  Color _colorFor(DocumentType t) => switch (t) {
    DocumentType.cv             => _kBlue,
    DocumentType.transcript     => const Color(0xFF8B5CF6),
    DocumentType.recommendation => const Color(0xFF10B981),
    DocumentType.passport       => const Color(0xFFF59E0B),
    DocumentType.other          => const Color(0xFF6B7280),
  };

  IconData _iconFor(DocumentType t) => switch (t) {
    DocumentType.cv             => Icons.description_outlined,
    DocumentType.transcript     => Icons.school_outlined,
    DocumentType.recommendation => Icons.recommend_outlined,
    DocumentType.passport       => Icons.badge_outlined,
    DocumentType.other          => Icons.attach_file_outlined,
  };

  String _labelFor(DocumentType t) => switch (t) {
    DocumentType.cv             => 'CV',
    DocumentType.transcript     => 'Releve de notes',
    DocumentType.recommendation => 'Lettre de recommandation',
    DocumentType.passport       => 'Passeport',
    DocumentType.other          => 'Autre',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: DocumentType.values.map((type) {
          final isSelected = selected == type;
          final color = _colorFor(type);
          final isLast = type == DocumentType.values.last;
          return GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.40)
                      : const Color(0xFFE5E7EB),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.12)
                        : const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFor(type),
                      size: 18,
                      color: isSelected ? color : _kGrey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_labelFor(type),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? color : _kNavy)),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFD1D5DB),
                      width: isSelected ? 6 : 2,
                    ),
                  ),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── File Picker Zone ──────────────────────────────────────────────────────────

class _FilePicker extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPick;
  const _FilePicker({required this.fileName, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return GestureDetector(
      onTap: onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: hasFile
              ? const Color(0xFF10B981).withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                : const Color(0xFFE5E7EB),
            width: hasFile ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: hasFile
                    ? const Color(0xFF10B981).withValues(alpha: 0.10)
                    : _kBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile
                    ? Icons.check_circle_outline_rounded
                    : Icons.upload_file_outlined,
                size: 30,
                color: hasFile ? const Color(0xFF10B981) : _kBlue,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFile ? fileName! : 'Appuyer pour selectionner',
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasFile ? FontWeight.w600 : FontWeight.w500,
                color: hasFile ? _kNavy : _kGrey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!hasFile) ...[
              const SizedBox(height: 6),
              const Text(
                'PDF  JPG  PNG  DOC  DOCX',
                style: TextStyle(fontSize: 12, color: _kGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

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

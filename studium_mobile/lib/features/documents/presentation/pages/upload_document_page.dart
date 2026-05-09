import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/document.dart';
import '../providers/document_providers.dart';

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
        const SnackBar(content: Text('Veuillez sélectionner un fichier')),
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
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Erreur : $msg')),
          ]),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uploader un document'),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _upload,
                  child: const Text('Enregistrer'),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Type de document',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            // ─── Sélecteur type sans widgets dépréciés ────────────────────
            Column(
              children: DocumentType.values.map((type) {
                final selected = _selectedType == type;
                return InkWell(
                  onTap: () => setState(() => _selectedType = type),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _labelFor(type),
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            const Text('Fichier',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _filePath != null
                          ? Icons.check_circle_outline
                          : Icons.upload_file_outlined,
                      size: 40,
                      color: _filePath != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fileName ?? 'Appuyer pour sélectionner un fichier',
                      style: TextStyle(
                        color:
                            _filePath != null ? Colors.black87 : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PDF, JPG, PNG, DOC, DOCX',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(DocumentType type) => switch (type) {
        DocumentType.cv             => 'CV',
        DocumentType.transcript     => 'Relevé de notes',
        DocumentType.recommendation => 'Lettre de recommandation',
        DocumentType.passport       => 'Passeport',
        DocumentType.other          => 'Autre',
      };
}
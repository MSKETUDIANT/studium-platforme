import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/document.dart';
import '../providers/document_providers.dart';
import 'upload_document_page.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mes Documents',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Color(0xFF1A1D2E)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1D2E)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1D2E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadDocumentPage()),
        ).then((_) => ref.invalidate(documentsProvider)),
      ),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4880FF).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_open_outlined,
                        size: 36, color: Color(0xFF4880FF)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucun document uploadé',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1A1D2E))),
                  const SizedBox(height: 6),
                  const Text('Appuyez sur + pour ajouter un document',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF9CA3AF))),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _DocumentCard(docs[i]),
          );
        },
      ),
    );
  }
}

// ─── Document Card ────────────────────────────────────────────────────────────

class _DocumentCard extends ConsumerWidget {
  final Document doc;
  const _DocumentCard(this.doc);

  Color _statusColor() => switch (doc.status) {
        DocumentStatus.approved    => const Color(0xFF10B981),
        DocumentStatus.rejected    => const Color(0xFFEF4444),
        DocumentStatus.underReview => const Color(0xFFF59E0B),
        DocumentStatus.uploaded    => const Color(0xFF4880FF),
      };

  Color _typeColor() => switch (doc.type) {
        DocumentType.cv             => const Color(0xFF4880FF),
        DocumentType.transcript     => const Color(0xFF8B5CF6),
        DocumentType.recommendation => const Color(0xFF10B981),
        DocumentType.passport       => const Color(0xFFF59E0B),
        DocumentType.other          => const Color(0xFF6B7280),
      };

  IconData _typeIcon() => switch (doc.type) {
        DocumentType.cv             => Icons.description_outlined,
        DocumentType.transcript     => Icons.school_outlined,
        DocumentType.recommendation => Icons.recommend_outlined,
        DocumentType.passport       => Icons.badge_outlined,
        DocumentType.other          => Icons.attach_file_outlined,
      };

  String _shortName() {
    const max = 28;
    if (doc.fileName.length <= max) return doc.fileName;
    final ext = doc.fileName.contains('.')
        ? '.${doc.fileName.split('.').last}'
        : '';
    return '${doc.fileName.substring(0, max - ext.length - 1)}…$ext';
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor();
    final typeColor   = _typeColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // header
            Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_typeIcon(), color: typeColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.typeLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1A1D2E))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(doc.statusLabel,
                          style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 14),

            // file info
            _InfoRow(
                icon: Icons.insert_drive_file_outlined,
                label: 'Fichier',
                value: doc.fileName),
            _InfoRow(
                icon: Icons.data_usage_outlined,
                label: 'Taille',
                value: doc.sizeLabel),
            _InfoRow(
                icon: Icons.code_outlined,
                label: 'Format',
                value: doc.mimeType),
            if (doc.createdAt != null)
              _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Uploadé le',
                  value: _fmtDate(doc.createdAt!)),

            // rejection reason
            if (doc.status == DocumentStatus.rejected &&
                doc.rejectionReason != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Motif de rejet',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444))),
                          const SizedBox(height: 4),
                          Text(doc.rejectionReason!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFEF4444),
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // open file button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(doc.fileUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Impossible d\'ouvrir le fichier')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ouvrir le fichier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4880FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref);
                },
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFEF4444)),
                label: const Text('Supprimer le document',
                    style: TextStyle(color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(0xFFEF4444), width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le document ?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('${doc.typeLabel} — ${doc.fileName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(documentsProvider.notifier).delete(doc.id, doc.fileUrl);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor();
    final typeColor   = _typeColor();

    return GestureDetector(
      onTap: () => _showDetails(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // type icon
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(), color: typeColor, size: 22),
            ),
            const SizedBox(width: 12),

            // info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.typeLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A1D2E))),
                  const SizedBox(height: 3),
                  Text(
                    '${_shortName()} · ${doc.sizeLabel}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (doc.status == DocumentStatus.rejected &&
                      doc.rejectionReason != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 12, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doc.rejectionReason!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFEF4444),
                                fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(doc.statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),

            // delete
            GestureDetector(
              onTap: () => _confirmDelete(context, ref),
              child: const Icon(Icons.delete_outline,
                  size: 20, color: Color(0xFFEF4444)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text('$label :',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF1A1D2E))),
          ),
        ],
      ),
    );
  }
}

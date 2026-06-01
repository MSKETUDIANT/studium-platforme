import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/document.dart';
import '../providers/document_providers.dart';
import 'upload_document_page.dart';

const _kBg     = Color(0xFFF4F6FB);
const _kNavy   = Color(0xFF1A1D2E);
const _kBlue   = Color(0xFF4880FF);
const _kGrey   = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: documentsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: _kBlue)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(e.toString(),
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
            data: (docs) => CustomScrollView(
              slivers: [
                // ─── Gradient Header ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildHeader(context, docs)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.06),
                ),
                // ─── Upload Button ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: _UploadButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UploadDocumentPage()),
                      ).then((_) => ref.invalidate(documentsProvider)),
                    ),
                  ).animate().fadeIn(delay: 120.ms).slideY(begin: .04),
                ),
                // ─── Content ─────────────────────────────────────────────
                docs.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _DocumentCard(docs[i])
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                      milliseconds: 80 + i * 55),
                                  duration:
                                      const Duration(milliseconds: 260),
                                )
                                .slideY(
                                  begin: .05,
                                  duration:
                                      const Duration(milliseconds: 260),
                                  curve: Curves.easeOut,
                                ),
                            childCount: docs.length,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<Document> docs) {
    final total    = docs.length;
    final approved = docs.where((d) => d.status == DocumentStatus.approved).length;
    final pending  = docs.where((d) => d.status == DocumentStatus.uploaded ||
        d.status == DocumentStatus.underReview).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0D1F42),
              Color(0xFF1565C0),
              Color(0xFF1E5298),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1F42).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -16, top: -16,
              child: _DecorCircle(size: 110, opacity: 0.08),
            ),
            Positioned(
              right: 50, bottom: -20,
              child: _DecorCircle(size: 70, opacity: 0.06),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.folder_open_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Documents',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                const Text(
                  'Mes documents',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatPill(
                      icon: Icons.folder_outlined,
                      label: '$total fichier${total > 1 ? "s" : ""}',
                    ),
                    _StatPill(
                      icon: Icons.check_circle_outline,
                      label: '$approved validé${approved > 1 ? "s" : ""}',
                    ),
                    _StatPill(
                      icon: Icons.schedule_outlined,
                      label: '$pending en attente',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            40, 24, 40, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_outlined,
                  size: 36, color: _kBlue),
            ),
            const SizedBox(height: 20),
            const Text('Aucun document',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kNavy)),
            const SizedBox(height: 8),
            const Text(
              'Uploadez vos fichiers pour\ncomplèter votre dossier.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kGrey, height: 1.5),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms),
      ),
    );
  }
}

// ─── Upload Button ─────────────────────────────────────────────────────────────

class _UploadButton extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF4880FF), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file_outlined, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Uploader un document',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
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

// ─── Document Card ─────────────────────────────────────────────────────────────

class _DocumentCard extends ConsumerWidget {
  final Document doc;
  const _DocumentCard(this.doc);

  Color _statusColor() => switch (doc.status) {
        DocumentStatus.approved    => const Color(0xFF10B981),
        DocumentStatus.rejected    => const Color(0xFFEF4444),
        DocumentStatus.underReview => const Color(0xFFF59E0B),
        DocumentStatus.uploaded    => _kBlue,
      };

  Color _typeColor() => switch (doc.type) {
        DocumentType.cv             => _kBlue,
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
    return '${doc.fileName.substring(0, max - ext.length - 1)}...$ext';
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                            color: _kNavy)),
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
                  label: 'Date',
                  value: _fmtDate(doc.createdAt!)),
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
                            content: Text("Impossible d'ouvrir le fichier")),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ouvrir le fichier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
                  side: const BorderSide(color: Color(0xFFEF4444)),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(), color: typeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.typeLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _kNavy)),
                      const SizedBox(height: 3),
                      Text(
                        '${_shortName()} · ${doc.sizeLabel}',
                        style: const TextStyle(
                            fontSize: 12, color: _kGrey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (doc.status == DocumentStatus.rejected &&
                          doc.rejectionReason != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
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
                        ]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

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
          Icon(icon, size: 15, color: _kGrey),
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
                style: const TextStyle(fontSize: 13, color: _kNavy)),
          ),
        ],
      ),
    );
  }
}

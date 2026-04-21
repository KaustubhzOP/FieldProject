import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint.dart';
import '../../config/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AdminComplaintManagementScreen extends StatelessWidget {
  const AdminComplaintManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Complaint Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'In Progress'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        // StreamBuilder at this level so all tabs share one stream
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.redAccent)));
            }

            // Parse ALL complaints once
            final List<ComplaintModel> all = [];
            for (final doc in (snap.data?.docs ?? [])) {
              try {
                final data = Map<String, dynamic>.from(doc.data() as Map);
                data['id'] = doc.id;
                all.add(ComplaintModel.fromJson(data));
              } catch (_) {}
            }
            all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return TabBarView(
              children: [
                _ComplaintTab(complaints: all, status: 'pending'),
                _ComplaintTab(complaints: all, status: 'in_progress'),
                _ComplaintTab(complaints: all, status: 'resolved'),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ComplaintTab extends StatelessWidget {
  final List<ComplaintModel> complaints;
  final String status;

  const _ComplaintTab({required this.complaints, required this.status});

  @override
  Widget build(BuildContext context) {
    final filtered = complaints.where((c) => c.status == status).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(status == 'resolved' ? Icons.check_circle_outline : Icons.inbox_outlined,
                color: Colors.white12, size: 64),
            const SizedBox(height: 12),
            Text('No ${status.replaceAll('_', ' ')} complaints',
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    final color = status == 'resolved' ? Colors.green : (status == 'in_progress' ? Colors.blue : Colors.orange);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final c = filtered[i];
        final hasImg = c.imageUrl != null && c.imageUrl!.isNotEmpty;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _ComplaintDetailScreen(complaint: c)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(
                    status == 'resolved' ? Icons.check_circle : (status == 'in_progress' ? Icons.autorenew : Icons.pending),
                    color: color, size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.id,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 3),
                      Text('${c.type}  •  ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      if (hasImg) ...[
                        const SizedBox(height: 4),
                        Row(children: const [
                          Icon(Icons.image, color: Colors.tealAccent, size: 12),
                          SizedBox(width: 4),
                          Text('Photo attached', style: TextStyle(color: Colors.tealAccent, fontSize: 11)),
                        ]),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL SCREEN (full page, avoids all dialog/context/overlay issues)
// ─────────────────────────────────────────────────────────────────────────────
class _ComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel complaint;
  const _ComplaintDetailScreen({required this.complaint});

  @override
  State<_ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<_ComplaintDetailScreen> {
  Uint8List? _imageBytes;
  bool _imageLoading = true;
  String _imageStatus = '';

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  void _decodeImage() {
    final url = widget.complaint.imageUrl;
    if (url == null || url.trim().isEmpty) {
      setState(() { _imageLoading = false; _imageStatus = 'none'; });
      return;
    }

    try {
      String clean = url.replaceAll(RegExp(r'\s'), '');
      // Strip data-URL prefix
      if (clean.contains(';base64,')) clean = clean.split(';base64,').last;
      else if (clean.contains(',') && clean.length > 100) {
        // It's raw base64 that happens to contain commas — don't split
        // (regular base64 doesn't have commas, but URL-safe might have issues)
      }
      // Fix padding
      final r = clean.length % 4;
      if (r != 0) clean += '=' * (4 - r);

      final bytes = base64Decode(clean);
      setState(() { _imageBytes = bytes; _imageLoading = false; _imageStatus = 'ok'; });
    } catch (e) {
      debugPrint('[IMG DECODE] Failed: $e');
      setState(() { _imageLoading = false; _imageStatus = 'error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final hasImg = c.imageUrl != null && c.imageUrl!.isNotEmpty;
    final sizeKB = hasImg ? (c.imageUrl!.length / 1024).toStringAsFixed(1) : '0';
    final statusColor = c.status == 'resolved' ? Colors.green : (c.status == 'in_progress' ? Colors.blue : Colors.orange);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(c.type),
        actions: [
          if (c.status != 'resolved')
            TextButton.icon(
              onPressed: () {
                final newStatus = c.status == 'pending' ? 'in_progress' : 'resolved';
                context.read<ComplaintProvider>().updateComplaintStatus(c.id, newStatus);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                c.status == 'pending' ? 'Start' : 'Resolve',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(c.status.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 20),

            _section('Complaint ID', c.id),
            _section('Type', c.type),
            _section('Description', c.description),
            _section('Raised By', c.raisedBy),
            _section('Date', '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year} at ${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}'),
            _section('Location', 'LAT: ${c.latitude.toStringAsFixed(5)}  |  LNG: ${c.longitude.toStringAsFixed(5)}'),

            const SizedBox(height: 20),
            Row(children: [
              const Text('Attached Photo', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Text(hasImg ? '($sizeKB KB stored)' : '(none)',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
            const SizedBox(height: 10),

            // IMAGE DISPLAY
            if (_imageLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, err, __) => _imgError('Render failed: $err'),
                ),
              )
            else if (hasImg)
              _imgError('Stored but could not decode ($sizeKB KB). Status: $_imageStatus')
            else
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('No photo attached', style: TextStyle(color: Colors.white38))),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _section(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textBody, fontSize: 14)),
          const Divider(color: Colors.white10, height: 20),
        ],
      ),
    );
  }

  Widget _imgError(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Text(msg, style: const TextStyle(color: Colors.orange, fontSize: 12)),
  );
}

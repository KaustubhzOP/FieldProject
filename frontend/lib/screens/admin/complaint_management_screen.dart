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
    final bool isDesktop = MediaQuery.of(context).size.width > 1100;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Complaint Management'),
          bottom: TabBar(
            labelColor: AppColors.card,
            unselectedLabelColor: AppColors.card.withOpacity(0.7),
            indicatorColor: AppColors.card,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'In Progress'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accent));
            }
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

            final List<ComplaintModel> all = [];
            for (final doc in (snap.data?.docs ?? [])) {
              try {
                final data = Map<String, dynamic>.from(doc.data() as Map);
                data['id'] = doc.id;
                all.add(ComplaintModel.fromJson(data));
              } catch (_) {}
            }
            all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (isDesktop) {
              return _AdminWebManagementLayout(allComplaints: all);
            }

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

class _AdminWebManagementLayout extends StatefulWidget {
  final List<ComplaintModel> allComplaints;
  const _AdminWebManagementLayout({required this.allComplaints});

  @override
  State<_AdminWebManagementLayout> createState() => _AdminWebManagementLayoutState();
}

class _AdminWebManagementLayoutState extends State<_AdminWebManagementLayout> {
  ComplaintModel? _selectedComplaint;

  @override
  Widget build(BuildContext context) {
    final tabIndex = DefaultTabController.of(context).index;
    final status = tabIndex == 0 ? 'pending' : (tabIndex == 1 ? 'in_progress' : 'resolved');
    final filtered = widget.allComplaints.where((c) => c.status == status).toList();

    return Row(
      children: [
        // Sidebar List
        SizedBox(
          width: 400,
          child: Container(
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
            child: filtered.isEmpty 
              ? const Center(child: Text('No complaints', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    final isSelected = _selectedComplaint?.id == c.id;
                    return InkWell(
                      onTap: () => setState(() => _selectedComplaint = c),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.id.toUpperCase().substring(0, 8), style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textHeader, fontWeight: FontWeight.bold)),
                                  Text(c.type, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (isSelected) const Icon(Icons.chevron_right, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
        // Detail Area
        Expanded(
          child: _selectedComplaint == null 
            ? const Center(child: Text('Select a complaint to view details', style: TextStyle(color: AppColors.textMuted)))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ComplaintDetailScreen(complaint: _selectedComplaint, key: ValueKey(_selectedComplaint!.id)),
                ),
              ),
        ),
      ],
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
                color: AppColors.border, size: 64),
            const SizedBox(height: 12),
            Text('No ${status.replaceAll('_', ' ')} complaints',
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    final color = status == 'resolved' ? AppColors.success : (status == 'in_progress' ? AppColors.primary : AppColors.warning);

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
              MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: c)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13)),
                      const SizedBox(height: 3),
                      Text('${c.type}  •  ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      if (hasImg) ...[
                        const SizedBox(height: 4),
                        Row(children: const [
                          Icon(Icons.image, color: AppColors.teal, size: 12),
                          SizedBox(width: 4),
                          Text('Photo attached', style: TextStyle(color: AppColors.teal, fontSize: 11)),
                        ]),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
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
class ComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel? complaint;
  final String? complaintId;
  const ComplaintDetailScreen({super.key, this.complaint, this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  ComplaintModel? _complaint;
  bool _loading = false;
  Uint8List? _imageBytes;
  bool _imageLoading = true;
  String _imageStatus = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(covariant ComplaintDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.complaint != oldWidget.complaint || widget.complaintId != oldWidget.complaintId) {
      _initData();
    }
  }

  void _initData() {
    if (widget.complaint != null) {
      _complaint = widget.complaint;
      _decodeImage();
    } else if (widget.complaintId != null) {
      _fetchComplaint();
    }
  }

  Future<void> _fetchComplaint() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId)
          .get();
      if (doc.exists && mounted) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        setState(() {
          _complaint = ComplaintModel.fromJson(data);
          _loading = false;
        });
        _decodeImage();
      }
    } catch (e) {
      debugPrint('[FETCH] Failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _decodeImage() {
    final url = _complaint?.imageUrl;
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
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_complaint == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Complaint not found', style: TextStyle(color: AppColors.textHeader))),
      );
    }

    final c = _complaint!;
    final statusColor = c.status == 'resolved' ? AppColors.success : (c.status == 'in_progress' ? AppColors.primary : AppColors.warning);

    // Action button logic
    Widget? actionButton;
    if (c.status != 'resolved') {
      actionButton = TextButton.icon(
        onPressed: () => _handleStatusUpdate(context, c),
        icon: const Icon(Icons.check, color: AppColors.card),
        label: Text(c.status == 'pending' ? 'Start' : 'Resolve', style: const TextStyle(color: AppColors.card)),
      );
    }

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(c.type, style: const TextStyle(color: AppColors.textHeader, fontSize: 24, fontWeight: FontWeight.bold)),
                 if (actionButton != null) actionButton,
               ],
             ),
             const SizedBox(height: 10),
          ],
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
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
            Text(c.imageUrl != null && c.imageUrl!.isNotEmpty ? '(${(c.imageUrl!.length / 1024).toStringAsFixed(1)} KB stored)' : '(none)',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          _buildImageDisplay(c),
          const SizedBox(height: 30),
        ],
      ),
    );

    if (isDesktop) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(c.type), actions: [if (actionButton != null) actionButton]),
      body: body,
    );
  }

  void _handleStatusUpdate(BuildContext context, ComplaintModel c) async {
    final newStatus = c.status == 'pending' ? 'in_progress' : 'resolved';
    final remarksController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(c.status == 'pending' ? 'Mark as In Progress' : 'Mark as Resolved', style: const TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a message for the resident (optional):', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textBody),
              decoration: InputDecoration(
                hintText: 'e.g. Team dispatched. Estimated resolution in 2 hours.',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final remarks = remarksController.text.trim();
      await context.read<ComplaintProvider>().updateComplaintStatus(c.id, newStatus, remarks: remarks.isNotEmpty ? remarks : null);
      if (context.mounted && MediaQuery.of(context).size.width <= 900) {
         Navigator.pop(context);
      }
    }
  }

  Widget _buildImageDisplay(ComplaintModel c) {
    if (_imageLoading) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)));
    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_imageBytes!, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, err, __) => _imgError('Render failed: $err')),
      );
    }
    if (c.imageUrl != null && c.imageUrl!.isNotEmpty) return _imgError('Stored but could not decode. Status: $_imageStatus');
    return Container(
      height: 80, width: double.infinity,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: const Center(child: Text('No photo attached', style: TextStyle(color: AppColors.textMuted))),
    );
  }

  Widget _section(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textBody, fontSize: 14)),
          const Divider(color: AppColors.border, height: 20),
        ],
      ),
    );
  }

  Widget _imgError(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Text(msg, style: const TextStyle(color: AppColors.warning, fontSize: 12)),
  );
}

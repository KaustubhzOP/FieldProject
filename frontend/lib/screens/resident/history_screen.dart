import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../models/collection_record.dart';
import '../../config/app_colors.dart';

class CollectionHistoryScreen extends StatelessWidget {
  const CollectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final ward = user?.ward ?? '';
    
    // DEBUG: print('VIEWING HISTORY FOR WARD: $ward');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collection History'),
        elevation: 0,
      ),
      body: ward.isEmpty 
        ? const Center(child: Text('Register your home to see history.', style: TextStyle(color: AppColors.textMuted)))
        : StreamBuilder<List<CollectionRecordModel>>(
            stream: context.read<CollectionProvider>().getWardCollectionHistory(ward),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error loading history: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: AppColors.border),
                      const SizedBox(height: 16),
                      const Text('No recent collections in your ward', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final bool isMissed = item.status == 'missed';
                  final bool isInProgress = item.status == 'in_progress';
                  
                  final dateStr = DateFormat('EEE, MMM d, y').format(item.startTime);
                  final timeStr = DateFormat('hh:mm a').format(item.startTime);

                  Color statusColor = AppColors.success;
                  IconData statusIcon = Icons.check_circle_outline;
                  
                  if (isMissed) {
                    statusColor = AppColors.error;
                    statusIcon = Icons.cancel_outlined;
                  } else if (isInProgress) {
                    statusColor = AppColors.warning;
                    statusIcon = Icons.pending_outlined;
                  }

                  return Card(
                    elevation: 0,
                    color: AppColors.card,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 24),
                      ),
                      title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader)),
                      subtitle: Text('Truck Tracking: ${item.id.length > 8 ? item.id.substring(0, 8) : item.id} • $timeStr', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.status.toUpperCase(), 
                            style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 10, letterSpacing: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.pointsCollected}/${item.totalPoints} Points', 
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}

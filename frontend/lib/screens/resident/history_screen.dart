import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CollectionHistoryScreen extends StatelessWidget {
  const CollectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate dummy collection history (Last 7 days)
    final List<Map<String, dynamic>> history = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: index + 1));
      return {
        'date': DateFormat('EEE, MMM d, y').format(date),
        'time': '08:4${index} AM',
        'status': index % 3 == 0 ? 'Missed' : 'Collected',
        'truck': 'MH-01-AB-${1234 + index}',
        'weight': '${(2.0 + index / 2).toStringAsFixed(1)} kg',
      };
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Collection History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          final bool isMissed = item['status'] == 'Missed';
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMissed ? Colors.red.shade50 : Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMissed ? Icons.close : Icons.check,
                  color: isMissed ? Colors.red : Colors.green,
                ),
              ),
              title: Text(item['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Truck: ${item['truck']} • ${item['time']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item['status'], style: TextStyle(fontWeight: FontWeight.bold, color: isMissed ? Colors.red : Colors.green)),
                  Text(item['weight'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

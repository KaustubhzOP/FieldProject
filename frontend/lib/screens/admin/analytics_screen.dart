import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Collection Statistics Title
            _buildSectionHeader(context, 'Collection Statistics'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildMetricCard('Total Waste', '245 Tons', Colors.blue, 'Daily'),
                _buildMetricCard('Completion', '92%', Colors.green, 'Today'),
                _buildMetricCard('Avg Response', '14 Min', Colors.orange, 'Last Hour'),
                _buildMetricCard('Drivers Active', '18/20', Colors.purple, 'Now'),
              ],
            ),
            const SizedBox(height: 24),
            // Waste Collection Trends
            _buildChartCard(
              context,
              'Weekly Waste Trends (Tons)',
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          const FlSpot(0, 30),
                          const FlSpot(1, 45),
                          const FlSpot(2, 40),
                          const FlSpot(3, 60),
                          const FlSpot(4, 55),
                          const FlSpot(5, 75),
                          const FlSpot(6, 70),
                        ],
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 4,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Citizen Satisfaction
            _buildChartCard(
              context,
              'Citizen Satisfaction (%)',
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(value: 65, color: Colors.green, title: 'Happy', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      PieChartSectionData(value: 20, color: Colors.blue, title: 'Neutral', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      PieChartSectionData(value: 15, color: Colors.orange, title: 'Unhappy', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Ward-wise Complaints
            _buildChartCard(
              context,
              'Ward-wise Complaints',
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 12, color: Colors.blue)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 18, color: Colors.blue)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 14, color: Colors.blue)]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 20, color: Colors.blue)]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const Spacer(),
            Text(subtitle, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, Widget chart) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            chart,
          ],
        ),
      ),
    );
  }
}

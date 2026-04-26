import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_colors.dart';

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
                _buildMetricCard('Total Waste', '245 Tons', AppColors.primary, 'Daily'),
                _buildMetricCard('Completion', '92%', AppColors.success, 'Today'),
                _buildMetricCard('Avg Response', '14 Min', AppColors.warning, 'Last Hour'),
                _buildMetricCard('Drivers Active', '18/20', AppColors.accent, 'Now'),
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
                        color: AppColors.primary,
                        barWidth: 4,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
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
                      PieChartSectionData(value: 65, color: AppColors.success, title: 'Happy', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.card)),
                      PieChartSectionData(value: 20, color: AppColors.primary, title: 'Neutral', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.card)),
                      PieChartSectionData(value: 15, color: AppColors.warning, title: 'Unhappy', radius: 50, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.card)),
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
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 12, color: AppColors.primary)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 18, color: AppColors.primary)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: AppColors.primary)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 14, color: AppColors.primary)]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 20, color: AppColors.primary)]),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, Widget chart) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
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

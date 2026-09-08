import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/data_controller.dart';
import '../widgets/animated_empty_pie_chart.dart';

class AnalyticsTab extends StatelessWidget {
  final DataController dataController;
  final int selectedYear;
  final int selectedMonth;
  final VoidCallback? onNavigateToProfile;

  const AnalyticsTab({
    super.key,
    required this.dataController,
    required this.selectedYear,
    required this.selectedMonth,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final user = dataController.userProfile;
    final transactions = dataController.transactions;

    final periodTxs = transactions
        .where((t) =>
            t.date.year == selectedYear &&
            t.date.month == (selectedMonth + 1))
        .toList();
    final expTxs = periodTxs.where((t) => t.type == 'expense').toList();

    final Map<String, double> catMap = {};
    for (var t in expTxs) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    }

    final pBank = user.primaryBank.isNotEmpty ? user.primaryBank : 'Not Set';
    final sBank = user.secondaryBank.isNotEmpty ? user.secondaryBank : 'Not Set';
    final mBank = user.mfs.isNotEmpty ? user.mfs : 'Not Set';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Statement Header Profile Banner
          InkWell(
            onTap: onNavigateToProfile,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFF0A221C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('FINANCIAL STATEMENT PROFILE',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                    letterSpacing: 1)),
                            Icon(Icons.chevron_right_rounded,
                                size: 16, color: Color(0xFF10B981)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(user.name.isNotEmpty ? user.name : 'Tap to set up Profile',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        Text(
                            'Occupation: ${user.occupation.isNotEmpty ? user.occupation : "N/A"}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.slate300)),
                        Text(
                            'Phone: ${user.phone.isNotEmpty ? user.phone : "N/A"} • Address: ${user.address.isNotEmpty ? user.address : "N/A"}',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.slate400)),
                        const Divider(color: Color(0xFF061714)),
                        Text(
                            'Primary: $pBank | Sec: $sBank | Mobile: $mBank',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF34D399))),
                      ],
                    ),
                  ),
                  if (user.avatarPath.isNotEmpty &&
                      File(user.avatarPath).existsSync())
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: CircleAvatar(
                          radius: 28,
                          backgroundImage: FileImage(File(user.avatarPath))),
                    )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Expense Pie Chart Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF0A221C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MONTHLY EXPENSE PIE CHART',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981))),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: catMap.isEmpty
                      ? const AnimatedEmptyPieChart()
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 0,
                            sections: catMap.entries.map((e) {
                              return PieChartSectionData(
                                color: Colors.primaries[
                                    catMap.keys.toList().indexOf(e.key) %
                                        Colors.primaries.length],
                                value: e.value,
                                title:
                                    "${e.key}\n৳${e.value.toStringAsFixed(0)}",
                                radius: 80,
                                titleStyle: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

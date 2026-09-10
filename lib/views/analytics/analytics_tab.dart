import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_categories.dart';
import '../../controllers/data_controller.dart';
import '../../models/user_profile.dart';
import '../../models/transaction_item.dart';
import '../../services/pdf_statement_service.dart';
import '../widgets/animated_empty_pie_chart.dart';
import '../widgets/app_toast.dart';

class AnalyticsTab extends StatefulWidget {
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
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  late int _selectedReportYear;

  @override
  void initState() {
    super.initState();
    _selectedReportYear = widget.selectedYear;
  }

  @override
  void didUpdateWidget(covariant AnalyticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear) {
      _selectedReportYear = widget.selectedYear;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.dataController.userProfile;
    final transactions = widget.dataController.transactions;
    final selectedYear = widget.selectedYear;
    final selectedMonth = widget.selectedMonth;
    final onNavigateToProfile = widget.onNavigateToProfile;

    // Filter transactions to selected month
    final periodTxs = transactions
        .where((t) =>
            t.date.year == selectedYear && t.date.month == (selectedMonth + 1))
        .toList();

    // 1. Group Incomes by category
    final Map<String, double> incomeCatMap = {};
    double totalIncome = 0;
    for (var t in periodTxs) {
      if (t.type == 'income' ||
          (t.type == 'transfer' && t.category == 'Cash Received')) {
        incomeCatMap[t.category] = (incomeCatMap[t.category] ?? 0) + t.amount;
        totalIncome += t.amount;
      }
    }
    final sortedIncomeEntries = incomeCatMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 2. Group Expenses by category
    final Map<String, double> expenseCatMap = {};
    double totalExpense = 0;
    for (var t in periodTxs) {
      if (t.type == 'expense') {
        expenseCatMap[t.category] = (expenseCatMap[t.category] ?? 0) + t.amount;
        totalExpense += t.amount;
      }
    }
    final sortedExpenseEntries = expenseCatMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. Group Savings / Investments
    double totalSavings = 0;
    for (var t in periodTxs) {
      if (t.type == 'saving') {
        totalSavings += t.amount;
      }
    }

    // 4. Net Monthly Flow
    final double netMonthlyFlow = totalIncome - totalExpense - totalSavings;

    // Available years for dropdown
    final Set<int> yearSet = {
      DateTime.now().year,
      selectedYear,
      _selectedReportYear,
    };
    for (var t in transactions) {
      yearSet.add(t.date.year);
    }
    for (int y = _selectedReportYear - 2; y <= _selectedReportYear + 2; y++) {
      yearSet.add(y);
    }
    final List<int> availableYears = yearSet.toList()
      ..sort((a, b) => b.compareTo(a));

    // Calculate 12-month expenses for _selectedReportYear
    final List<double> monthlyExpenses = List.filled(12, 0.0);
    for (var t in transactions) {
      if (t.type == 'expense' && t.date.year == _selectedReportYear) {
        final mIdx = t.date.month - 1;
        if (mIdx >= 0 && mIdx < 12) {
          monthlyExpenses[mIdx] += t.amount;
        }
      }
    }

    // Chart scale calculations
    final double maxExp =
        monthlyExpenses.fold(0.0, (prev, e) => e > prev ? e : prev);
    final double chartMaxY;
    final double chartYInterval;
    if (maxExp <= 7000.0) {
      chartMaxY = 7000.0;
      chartYInterval = 1000.0;
    } else {
      final double step = ((maxExp / 7.0) / 1000.0).ceil() * 1000.0;
      chartYInterval = step < 1000.0 ? 1000.0 : step;
      chartMaxY = chartYInterval * 7.0;
    }

    // Calculate Yearly aggregates, category breakdowns, and monthly distributions for _selectedReportYear
    double yearlyIncome = 0.0;
    double yearlyExpense = 0.0;
    double yearlySavings = 0.0;
    final Map<String, double> yearlyIncomeCatMap = {};
    final Map<String, double> yearlyExpenseCatMap = {};
    final List<double> yearlyMonthlyIncomes = List.filled(12, 0.0);
    final List<double> yearlyMonthlyExpenses = List.filled(12, 0.0);

    for (var t in transactions) {
      if (t.date.year == _selectedReportYear) {
        final mIdx = t.date.month - 1;
        if (t.type == 'income' ||
            (t.type == 'transfer' && t.category == 'Cash Received')) {
          yearlyIncome += t.amount;
          yearlyIncomeCatMap[t.category] =
              (yearlyIncomeCatMap[t.category] ?? 0) + t.amount;
          if (mIdx >= 0 && mIdx < 12) {
            yearlyMonthlyIncomes[mIdx] += t.amount;
          }
        } else if (t.type == 'expense') {
          yearlyExpense += t.amount;
          yearlyExpenseCatMap[t.category] =
              (yearlyExpenseCatMap[t.category] ?? 0) + t.amount;
          if (mIdx >= 0 && mIdx < 12) {
            yearlyMonthlyExpenses[mIdx] += t.amount;
          }
        } else if (t.type == 'saving') {
          yearlySavings += t.amount;
        }
      }
    }
    final double yearlyNetBalance =
        yearlyIncome - yearlyExpense - yearlySavings;

    final sortedYearlyIncomeEntries = yearlyIncomeCatMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedYearlyExpenseEntries = yearlyExpenseCatMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Scale calculation for Yearly Income vs Expense Comparison Chart
    double maxYearlyVal = 0.0;
    for (int i = 0; i < 12; i++) {
      if (yearlyMonthlyIncomes[i] > maxYearlyVal) {
        maxYearlyVal = yearlyMonthlyIncomes[i];
      }
      if (yearlyMonthlyExpenses[i] > maxYearlyVal) {
        maxYearlyVal = yearlyMonthlyExpenses[i];
      }
    }

    final double yearlyChartMaxY;
    final double yearlyChartYInterval;
    if (maxYearlyVal <= 7000.0) {
      yearlyChartMaxY = 7000.0;
      yearlyChartYInterval = 1000.0;
    } else {
      final double rawStep = maxYearlyVal / 8.0;
      double step = 1000.0;
      if (rawStep <= 1000.0) {
        step = 1000.0;
      } else if (rawStep <= 2000.0) {
        step = 2000.0;
      } else if (rawStep <= 2500.0) {
        step = 2500.0;
      } else if (rawStep <= 5000.0) {
        step = 5000.0;
      } else if (rawStep <= 10000.0) {
        step = 10000.0;
      } else {
        step = (rawStep / 10000.0).ceil() * 10000.0;
      }
      yearlyChartYInterval = step;
      yearlyChartMaxY = (maxYearlyVal / step).ceil() * step;
    }

    final pBank = user.primaryBank.isNotEmpty ? user.primaryBank : 'Not Set';
    final sBank =
        user.secondaryBank.isNotEmpty ? user.secondaryBank : 'Not Set';
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
                  color: Theme.of(context).cardColor,
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
                        Text(
                            user.name.isNotEmpty
                                ? user.name
                                : 'Tap to set up Profile',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        Text(
                            'Occupation: ${user.occupation.isNotEmpty ? user.occupation : "N/A"}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.slate300)),
                        Text(
                            'Phone: ${user.phone.isNotEmpty ? user.phone : "N/A"} • Address: ${user.address.isNotEmpty ? user.address : "N/A"}',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.slate400)),
                        const Divider(color: Color(0xFF061714)),
                        Text('Primary: $pBank | Sec: $sBank | Mobile: $mBank',
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

          // 1. MONTHLY ANALYTICS Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY ANALYTICS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34D399),
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Statement and category reports for selected month.',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showPrintStatementModal(
                    context: context,
                    user: user,
                    periodTxs: periodTxs,
                    selectedMonth: selectedMonth,
                    selectedYear: selectedYear,
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    totalSavings: totalSavings,
                    netMonthlyFlow: netMonthlyFlow,
                    sortedIncomeEntries: sortedIncomeEntries,
                    sortedExpenseEntries: sortedExpenseEntries,
                    selectedReportYear: _selectedReportYear,
                    yearlyIncome: yearlyIncome,
                    yearlyExpense: yearlyExpense,
                    yearlySavings: yearlySavings,
                    yearlyNetBalance: yearlyNetBalance,
                    yearlyMonthlyIncomes: yearlyMonthlyIncomes,
                    yearlyMonthlyExpenses: yearlyMonthlyExpenses,
                    sortedYearlyIncomeEntries: sortedYearlyIncomeEntries,
                    sortedYearlyExpenseEntries: sortedYearlyExpenseEntries,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34D399),
                    foregroundColor: const Color(0xFF030A08),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Print Statement',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. MONTHLY FINANCIAL SUMMARY Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONTHLY FINANCIAL SUMMARY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate300,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  context,
                  label: 'Total Income',
                  value: '+৳${totalIncome.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF34D399),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  context,
                  label: 'Total Expense',
                  value: '-৳${totalExpense.toStringAsFixed(2)}',
                  valueColor: const Color(0xFFFB7185),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  context,
                  label: 'Total Savings/Investments',
                  value: '৳${totalSavings.toStringAsFixed(2)}',
                  valueColor: const Color(0xFFC084FC),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Monthly Flow',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        netMonthlyFlow < 0
                            ? '-৳${netMonthlyFlow.abs().toStringAsFixed(2)}'
                            : '৳${netMonthlyFlow.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: netMonthlyFlow < 0
                              ? const Color(0xFFFB7185)
                              : const Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. MONTHLY INCOME SOURCES Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONTHLY INCOME SOURCES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34D399),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                if (sortedIncomeEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No income recorded for this month.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.slate400,
                      ),
                    ),
                  )
                else
                  ...sortedIncomeEntries.asMap().entries.map((mapEntry) {
                    final idx = mapEntry.key;
                    final entry = mapEntry.value;
                    final double percentage = totalIncome > 0
                        ? (entry.value / totalIncome * 100)
                        : 0.0;
                    final double ratio = totalIncome > 0
                        ? (entry.value / totalIncome).clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom:
                              idx == sortedIncomeEntries.length - 1 ? 0 : 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '+৳${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth * ratio,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. MONTHLY EXPENSE BREAKDOWN Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONTHLY EXPENSE BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFB7185),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                if (sortedExpenseEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No expenses recorded for this month.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.slate400,
                      ),
                    ),
                  )
                else
                  ...sortedExpenseEntries.asMap().entries.map((mapEntry) {
                    final idx = mapEntry.key;
                    final entry = mapEntry.value;
                    final double percentage = totalExpense > 0
                        ? (entry.value / totalExpense * 100)
                        : 0.0;
                    final double ratio = totalExpense > 0
                        ? (entry.value / totalExpense).clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: idx == sortedExpenseEntries.length - 1
                              ? 0
                              : 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '-৳${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFB7185),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth * ratio,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFB7185),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Updated Monthly Expense Pie Chart Card with Visual Distribution Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MONTHLY EXPENSE PIE CHART',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFB7185),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4C0519).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFB7185).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'Visual Distribution',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFB7185),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                ),
                const SizedBox(height: 16),
                expenseCatMap.isEmpty
                    ? const SizedBox(
                        height: 200,
                        child: AnimatedEmptyPieChart(),
                      )
                    : Builder(builder: (context) {
                        // Order entries clockwise: non-largest slices first, largest slice last
                        final List<MapEntry<String, double>> pieChartEntries;
                        if (sortedExpenseEntries.length > 1) {
                          pieChartEntries = [
                            ...sortedExpenseEntries.skip(1),
                            sortedExpenseEntries.first,
                          ];
                        } else {
                          pieChartEntries = List.from(sortedExpenseEntries);
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 6,
                              child: SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 0,
                                    startDegreeOffset: -90,
                                    sections: pieChartEntries
                                        .asMap()
                                        .entries
                                        .map((m) {
                                      final idx = m.key;
                                      final e = m.value;
                                      final color =
                                          _getExpenseCategoryColor(e.key, idx);
                                      return PieChartSectionData(
                                        color: color,
                                        value: e.value,
                                        showTitle: false,
                                        radius: 82,
                                        borderSide: const BorderSide(
                                          color: Color(0xFF030A08),
                                          width: 1.5,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    pieChartEntries.asMap().entries.map((m) {
                                  final idx = m.key;
                                  final e = m.value;
                                  final color =
                                      _getExpenseCategoryColor(e.key, idx);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        );
                      }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. MONTHLY EXPENSE COMPARISON CHART Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONTHLY EXPENSE COMPARISON CHART',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFB7185),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB7185),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Expense',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: const Color(0xFF0A221C),
                          tooltipBorder: BorderSide(
                            color:
                                const Color(0xFFFB7185).withValues(alpha: 0.4),
                          ),
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec'
                            ];
                            final mName = months[group.x.toInt()];
                            return BarTooltipItem(
                              '$mName $_selectedReportYear\n',
                              const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: '৳${rod.toY.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFB7185),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: chartYInterval,
                            getTitlesWidget: (value, meta) {
                              if (value > chartMaxY || value < 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                NumberFormat('#,###').format(value.toInt()),
                                style: const TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.right,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              const months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec'
                              ];
                              final idx = value.toInt();
                              if (idx >= 0 && idx < 12) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    months[idx],
                                    style: const TextStyle(
                                      color: AppColors.slate400,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        verticalLines: List.generate(11, (i) {
                          return VerticalLine(
                            x: (i + 1) / 12.0,
                            color:
                                const Color(0xFF0F382E).withValues(alpha: 0.7),
                            strokeWidth: 1,
                          );
                        }),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartYInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFF0F382E).withValues(alpha: 0.7),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: const Color(0xFF0F382E).withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      barGroups: List.generate(12, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: monthlyExpenses[i],
                              color: const Color(0xFFFB7185),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Divider between comparison chart and year report
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 24,
          ),
          const SizedBox(height: 8),

          // 7. YEAR REPORT Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'YEAR REPORT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2DD4BF),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Year: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedReportYear,
                        dropdownColor: Theme.of(context).cardColor,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                        isDense: true,
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        items: availableYears.map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text(
                              '$y',
                              style: TextStyle(
                                color: y == _selectedReportYear
                                    ? const Color(0xFF34D399)
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newYear) {
                          if (newYear != null) {
                            setState(() {
                              _selectedReportYear = newYear;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Yearly Metric Cards Container (2x2 Grid)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildYearMetricCard(
                        context,
                        title: 'YEARLY INCOME',
                        value: '+৳${yearlyIncome.toStringAsFixed(2)}',
                        titleColor: const Color(0xFF34D399),
                        valueColor: const Color(0xFF34D399),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildYearMetricCard(
                        context,
                        title: 'YEARLY EXPENSE',
                        value: '-৳${yearlyExpense.toStringAsFixed(2)}',
                        titleColor: const Color(0xFFFB7185),
                        valueColor: const Color(0xFFFB7185),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildYearMetricCard(
                        context,
                        title: 'YEARLY SAVINGS',
                        value: '৳${yearlySavings.toStringAsFixed(2)}',
                        titleColor: const Color(0xFFC084FC),
                        valueColor: const Color(0xFFC084FC),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildYearMetricCard(
                        context,
                        title: 'YEARLY NET BALANCE',
                        value: yearlyNetBalance < 0
                            ? '-৳${yearlyNetBalance.abs().toStringAsFixed(2)}'
                            : '৳${yearlyNetBalance.toStringAsFixed(2)}',
                        titleColor: const Color(0xFF38BDF8),
                        valueColor: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 8. YEARLY INCOME VS EXPENSE COMPARISON Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YEARLY INCOME VS EXPENSE COMPARISON',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E8F0),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      width: 36,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB7185),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Expense',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: yearlyChartMaxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: const Color(0xFF0A221C),
                          tooltipBorder: BorderSide(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.4),
                          ),
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec'
                            ];
                            final mName = months[group.x.toInt()];
                            final isIncome = rodIndex == 0;
                            return BarTooltipItem(
                              '$mName $_selectedReportYear\n',
                              const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: isIncome
                                      ? 'Income: +৳${rod.toY.toStringAsFixed(2)}'
                                      : 'Expense: -৳${rod.toY.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isIncome
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFFB7185),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: yearlyChartYInterval,
                            getTitlesWidget: (value, meta) {
                              if (value > yearlyChartMaxY || value < 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                NumberFormat('#,###').format(value.toInt()),
                                style: const TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.right,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              const months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec'
                              ];
                              final idx = value.toInt();
                              if (idx >= 0 && idx < 12) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    months[idx],
                                    style: const TextStyle(
                                      color: AppColors.slate400,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        verticalLines: List.generate(11, (i) {
                          return VerticalLine(
                            x: (i + 1) / 12.0,
                            color:
                                const Color(0xFF0F382E).withValues(alpha: 0.7),
                            strokeWidth: 1,
                          );
                        }),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        horizontalInterval: yearlyChartYInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFF0F382E).withValues(alpha: 0.7),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: const Color(0xFF0F382E).withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      barGroups: List.generate(12, (i) {
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 1.5,
                          barRods: [
                            BarChartRodData(
                              toY: yearlyMonthlyIncomes[i],
                              color: const Color(0xFF34D399),
                              width: 7,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                            BarChartRodData(
                              toY: yearlyMonthlyExpenses[i],
                              color: const Color(0xFFFB7185),
                              width: 7,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 9. YEARLY INCOME EARNED Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YEARLY INCOME EARNED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34D399),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                if (sortedYearlyIncomeEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No income recorded for this year.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.slate400,
                      ),
                    ),
                  )
                else
                  ...sortedYearlyIncomeEntries.asMap().entries.map((mapEntry) {
                    final idx = mapEntry.key;
                    final entry = mapEntry.value;
                    final double percentage = yearlyIncome > 0
                        ? (entry.value / yearlyIncome * 100)
                        : 0.0;
                    final double ratio = yearlyIncome > 0
                        ? (entry.value / yearlyIncome).clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: idx == sortedYearlyIncomeEntries.length - 1
                              ? 0
                              : 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '+৳${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth * ratio,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 10. YEARLY EXPENSE SPENT Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YEARLY EXPENSE SPENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFB7185),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                if (sortedYearlyExpenseEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No expenses recorded for this year.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.slate400,
                      ),
                    ),
                  )
                else
                  ...sortedYearlyExpenseEntries.asMap().entries.map((mapEntry) {
                    final idx = mapEntry.key;
                    final entry = mapEntry.value;
                    final double percentage = yearlyExpense > 0
                        ? (entry.value / yearlyExpense * 100)
                        : 0.0;
                    final double ratio = yearlyExpense > 0
                        ? (entry.value / yearlyExpense).clamp(0.0, 1.0)
                        : 0.0;

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: idx == sortedYearlyExpenseEntries.length - 1
                              ? 0
                              : 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '-৳${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFB7185),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                    Container(
                                      height: 6,
                                      width: constraints.maxWidth * ratio,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFB7185),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildYearMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color titleColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: titleColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showPrintStatementModal({
    required BuildContext context,
    required UserProfile user,
    required List<TransactionItem> periodTxs,
    required int selectedMonth,
    required int selectedYear,
    required double totalIncome,
    required double totalExpense,
    required double totalSavings,
    required double netMonthlyFlow,
    required List<MapEntry<String, double>> sortedIncomeEntries,
    required List<MapEntry<String, double>> sortedExpenseEntries,
    required int selectedReportYear,
    required double yearlyIncome,
    required double yearlyExpense,
    required double yearlySavings,
    required double yearlyNetBalance,
    required List<double> yearlyMonthlyIncomes,
    required List<double> yearlyMonthlyExpenses,
    required List<MapEntry<String, double>> sortedYearlyIncomeEntries,
    required List<MapEntry<String, double>> sortedYearlyExpenseEntries,
  }) {
    final monthName = AppCategories.months[selectedMonth];
    final periodString = "$monthName $selectedYear";
    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Generate comprehensive formatted statement text for clipboard/export
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('PERFINAX COMPREHENSIVE FINANCIAL STATEMENT');
    buffer
        .writeln('Period: $periodString | Annual Report: $selectedReportYear');
    buffer.writeln('========================================');
    buffer.writeln('ACCOUNT HOLDER PROFILE:');
    buffer.writeln(
        '  Account Holder: ${user.name.isNotEmpty ? user.name : "N/A"}');
    buffer.writeln(
        '  Occupation    : ${user.occupation.isNotEmpty ? user.occupation : "N/A"}');
    buffer.writeln(
        '  Phone         : ${user.phone.isNotEmpty ? user.phone : "N/A"}');
    buffer.writeln(
        '  Address       : ${user.address.isNotEmpty ? user.address : "N/A"}');
    buffer.writeln(
        '  Primary Bank  : ${user.primaryBank.isNotEmpty ? user.primaryBank : "Not Set"}');
    buffer.writeln(
        '  Secondary Bank: ${user.secondaryBank.isNotEmpty ? user.secondaryBank : "Not Set"}');
    buffer.writeln(
        '  MFS Account   : ${user.mfs.isNotEmpty ? user.mfs : "Not Set"}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('MONTHLY FINANCIAL SUMMARY ($periodString):');
    buffer.writeln(
        '  Total Income:              +৳${totalIncome.toStringAsFixed(2)}');
    buffer.writeln(
        '  Total Expense:             -৳${totalExpense.toStringAsFixed(2)}');
    buffer.writeln(
        '  Total Savings/Investments:  ৳${totalSavings.toStringAsFixed(2)}');
    buffer.writeln(
        '  Net Monthly Flow:          ${netMonthlyFlow < 0 ? "-৳${netMonthlyFlow.abs().toStringAsFixed(2)}" : "৳${netMonthlyFlow.toStringAsFixed(2)}"}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('MONTHLY INCOME SOURCES:');
    if (sortedIncomeEntries.isEmpty) {
      buffer.writeln('  (No income records)');
    } else {
      for (var e in sortedIncomeEntries) {
        final pct = totalIncome > 0 ? (e.value / totalIncome * 100) : 0.0;
        buffer.writeln(
            '  - ${e.key.padRight(22)} ৳${e.value.toStringAsFixed(2).padLeft(10)} (${pct.toStringAsFixed(1)}%)');
      }
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('MONTHLY EXPENSE BREAKDOWN:');
    if (sortedExpenseEntries.isEmpty) {
      buffer.writeln('  (No expense records)');
    } else {
      for (var e in sortedExpenseEntries) {
        final pct = totalExpense > 0 ? (e.value / totalExpense * 100) : 0.0;
        buffer.writeln(
            '  - ${e.key.padRight(22)} ৳${e.value.toStringAsFixed(2).padLeft(10)} (${pct.toStringAsFixed(1)}%)');
      }
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('ANNUAL REPORT SUMMARY ($selectedReportYear):');
    buffer.writeln(
        '  Yearly Total Income :      +৳${yearlyIncome.toStringAsFixed(2)}');
    buffer.writeln(
        '  Yearly Total Expense:      -৳${yearlyExpense.toStringAsFixed(2)}');
    buffer.writeln(
        '  Yearly Total Savings:       ৳${yearlySavings.toStringAsFixed(2)}');
    buffer.writeln(
        '  Yearly Net Balance  :      ${yearlyNetBalance < 0 ? "-৳${yearlyNetBalance.abs().toStringAsFixed(2)}" : "৳${yearlyNetBalance.toStringAsFixed(2)}"}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('YEARLY MONTH-BY-MONTH BREAKDOWN ($selectedReportYear):');
    buffer.writeln('  Month    Income         Expense        Net Flow');
    for (int i = 0; i < 12; i++) {
      final inc = yearlyMonthlyIncomes[i];
      final exp = yearlyMonthlyExpenses[i];
      final net = inc - exp;
      if (inc > 0 || exp > 0) {
        buffer.writeln(
            '  ${monthLabels[i].padRight(8)} ৳${inc.toStringAsFixed(2).padRight(13)} ৳${exp.toStringAsFixed(2).padRight(13)} ${net < 0 ? "-৳${net.abs().toStringAsFixed(2)}" : "+৳${net.toStringAsFixed(2)}"}');
      }
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('YEARLY INCOME EARNED ($selectedReportYear):');
    if (sortedYearlyIncomeEntries.isEmpty) {
      buffer.writeln('  (No yearly income records)');
    } else {
      for (var e in sortedYearlyIncomeEntries) {
        final pct = yearlyIncome > 0 ? (e.value / yearlyIncome * 100) : 0.0;
        buffer.writeln(
            '  - ${e.key.padRight(22)} ৳${e.value.toStringAsFixed(2).padLeft(10)} (${pct.toStringAsFixed(1)}%)');
      }
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('YEARLY EXPENSE SPENT ($selectedReportYear):');
    if (sortedYearlyExpenseEntries.isEmpty) {
      buffer.writeln('  (No yearly expense records)');
    } else {
      for (var e in sortedYearlyExpenseEntries) {
        final pct = yearlyExpense > 0 ? (e.value / yearlyExpense * 100) : 0.0;
        buffer.writeln(
            '  - ${e.key.padRight(22)} ৳${e.value.toStringAsFixed(2).padLeft(10)} (${pct.toStringAsFixed(1)}%)');
      }
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('TRANSACTIONS LIST IN PERIOD (${periodTxs.length} items):');
    if (periodTxs.isEmpty) {
      buffer.writeln('  (No transactions recorded)');
    } else {
      for (var t in periodTxs) {
        final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
        buffer.writeln(
            '  [$dateStr] ${t.type.toUpperCase().padRight(8)} ${t.category.padRight(16)} ৳${t.amount.toStringAsFixed(2).padLeft(8)} (${t.account}) ${t.note}');
      }
    }
    buffer.writeln('========================================');
    buffer.writeln('Generated via PERFINAX Wealth Manager');

    final statementText = buffer.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate500.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Title and Print/Copy actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MONTHLY FINANCIAL STATEMENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            periodString,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "Annual Report: $selectedReportYear",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2DD4BF),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf_rounded,
                                color: Color(0xFF10B981), size: 22),
                            tooltip: 'Download PDF Report',
                            onPressed: () async {
                              AppToast.show(
                                context,
                                message: 'Generating PDF report...',
                                type: ToastType.info,
                                duration: const Duration(seconds: 1),
                              );
                              final savedPath = await PdfStatementService
                                  .exportAndDownloadPdf(
                                user: user,
                                periodTxs: periodTxs,
                                selectedMonth: selectedMonth,
                                selectedYear: selectedYear,
                                totalIncome: totalIncome,
                                totalExpense: totalExpense,
                                totalSavings: totalSavings,
                                netMonthlyFlow: netMonthlyFlow,
                                sortedIncomeEntries: sortedIncomeEntries,
                                sortedExpenseEntries: sortedExpenseEntries,
                                selectedReportYear: selectedReportYear,
                                yearlyIncome: yearlyIncome,
                                yearlyExpense: yearlyExpense,
                                yearlySavings: yearlySavings,
                                yearlyNetBalance: yearlyNetBalance,
                                yearlyMonthlyIncomes: yearlyMonthlyIncomes,
                                yearlyMonthlyExpenses: yearlyMonthlyExpenses,
                                sortedYearlyIncomeEntries:
                                    sortedYearlyIncomeEntries,
                                sortedYearlyExpenseEntries:
                                    sortedYearlyExpenseEntries,
                              );
                              if (context.mounted) {
                                AppToast.show(
                                  context,
                                  message: savedPath != null
                                      ? 'PDF downloaded to: $savedPath'
                                      : 'PDF report ready!',
                                  type: ToastType.success,
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF061714)),

                  // Scrollable statement body
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Profile summary block
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppColors.emerald.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name.isNotEmpty
                                    ? user.name
                                    : 'User Profile Unset',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Occupation: ${user.occupation.isNotEmpty ? user.occupation : "N/A"} • Phone: ${user.phone.isNotEmpty ? user.phone : "N/A"}',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.slate400),
                              ),
                              if (user.address.isNotEmpty)
                                Text('Address: ${user.address}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.slate400)),
                              const SizedBox(height: 4),
                              Text(
                                'Accounts: [P: ${user.primaryBank.isNotEmpty ? user.primaryBank : "None"}] [S: ${user.secondaryBank.isNotEmpty ? user.secondaryBank : "None"}] [MFS: ${user.mfs.isNotEmpty ? user.mfs : "None"}]',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF34D399),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 1: Monthly Financial Summary
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MONTHLY SUMMARY ($periodString)',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate300,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildModalLineRow(
                                  'Total Income:',
                                  '+৳${totalIncome.toStringAsFixed(2)}',
                                  const Color(0xFF34D399)),
                              _buildModalLineRow(
                                  'Total Expense:',
                                  '-৳${totalExpense.toStringAsFixed(2)}',
                                  const Color(0xFFFB7185)),
                              _buildModalLineRow(
                                  'Total Savings:',
                                  '৳${totalSavings.toStringAsFixed(2)}',
                                  const Color(0xFFC084FC)),
                              const Divider(height: 12),
                              _buildModalLineRow(
                                'Net Monthly Flow:',
                                netMonthlyFlow < 0
                                    ? '-৳${netMonthlyFlow.abs().toStringAsFixed(2)}'
                                    : '৳${netMonthlyFlow.toStringAsFixed(2)}',
                                netMonthlyFlow < 0
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFF34D399),
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Monthly Income Sources
                        const Text(
                          'MONTHLY INCOME SOURCES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34D399),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (sortedIncomeEntries.isEmpty)
                          const Text('No income transactions.',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.slate400))
                        else
                          ...sortedIncomeEntries.map((e) {
                            final pct = totalIncome > 0
                                ? (e.value / totalIncome * 100)
                                : 0.0;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key,
                                      style: const TextStyle(fontSize: 11)),
                                  Text(
                                    '+৳${e.value.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF34D399)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 14),

                        // Section 3: Monthly Expense Breakdown
                        const Text(
                          'MONTHLY EXPENSE BREAKDOWN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFB7185),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (sortedExpenseEntries.isEmpty)
                          const Text('No expense transactions.',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.slate400))
                        else
                          ...sortedExpenseEntries.map((e) {
                            final pct = totalExpense > 0
                                ? (e.value / totalExpense * 100)
                                : 0.0;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key,
                                      style: const TextStyle(fontSize: 11)),
                                  Text(
                                    '-৳${e.value.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFB7185)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 16),

                        // Section 4: Annual Report Summary
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2DD4BF)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ANNUAL REPORT SUMMARY ($selectedReportYear)',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2DD4BF),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildModalLineRow(
                                  'Yearly Income:',
                                  '+৳${yearlyIncome.toStringAsFixed(2)}',
                                  const Color(0xFF34D399)),
                              _buildModalLineRow(
                                  'Yearly Expense:',
                                  '-৳${yearlyExpense.toStringAsFixed(2)}',
                                  const Color(0xFFFB7185)),
                              _buildModalLineRow(
                                  'Yearly Savings:',
                                  '৳${yearlySavings.toStringAsFixed(2)}',
                                  const Color(0xFFC084FC)),
                              const Divider(height: 12),
                              _buildModalLineRow(
                                'Yearly Net Balance:',
                                yearlyNetBalance < 0
                                    ? '-৳${yearlyNetBalance.abs().toStringAsFixed(2)}'
                                    : '৳${yearlyNetBalance.toStringAsFixed(2)}',
                                yearlyNetBalance < 0
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFF38BDF8),
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 5: Yearly Cash Flow by Month (Jan-Dec)
                        const Text(
                          'YEARLY MONTH-BY-MONTH CASH FLOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF38BDF8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Month',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.slate400,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'Income',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF34D399),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'Expense',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFB7185),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 10),
                              ...List.generate(12, (i) {
                                final inc = yearlyMonthlyIncomes[i];
                                final exp = yearlyMonthlyExpenses[i];
                                if (inc == 0 && exp == 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2.5),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          monthLabels[i],
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          '+৳${inc.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF34D399),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          '-৳${exp.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFB7185),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (yearlyIncome == 0 && yearlyExpense == 0)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    'No monthly data for this year.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Section 6: Yearly Income Earned
                        const Text(
                          'YEARLY INCOME EARNED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34D399),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (sortedYearlyIncomeEntries.isEmpty)
                          const Text('No yearly income transactions.',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.slate400))
                        else
                          ...sortedYearlyIncomeEntries.map((e) {
                            final pct = yearlyIncome > 0
                                ? (e.value / yearlyIncome * 100)
                                : 0.0;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key,
                                      style: const TextStyle(fontSize: 11)),
                                  Text(
                                    '+৳${e.value.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF34D399)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 14),

                        // Section 7: Yearly Expense Spent
                        const Text(
                          'YEARLY EXPENSE SPENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFB7185),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (sortedYearlyExpenseEntries.isEmpty)
                          const Text('No yearly expense transactions.',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.slate400))
                        else
                          ...sortedYearlyExpenseEntries.map((e) {
                            final pct = yearlyExpense > 0
                                ? (e.value / yearlyExpense * 100)
                                : 0.0;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key,
                                      style: const TextStyle(fontSize: 11)),
                                  Text(
                                    '-৳${e.value.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFB7185)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 14),

                        // Section 8: Transactions in Period
                        Text(
                          'TRANSACTIONS IN PERIOD (${periodTxs.length})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (periodTxs.isEmpty)
                          const Text('No transactions recorded.',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.slate400))
                        else
                          ...periodTxs.map((t) {
                            final isInc = t.type == 'income' ||
                                t.category == 'Cash Received';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${t.category} (${t.type.toUpperCase()})",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${DateFormat('yyyy-MM-dd').format(t.date)} • ${t.account.toUpperCase()}${t.note.isNotEmpty ? ' • ${t.note}' : ''}",
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: AppColors.slate400),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${isInc ? '+' : '-'}৳${t.amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isInc
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFFFB7185),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            AppToast.show(
                              context,
                              message: 'Generating PDF report...',
                              type: ToastType.info,
                              duration: const Duration(seconds: 1),
                            );
                            final savedPath =
                                await PdfStatementService.exportAndDownloadPdf(
                              user: user,
                              periodTxs: periodTxs,
                              selectedMonth: selectedMonth,
                              selectedYear: selectedYear,
                              totalIncome: totalIncome,
                              totalExpense: totalExpense,
                              totalSavings: totalSavings,
                              netMonthlyFlow: netMonthlyFlow,
                              sortedIncomeEntries: sortedIncomeEntries,
                              sortedExpenseEntries: sortedExpenseEntries,
                              selectedReportYear: selectedReportYear,
                              yearlyIncome: yearlyIncome,
                              yearlyExpense: yearlyExpense,
                              yearlySavings: yearlySavings,
                              yearlyNetBalance: yearlyNetBalance,
                              yearlyMonthlyIncomes: yearlyMonthlyIncomes,
                              yearlyMonthlyExpenses: yearlyMonthlyExpenses,
                              sortedYearlyIncomeEntries:
                                  sortedYearlyIncomeEntries,
                              sortedYearlyExpenseEntries:
                                  sortedYearlyExpenseEntries,
                            );
                            if (context.mounted) {
                              AppToast.show(
                                context,
                                message: savedPath != null
                                    ? 'PDF downloaded to: $savedPath'
                                    : 'PDF report ready!',
                                type: ToastType.success,
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 16),
                          label: const Text(
                            'Download PDF',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: statementText));
                            Navigator.pop(ctx);
                            AppToast.show(
                              context,
                              message:
                                  'Comprehensive Statement for $periodString & $selectedReportYear copied to clipboard!',
                              type: ToastType.success,
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text(
                            'Copy Statement',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF064E3B),
                            foregroundColor: const Color(0xFF34D399),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          side: const BorderSide(color: AppColors.slate500),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Close',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalLineRow(String label, String value, Color valueColor,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 12 : 11,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 13 : 11,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getExpenseCategoryColor(String category, int index) {
    switch (category.toLowerCase().trim()) {
      case 'loan pay':
        return const Color(0xFF38BDF8); // cyan / sky blue
      case 'transport':
        return const Color(0xFF10B981); // emerald / green
      case 'bills':
        return const Color(0xFFF43F5E); // rose / coral red
      case 'food':
        return const Color(0xFFFBBF24); // amber
      case 'rent':
        return const Color(0xFF818CF8); // indigo
      case 'entertainment':
        return const Color(0xFFC084FC); // purple
      case 'subscription':
        return const Color(0xFF2DD4BF); // teal
      case 'fashion':
        return const Color(0xFFF472B6); // pink
      case 'house help':
        return const Color(0xFF34D399); // mint
      case 'family':
        return const Color(0xFFFB923C); // orange
      case 'child/medicine':
        return const Color(0xFFE879F9); // fuchsia
      default:
        const palette = [
          Color(0xFF10B981),
          Color(0xFFF43F5E),
          Color(0xFF38BDF8),
          Color(0xFFC084FC),
          Color(0xFFFBBF24),
          Color(0xFF2DD4BF),
          Color(0xFFF472B6),
          Color(0xFFFB923C),
          Color(0xFF818CF8),
          Color(0xFF34D399),
        ];
        return palette[index % palette.length];
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_categories.dart';
import '../../controllers/data_controller.dart';
import '../../models/transaction_item.dart';
import '../widgets/modal_selector.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/animated_empty_transactions.dart';
import '../widgets/app_toast.dart';

class DashboardTab extends StatefulWidget {
  final DataController dataController;
  final int selectedYear;
  final int selectedMonth;
  final ScrollController homeScrollController;
  final VoidCallback onDataChanged;

  const DashboardTab({
    super.key,
    required this.dataController,
    required this.selectedYear,
    required this.selectedMonth,
    required this.homeScrollController,
    required this.onDataChanged,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Transaction List Filters & Pagination
  String _txCatFilter = 'ALL';
  final String _sortBy = 'date';
  bool _sortAscending = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  void _openAddTransactionModal() {
    showAddTransactionModal(
      context: context,
      dataController: widget.dataController,
      onTransactionAdded: () {
        widget.onDataChanged();
        setState(() {});
      },
    );
  }

  void _openEditTransactionModal(TransactionItem item) {
    showAddTransactionModal(
      context: context,
      dataController: widget.dataController,
      transactionToEdit: item,
      onTransactionAdded: () {
        widget.onDataChanged();
        setState(() {});
      },
    );
  }

  void _confirmDeleteTransaction(TransactionItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.rose400.withValues(alpha: 0.3)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.rose400, size: 22),
              SizedBox(width: 8),
              Text(
                'Delete Transaction?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this ${item.type.toUpperCase()} entry for '${item.category}' (৳${item.amount.toStringAsFixed(2)})?\nThis action cannot be undone.",
            style: const TextStyle(
              color: AppColors.slate300,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.slate500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('CANCEL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.dataController.removeTransaction(item.id);
                widget.onDataChanged();
                AppToast.show(
                  context,
                  message: 'Transaction deleted',
                  type: ToastType.delete,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('DELETE',
                  style:
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.dataController.userProfile;
    final transactions = widget.dataController.transactions;

    // Filter transactions to selected month
    final periodTxs = transactions
        .where((t) =>
            t.date.year == widget.selectedYear &&
            t.date.month == (widget.selectedMonth + 1))
        .toList();

    double primary = 0, secondary = 0, mfs = 0, cash = 0, savings = 0;

    for (var t in periodTxs) {
      if (t.type == 'income') {
        if (t.account == 'primary') primary += t.amount;
        if (t.account == 'secondary') secondary += t.amount;
        if (t.account == 'mfs') mfs += t.amount;
        if (t.account == 'cash') cash += t.amount;
      } else if (t.type == 'expense') {
        if (t.account == 'primary') primary -= t.amount;
        if (t.account == 'secondary') secondary -= t.amount;
        if (t.account == 'mfs') mfs -= t.amount;
        if (t.account == 'cash') cash -= t.amount;
      } else if (t.type == 'saving') {
        if (t.account == 'primary') primary -= t.amount;
        if (t.account == 'secondary') secondary -= t.amount;
        if (t.account == 'mfs') mfs -= t.amount;
        if (t.account == 'cash') cash -= t.amount;
        savings += t.amount;
      } else if (t.type == 'transfer') {
        if (t.category == 'Cash Withdrawal') {
          if (t.account == 'secondary') {
            secondary -= t.amount;
          } else {
            primary -= t.amount;
          }
          cash += t.amount;
        } else if (t.category == 'Mobile Banking Transfer') {
          if (t.account == 'cash') {
            cash -= t.amount;
          } else {
            primary -= t.amount;
          }
          mfs += t.amount;
        } else if (t.category == 'Cash Received') {
          if (t.account == 'mfs') {
            mfs += t.amount;
          } else if (t.account == 'primary') {
            primary += t.amount;
          } else {
            cash += t.amount;
          }
        }
      }
    }

    double periodIncome = 0;
    double periodExpense = 0;
    double periodSavings = 0;

    for (var t in periodTxs) {
      if (t.type == 'income' || t.category == 'Cash Received') {
        periodIncome += t.amount;
      } else if (t.type == 'expense') {
        periodExpense += t.amount;
      } else if (t.type == 'saving') {
        periodSavings += t.amount;
      }
    }

    final double remainingBalance = primary + secondary + mfs + cash;

    // Filter & Sorting for Transactions list
    var filteredList = periodTxs;
    if (_txCatFilter != 'ALL') {
      filteredList =
          filteredList.where((t) => t.category == _txCatFilter).toList();
    }
    filteredList.sort((a, b) {
      int cmp = _sortBy == 'amount'
          ? a.amount.compareTo(b.amount)
          : a.date.compareTo(b.date);
      return _sortAscending ? cmp : -cmp;
    });

    final int totalPages = (filteredList.length / _itemsPerPage).ceil() == 0
        ? 1
        : (filteredList.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages) _currentPage = totalPages - 1;
    if (_currentPage < 0) _currentPage = 0;

    final paginatedList = filteredList
        .skip(_currentPage * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    final String pBankLabel =
        user.primaryBank.isNotEmpty ? user.primaryBank : 'Primary Bank';
    final String sBankLabel =
        user.secondaryBank.isNotEmpty ? user.secondaryBank : 'Sec. Bank';
    final String mfsBankLabel =
        user.mfs.isNotEmpty ? user.mfs : 'Mobile Bank';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomScrollView(
        controller: widget.homeScrollController,
        slivers: [
          // 1. REMAINING BALANCE CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 2)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REMAINING BALANCE (SELECTED MONTH)',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34D399),
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('৳${remainingBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: remainingBalance < 0
                                    ? AppColors.rose400
                                    : Colors.white)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('Month Isolated',
                              style: TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        _buildBalanceMiniCard(
                            pBankLabel, primary, AppColors.sky400),
                        _buildBalanceMiniCard(
                            sBankLabel, secondary, AppColors.teal300),
                        _buildBalanceMiniCard(
                            mfsBankLabel, mfs, AppColors.pink400),
                        _buildBalanceMiniCard(
                            'Cash Hand', cash, const Color(0xFF10B981)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Invested / Saved',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate300)),
                          Text('৳${savings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.purple400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. TRANSACTIONS LIST HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('LATEST TRANSACTIONS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.5)),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          final allCats = [
                            'ALL',
                            ...AppCategories.categories['expense']!,
                            ...AppCategories.categories['income']!,
                            ...AppCategories.categories['saving']!,
                            ...AppCategories.categories['transfer']!
                          ].map((e) => {'label': e, 'value': e}).toList();
                          showModalSelector(
                              context: context,
                              title: 'Filter Category',
                              options: allCats,
                              currentValue: _txCatFilter,
                              onSelect: (val) =>
                                  setState(() => _txCatFilter = val));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(_txCatFilter,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(
                            _sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 16,
                            color: const Color(0xFF10B981)),
                        onPressed: () =>
                            setState(() => _sortAscending = !_sortAscending),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. TRANSACTIONS LIST / ANIMATED EMPTY STATE
          filteredList.isEmpty
              ? SliverToBoxAdapter(
                  child: AnimatedEmptyTransactions(
                    onAddTap: _openAddTransactionModal,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final item = filteredList[idx];
                      final isInc = item.type == 'income' ||
                          item.category == 'Cash Received';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.emerald
                                    .withValues(alpha: 0.2))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _openEditTransactionModal(item),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.category,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                              color: isInc
                                                  ? AppColors.emerald
                                                      .withValues(alpha: 0.2)
                                                  : AppColors.rose
                                                      .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: Text(item.type.toUpperCase(),
                                              style: TextStyle(
                                                  color: isInc
                                                      ? const Color(0xFF10B981)
                                                      : AppColors.rose400,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${DateFormat('yyyy-MM-dd').format(item.date)} • ${item.account.toUpperCase()} ${item.note.isNotEmpty ? '• ${item.note}' : ''}",
                                      style: const TextStyle(
                                          fontSize: 9, color: AppColors.slate400),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Text(
                                    "${isInc ? '+' : '-'}৳${item.amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: isInc
                                            ? const Color(0xFF10B981)
                                            : AppColors.rose400)),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(left: 4),
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 14, color: AppColors.slate400),
                                  tooltip: 'Edit Transaction',
                                  onPressed: () =>
                                      _openEditTransactionModal(item),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(left: 4),
                                  icon: const Icon(Icons.close,
                                      size: 14, color: AppColors.slate500),
                                  tooltip: 'Delete Transaction',
                                  onPressed: () =>
                                      _confirmDeleteTransaction(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: paginatedList.length,
                  ),
                ),

          // 4. PAGINATION, SELECTED PERIOD SUMMARY & DEVICE STORAGE OPTIONS
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildPaginationBar(filteredList.length, totalPages),
                const SizedBox(height: 16),
                _buildSelectedPeriodSummaryCard(
                    periodIncome, periodExpense, periodSavings),
                const SizedBox(height: 16),
                _buildDeviceStorageOptionsCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceMiniCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 9, color: AppColors.slate400),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('৳${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(int totalItems, int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} of $totalPages ($totalItems items)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.slate400
                  : const Color(0xFF64748B),
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentPage > 0
                          ? AppColors.emerald.withValues(alpha: 0.4)
                          : AppColors.slate500.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Prev',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _currentPage > 0
                          ? Theme.of(context).colorScheme.onSurface
                          : AppColors.slate500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentPage < totalPages - 1
                          ? AppColors.emerald.withValues(alpha: 0.4)
                          : AppColors.slate500.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _currentPage < totalPages - 1
                          ? Theme.of(context).colorScheme.onSurface
                          : AppColors.slate500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPeriodSummaryCard(
      double periodIncome, double periodExpense, double periodSavings) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'SELECTED PERIOD SUMMARY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('INCOME',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981))),
                    const SizedBox(height: 4),
                    Text('+৳${periodIncome.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981))),
                  ],
                ),
              ),
              Container(
                  height: 30,
                  width: 1,
                  color: AppColors.emerald.withValues(alpha: 0.2)),
              Expanded(
                child: Column(
                  children: [
                    const Text('EXPENSE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.rose400)),
                    const SizedBox(height: 4),
                    Text('-৳${periodExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.rose400)),
                  ],
                ),
              ),
              Container(
                  height: 30,
                  width: 1,
                  color: AppColors.emerald.withValues(alpha: 0.2)),
              Expanded(
                child: Column(
                  children: [
                    const Text('SAVINGS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC084FC))),
                    const SizedBox(height: 4),
                    Text('৳${periodSavings.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC084FC))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStorageOptionsCard() {
    return Container(
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
            'DEVICE STORAGE OPTIONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _handleBackupFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Center(
                      child: Text(
                        'Backup File',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _handleRestoreData,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        'Restore Data',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackupFile() async {
    try {
      final jsonString = widget.dataController.exportBackupJson();
      final fileName =
          'perfinax_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      Uri? savedUri;

      try {
        savedUri = await FilePicker.saveFile(
          dialogTitle: 'Download PERFINAX Backup JSON',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(jsonString),
        );
      } catch (_) {}

      String? savedPath;
      if (savedUri != null) {
        try {
          savedPath = savedUri.toFilePath();
        } catch (_) {
          savedPath = savedUri.path;
        }
      }

      if (savedPath != null && savedPath.isNotEmpty) {
        final file = File(savedPath);
        if (!file.existsSync() || file.lengthSync() == 0) {
          await file.writeAsString(jsonString);
        }
      } else {
        final docsDir = await getApplicationDocumentsDirectory();
        final file = File('${docsDir.path}/$fileName');
        await file.writeAsString(jsonString);
        savedPath = file.path;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: AppColors.emerald.withValues(alpha: 0.3)),
            ),
            title: const Row(
              children: [
                Icon(Icons.download_done_rounded,
                    color: Color(0xFF10B981), size: 22),
                SizedBox(width: 8),
                Text(
                  'Backup File Saved',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your PERFINAX data backup file has been generated and downloaded successfully.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_rounded,
                          color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (savedPath != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                savedPath,
                                style: const TextStyle(
                                    fontSize: 9, color: AppColors.slate400),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonString));
                  AppToast.show(
                    context,
                    message: 'Backup JSON copied to Clipboard!',
                    type: ToastType.success,
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('COPY JSON', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: const BorderSide(color: AppColors.slate500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('OK',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Error downloading backup file: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _handleRestoreData() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFiles.isEmpty) return;

      final pickedFile = pickedFiles.first;
      String? jsonContent;

      try {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.isNotEmpty) {
          jsonContent = utf8.decode(bytes);
        }
      } catch (_) {}

      if ((jsonContent == null || jsonContent.isEmpty) &&
          pickedFile.path != null &&
          pickedFile.path!.isNotEmpty) {
        final file = File(pickedFile.path!);
        if (file.existsSync()) {
          jsonContent = await file.readAsString();
        }
      }

      if (jsonContent == null || jsonContent.trim().isEmpty) {
        if (!mounted) return;
        AppToast.show(
          context,
          message: 'Selected JSON file is empty or unreadable.',
          type: ToastType.error,
        );
        return;
      }

      final success = await widget.dataController.importBackupJson(jsonContent);

      if (!mounted) return;

      if (success) {
        widget.onDataChanged();
        setState(() {});
        AppToast.show(
          context,
          message: 'Data restored successfully from "${pickedFile.name}"!',
          type: ToastType.success,
        );
      } else {
        AppToast.show(
          context,
          message: 'Failed to restore data. Invalid PERFINAX JSON file format.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Error uploading restore file: $e',
        type: ToastType.error,
      );
    }
  }
}

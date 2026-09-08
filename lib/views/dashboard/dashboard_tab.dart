import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_categories.dart';
import '../../controllers/data_controller.dart';
import '../../models/transaction_item.dart';
import '../widgets/modal_selector.dart';

class DashboardTab extends StatefulWidget {
  final DataController dataController;
  final int selectedYear;
  final int selectedMonth;
  final ScrollController homeScrollController;
  final GlobalKey inputFormKey;
  final VoidCallback onDataChanged;

  const DashboardTab({
    super.key,
    required this.dataController,
    required this.selectedYear,
    required this.selectedMonth,
    required this.homeScrollController,
    required this.inputFormKey,
    required this.onDataChanged,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Form State
  String _formType = 'expense';
  String _selectedCategory = '';
  String _selectedAccount = 'primary';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isRecurring = false;

  // Transaction List Filters
  String _txCatFilter = 'ALL';
  final String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setFormType(String type) {
    setState(() {
      _formType = type;
      if (type == 'income') {
        _selectedCategory = 'Salary';
      } else {
        _selectedCategory = '';
      }
    });
  }

  void _submitTransaction() {
    if (_amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }

    final double amount = double.parse(_amountController.text);
    final tx = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _formType,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      account: _selectedAccount,
      note: _noteController.text.trim(),
      recurring: _isRecurring,
    );

    widget.dataController.addTransaction(tx);
    widget.onDataChanged();

    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _setFormType(_formType);
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction recorded successfully!')));
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

    final String pBankLabel =
        user.primaryBank.isNotEmpty ? user.primaryBank : 'Primary Bank';
    final String sBankLabel =
        user.secondaryBank.isNotEmpty ? user.secondaryBank : 'Sec. Bank';
    final String mfsBankLabel =
        user.mfs.isNotEmpty ? user.mfs : 'Mobile Bank';

    return SingleChildScrollView(
      controller: widget.homeScrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remaining Balance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A221C),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
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
                      color: const Color(0xFF030A08),
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
          const SizedBox(height: 16),

          // Add Transaction Form Card Keyed for Auto-scroll
          Container(
            key: widget.inputFormKey,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A221C),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Beautified Segmented Pill Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF030A08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.2))),
                  child: Row(
                    children: [
                      _buildPillTab('expense', '💸 Expense', AppColors.emerald),
                      _buildPillTab('income', '💰 Income', Colors.teal),
                      _buildPillTab('saving', '💎 Savings', Colors.purple),
                      _buildPillTab('transfer', '🔄 Cash&MB', AppColors.sky),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AMOUNT',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              filled: true,
                              fillColor: const Color(0xFF030A08),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CATEGORY',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              final opts = AppCategories.categories[_formType]!
                                  .map((e) => {'label': e, 'value': e})
                                  .toList();
                              showModalSelector(
                                  context: context,
                                  title: 'Select Category',
                                  options: opts,
                                  currentValue: _selectedCategory,
                                  onSelect: (val) => setState(
                                      () => _selectedCategory = val));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF030A08),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(
                                          _selectedCategory.isNotEmpty
                                              ? _selectedCategory
                                              : 'Tap to Select',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedCategory.isNotEmpty
                                                  ? Colors.white
                                                  : AppColors.slate500),
                                          overflow: TextOverflow.ellipsis)),
                                  const Icon(Icons.arrow_drop_down,
                                      size: 16, color: AppColors.slate400),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030));
                              if (d != null) setState(() => _selectedDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF030A08),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                  DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACCOUNT',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              final pBank = user.primaryBank.isNotEmpty
                                  ? user.primaryBank
                                  : 'Primary Bank';
                              final sBank = user.secondaryBank.isNotEmpty
                                  ? user.secondaryBank
                                  : 'Secondary Bank';
                              final mBank = user.mfs.isNotEmpty
                                  ? user.mfs
                                  : 'Mobile Banking';
                              final opts = [
                                {'label': pBank, 'value': 'primary'},
                                {'label': sBank, 'value': 'secondary'},
                                {'label': mBank, 'value': 'mfs'},
                                {'label': 'Cash in Hand', 'value': 'cash'},
                              ];
                              showModalSelector(
                                  context: context,
                                  title: 'Select Account',
                                  options: opts,
                                  currentValue: _selectedAccount,
                                  onSelect: (val) => setState(
                                      () => _selectedAccount = val));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF030A08),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      _selectedAccount == 'primary'
                                          ? (user.primaryBank.isNotEmpty
                                              ? user.primaryBank
                                              : 'Primary')
                                          : _selectedAccount == 'secondary'
                                              ? (user.secondaryBank.isNotEmpty
                                                  ? user.secondaryBank
                                                  : 'Sec Bank')
                                              : _selectedAccount == 'mfs'
                                                  ? (user.mfs.isNotEmpty
                                                      ? user.mfs
                                                      : 'Mobile')
                                                  : 'Cash',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis),
                                  const Icon(Icons.arrow_drop_down,
                                      size: 16, color: AppColors.slate400),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text('NOTE / COMMENT',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34D399))),
                const SizedBox(height: 4),
                TextField(
                  controller: _noteController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Write comment...',
                    filled: true,
                    fillColor: const Color(0xFF030A08),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Checkbox(
                      value: _isRecurring,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) =>
                          setState(() => _isRecurring = val ?? false),
                    ),
                    const Expanded(
                        child: Text(
                            'Recurring Transaction (Auto-log next month)',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate300))),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('LOG ${_formType.toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transactions List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LATEST TRANSACTIONS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate300,
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
                          color: const Color(0xFF0A221C),
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
          const SizedBox(height: 8),

          filteredList.isEmpty
              ? const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No matching transactions in this month.',
                          style: TextStyle(
                              color: AppColors.slate500, fontSize: 11))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, idx) {
                    final item = filteredList[idx];
                    final isInc = item.type == 'income' ||
                        item.category == 'Cash Received';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF0A221C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.emerald
                                  .withValues(alpha: 0.2))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
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
                                padding: const EdgeInsets.only(left: 6),
                                icon: const Icon(Icons.close,
                                    size: 14, color: AppColors.slate500),
                                onPressed: () {
                                  widget.dataController
                                      .removeTransaction(item.id);
                                  widget.onDataChanged();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPillTab(String type, String label, Color color) {
    final isSel = _formType == type;
    return Expanded(
      child: InkWell(
        onTap: () => _setFormType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF064E3B) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSel ? Border.all(color: const Color(0xFF10B981)) : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isSel ? Colors.white : AppColors.slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceMiniCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color(0xFF030A08),
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
}

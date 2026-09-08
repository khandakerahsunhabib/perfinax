import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_categories.dart';
import '../../controllers/data_controller.dart';
import '../../models/transaction_item.dart';
import 'modal_selector.dart';

void showAddTransactionModal({
  required BuildContext context,
  required DataController dataController,
  required VoidCallback onTransactionAdded,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0A221C),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTransactionModalContent(
          dataController: dataController,
          onTransactionAdded: onTransactionAdded,
        ),
      );
    },
  );
}

class AddTransactionModalContent extends StatefulWidget {
  final DataController dataController;
  final VoidCallback onTransactionAdded;

  const AddTransactionModalContent({
    super.key,
    required this.dataController,
    required this.onTransactionAdded,
  });

  @override
  State<AddTransactionModalContent> createState() =>
      _AddTransactionModalContentState();
}

class _AddTransactionModalContentState
    extends State<AddTransactionModalContent> {
  String _formType = 'expense';
  String _selectedCategory = '';
  String _selectedAccount = 'primary';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isRecurring = false;

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
    widget.onTransactionAdded();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction recorded successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.dataController.userProfile;

    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                        color: Color(0xFF10B981), size: 22),
                    SizedBox(width: 8),
                    Text('LOG TRANSACTION',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.slate400),
                ),
              ],
            ),
            const Divider(color: Color(0xFF061714)),
            const SizedBox(height: 8),

            // Segmented Pill Tabs
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
            const SizedBox(height: 14),

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
                              onSelect: (val) =>
                                  setState(() => _selectedCategory = val));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF030A08),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
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
                              onSelect: (val) =>
                                  setState(() => _selectedAccount = val));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFF030A08),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    child: Text('Recurring Transaction (Auto-log next month)',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate300))),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
}

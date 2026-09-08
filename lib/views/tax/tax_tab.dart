import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/data_controller.dart';
import '../../controllers/tax_controller.dart';
import '../widgets/modal_selector.dart';

class TaxTab extends StatefulWidget {
  final DataController dataController;

  const TaxTab({
    super.key,
    required this.dataController,
  });

  @override
  State<TaxTab> createState() => _TaxTabState();
}

class _TaxTabState extends State<TaxTab> {
  String _taxAY = 'AY 2025-2026';
  double _taxCategoryThreshold = 375000.0;
  String _taxCategoryLabel = 'General Male (3.75L Exemption)';
  final bool _taxIsFirstTime = false;

  final TextEditingController _taxSalaryController = TextEditingController();
  final TextEditingController _taxBusinessController = TextEditingController();
  final TextEditingController _taxInvestmentController = TextEditingController();
  final TextEditingController _taxAitController = TextEditingController();

  @override
  void dispose() {
    _taxSalaryController.dispose();
    _taxBusinessController.dispose();
    _taxInvestmentController.dispose();
    _taxAitController.dispose();
    super.dispose();
  }

  void _autoPullTaxIncome() {
    final pulled = TaxController.autoPullTaxIncome(
      ay: _taxAY,
      transactions: widget.dataController.transactions,
    );

    final salary = pulled['salary']!;
    final business = pulled['business']!;
    final investment = pulled['investment']!;

    _taxSalaryController.text = salary > 0 ? salary.toStringAsFixed(2) : '';
    _taxBusinessController.text = business > 0 ? business.toStringAsFixed(2) : '';
    _taxInvestmentController.text = investment > 0 ? investment.toStringAsFixed(2) : '';
    setState(() {});
  }

  void _openModalTaxAY() {
    final opts = [
      {'label': 'AY 2025-2026', 'value': 'AY 2025-2026'},
      {'label': 'AY 2026-2027', 'value': 'AY 2026-2027'},
    ];
    showModalSelector(
      context: context,
      title: 'Select Assessment Year',
      options: opts,
      currentValue: _taxAY,
      onSelect: (val) {
        setState(() {
          _taxAY = val;
          _autoPullTaxIncome();
        });
      },
    );
  }

  void _openModalTaxCategory() {
    final opts = [
      {'label': 'General Male (3.75L Exemption)', 'value': '375000'},
      {'label': 'Female & Seniors 65+ (4.00L Exemption)', 'value': '400000'},
      {'label': 'Third Gender & Differently Abled (4.75L Exemption)', 'value': '475000'},
      {'label': 'Gazetted Freedom Fighters (5.00L Exemption)', 'value': '500000'},
    ];
    showModalSelector(
      context: context,
      title: 'Select Tax Category',
      options: opts,
      currentValue: _taxCategoryThreshold.toInt().toString(),
      onSelect: (val) {
        final double thresh = double.tryParse(val) ?? 375000.0;
        String label = 'General Male (3.75L Exemption)';
        if (thresh == 400000.0) label = 'Female & Seniors 65+ (4.00L Exemption)';
        if (thresh == 475000.0) label = 'Third Gender & Differently Abled (4.75L Exemption)';
        if (thresh == 500000.0) label = 'Gazetted Freedom Fighters (5.00L Exemption)';
        setState(() {
          _taxCategoryThreshold = thresh;
          _taxCategoryLabel = label;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double salary = double.tryParse(_taxSalaryController.text) ?? 0.0;
    final double business = double.tryParse(_taxBusinessController.text) ?? 0.0;
    final double investment = double.tryParse(_taxInvestmentController.text) ?? 0.0;
    final double ait = double.tryParse(_taxAitController.text) ?? 0.0;

    final taxRes = TaxController.calculateTaxResults(
      salary: salary,
      business: business,
      investment: investment,
      ait: ait,
      categoryThreshold: _taxCategoryThreshold,
      isFirstTime: _taxIsFirstTime,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const Text('NBR INCOME TAX ACT 2023 & FINANCE ACT',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('Income TAX Calculator',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _openModalTaxAY,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(_taxAY,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _openModalTaxCategory,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(_taxCategoryLabel,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
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
                          const Text('FISCAL SALARY INCOME',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                          const SizedBox(height: 2),
                          TextField(
                            controller: _taxSalaryController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                                hintText: '0.00',
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(10)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('FISCAL BUSINESS INCOME',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                          const SizedBox(height: 2),
                          TextField(
                            controller: _taxBusinessController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                                hintText: '0.00',
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(10)),
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
                          const Text('INVESTMENT REBATE',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                          const SizedBox(height: 2),
                          TextField(
                            controller: _taxInvestmentController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                                hintText: 'DPS/Stocks',
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(10)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ADVANCE AIT / TDS PAID',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                          const SizedBox(height: 2),
                          TextField(
                            controller: _taxAitController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                                hintText: 'AIT Paid',
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(10)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _autoPullTaxIncome,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      foregroundColor: const Color(0xFF10B981),
                      minimumSize: const Size(double.infinity, 36)),
                  child: const Text(
                      '⚡ PULL INCOME FROM FISCAL WINDOW (JULY–JUNE)',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),

                // Assessment Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _buildTaxLineRow('Total Gross Income:',
                          '৳${taxRes['gross']!.toStringAsFixed(2)}', Theme.of(context).colorScheme.onSurface),
                      _buildTaxLineRow(
                          'Less: Salary Exemption (1/3rd or Max 4.5L):',
                          '-৳${taxRes['exemption']!.toStringAsFixed(2)}',
                          AppColors.rose400),
                      _buildTaxLineRow(
                          'Net Taxable Income:',
                          '৳${taxRes['taxable']!.toStringAsFixed(2)}',
                          const Color(0xFF10B981)),
                      _buildTaxLineRow(
                          'Gross Calculated Tax:',
                          '৳${taxRes['grossTax']!.toStringAsFixed(2)}',
                          Theme.of(context).colorScheme.onSurface),
                      _buildTaxLineRow(
                          'Less: Investment Tax Rebate:',
                          '-৳${taxRes['rebate']!.toStringAsFixed(2)}',
                          const Color(0xFF10B981)),
                      _buildTaxLineRow(
                          'Less: Advance AIT / TDS Paid:',
                          '-৳${taxRes['ait']!.toStringAsFixed(2)}',
                          const Color(0xFF10B981)),
                      Divider(color: Theme.of(context).dividerColor),
                      _buildTaxLineRow(
                          'Final Payable Tax:',
                          '৳${taxRes['finalTax']!.toStringAsFixed(2)}',
                          const Color(0xFF10B981),
                          isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxLineRow(String label, String value, Color color,
      {bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: isBold
                      ? Theme.of(context).colorScheme.onSurface
                      : (isDark ? AppColors.slate300 : const Color(0xFF334155)),
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontSize: isBold ? 14 : 11,
                  color: color,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

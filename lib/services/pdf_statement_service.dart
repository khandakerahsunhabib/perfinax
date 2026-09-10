import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/app_categories.dart';
import '../models/transaction_item.dart';
import '../models/user_profile.dart';

class PdfStatementService {
  static const PdfColor emerald = PdfColor.fromInt(0xFF10B981);
  static const PdfColor darkEmerald = PdfColor.fromInt(0xFF064E3B);
  static const PdfColor incomeGreen = PdfColor.fromInt(0xFF059669);
  static const PdfColor expenseRose = PdfColor.fromInt(0xFFE11D48);
  static const PdfColor savingsPurple = PdfColor.fromInt(0xFF9333EA);
  static const PdfColor netBlue = PdfColor.fromInt(0xFF0284C7);
  static const PdfColor textDark = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor borderLight = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor bgMuted = PdfColor.fromInt(0xFFF8FAFC);

  /// Generates the raw PDF bytes for the comprehensive financial statement
  static Future<Uint8List> generateStatementPdf({
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
  }) async {
    final pdf = pw.Document(
      title: 'PERFINAX Financial Statement',
      author: 'PERFINAX Wealth Manager',
    );

    final monthName = AppCategories.months[selectedMonth];
    final periodString = "$monthName $selectedYear";
    final generatedDate =
        DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    const monthNames = [
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: emerald, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PERFINAX FINANCIAL STATEMENT',
                      style: const pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: darkEmerald,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Period: $periodString | Annual Report: $selectedReportYear',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: $generatedDate',
                      style: const pw.TextStyle(fontSize: 8, color: textMuted),
                    ),
                    pw.Text(
                      'Status: Official Statement',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: incomeGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderLight, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'PERFINAX Personal Finance and Tax Management - Confidential',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // 1. Account Holder Profile Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: bgMuted,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderLight),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ACCOUNT HOLDER INFORMATION',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: emerald,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          user.name.isNotEmpty ? user.name : 'Account Profile',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Occupation: ${user.occupation.isNotEmpty ? user.occupation : "N/A"} | Phone: ${user.phone.isNotEmpty ? user.phone : "N/A"}',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: textMuted,
                          ),
                        ),
                        if (user.address.isNotEmpty)
                          pw.Text(
                            'Address: ${user.address}',
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'BANKING ACCOUNTS',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: emerald,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Primary: ${user.primaryBank.isNotEmpty ? user.primaryBank : "Not Set"}',
                        style: const pw.TextStyle(fontSize: 8.5, color: textDark),
                      ),
                      pw.Text(
                        'Secondary: ${user.secondaryBank.isNotEmpty ? user.secondaryBank : "Not Set"}',
                        style: const pw.TextStyle(fontSize: 8.5, color: textDark),
                      ),
                      pw.Text(
                        'MFS: ${user.mfs.isNotEmpty ? user.mfs : "Not Set"}',
                        style: const pw.TextStyle(fontSize: 8.5, color: textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 2. Monthly Financial Summary Block
            pw.Text(
              '1. MONTHLY FINANCIAL SUMMARY ($periodString)',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: darkEmerald,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                _buildSummaryBox(
                  'TOTAL INCOME',
                  '+BDT ${totalIncome.toStringAsFixed(2)}',
                  incomeGreen,
                ),
                pw.SizedBox(width: 8),
                _buildSummaryBox(
                  'TOTAL EXPENSE',
                  '-BDT ${totalExpense.toStringAsFixed(2)}',
                  expenseRose,
                ),
                pw.SizedBox(width: 8),
                _buildSummaryBox(
                  'SAVINGS / INVESTMENTS',
                  'BDT ${totalSavings.toStringAsFixed(2)}',
                  savingsPurple,
                ),
                pw.SizedBox(width: 8),
                _buildSummaryBox(
                  'NET MONTHLY FLOW',
                  netMonthlyFlow < 0
                      ? '-BDT ${netMonthlyFlow.abs().toStringAsFixed(2)}'
                      : 'BDT ${netMonthlyFlow.toStringAsFixed(2)}',
                  netMonthlyFlow < 0 ? expenseRose : incomeGreen,
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 3. Monthly Income and Expense Side-by-Side Tables
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Monthly Income Breakdown
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MONTHLY INCOME SOURCES',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: incomeGreen,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (sortedIncomeEntries.isEmpty)
                        pw.Text('No income records.',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: textMuted))
                      else
                        pw.Table(
                          border: pw.TableBorder.all(
                              color: borderLight, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration:
                                  const pw.BoxDecoration(color: bgMuted),
                              children: [
                                _tableHeader('Category'),
                                _tableHeader('Amount', align: pw.TextAlign.right),
                                _tableHeader('Share', align: pw.TextAlign.right),
                              ],
                            ),
                            ...sortedIncomeEntries.map((e) {
                              final pct = totalIncome > 0
                                  ? (e.value / totalIncome * 100)
                                  : 0.0;
                              return pw.TableRow(
                                children: [
                                  _tableCell(e.key),
                                  _tableCell('+BDT ${e.value.toStringAsFixed(2)}',
                                      align: pw.TextAlign.right,
                                      color: incomeGreen,
                                      bold: true),
                                  _tableCell('${pct.toStringAsFixed(1)}%',
                                      align: pw.TextAlign.right),
                                ],
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                // Monthly Expense Breakdown
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MONTHLY EXPENSE BREAKDOWN',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: expenseRose,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (sortedExpenseEntries.isEmpty)
                        pw.Text('No expense records.',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: textMuted))
                      else
                        pw.Table(
                          border: pw.TableBorder.all(
                              color: borderLight, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration:
                                  const pw.BoxDecoration(color: bgMuted),
                              children: [
                                _tableHeader('Category'),
                                _tableHeader('Amount', align: pw.TextAlign.right),
                                _tableHeader('Share', align: pw.TextAlign.right),
                              ],
                            ),
                            ...sortedExpenseEntries.map((e) {
                              final pct = totalExpense > 0
                                  ? (e.value / totalExpense * 100)
                                  : 0.0;
                              return pw.TableRow(
                                children: [
                                  _tableCell(e.key),
                                  _tableCell('-BDT ${e.value.toStringAsFixed(2)}',
                                      align: pw.TextAlign.right,
                                      color: expenseRose,
                                      bold: true),
                                  _tableCell('${pct.toStringAsFixed(1)}%',
                                      align: pw.TextAlign.right),
                                ],
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // 4. Annual Analytics Report Block
            pw.Text(
              '2. ANNUAL FINANCIAL REPORT ($selectedReportYear)',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: darkEmerald,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                _buildSummaryBox(
                  'YEARLY INCOME',
                  '+BDT ${yearlyIncome.toStringAsFixed(2)}',
                  incomeGreen,
                ),
                pw.SizedBox(width: 8),
                _buildSummaryBox(
                  'YEARLY EXPENSE',
                  '-BDT ${yearlyExpense.toStringAsFixed(2)}',
                  expenseRose,
                ),
                pw.SizedBox(width: 8),
                _buildSummaryBox(
                  'YEARLY SAVINGS',
                  'BDT ${yearlySavings.toStringAsFixed(2)}',
                  savingsPurple,
                ),
                pw.SizedBox(width: 8),
                _buildSummaryBox(
                  'YEARLY NET BALANCE',
                  yearlyNetBalance < 0
                      ? '-BDT ${yearlyNetBalance.abs().toStringAsFixed(2)}'
                      : 'BDT ${yearlyNetBalance.toStringAsFixed(2)}',
                  yearlyNetBalance < 0 ? expenseRose : netBlue,
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 5. Month-by-Month Cash Flow Table (Jan-Dec)
            pw.Text(
              'YEARLY MONTH-BY-MONTH CASH FLOW ($selectedReportYear)',
              style: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: netBlue,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: borderLight, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: bgMuted),
                  children: [
                    _tableHeader('Month'),
                    _tableHeader('Income', align: pw.TextAlign.right),
                    _tableHeader('Expense', align: pw.TextAlign.right),
                    _tableHeader('Net Flow', align: pw.TextAlign.right),
                  ],
                ),
                ...List.generate(12, (i) {
                  final inc = yearlyMonthlyIncomes[i];
                  final exp = yearlyMonthlyExpenses[i];
                  final net = inc - exp;
                  if (inc == 0 && exp == 0) return null;
                  return pw.TableRow(
                    children: [
                      _tableCell(monthNames[i]),
                      _tableCell('+BDT ${inc.toStringAsFixed(2)}',
                          align: pw.TextAlign.right, color: incomeGreen),
                      _tableCell('-BDT ${exp.toStringAsFixed(2)}',
                          align: pw.TextAlign.right, color: expenseRose),
                      _tableCell(
                        net < 0
                            ? '-BDT ${net.abs().toStringAsFixed(2)}'
                            : '+BDT ${net.toStringAsFixed(2)}',
                        align: pw.TextAlign.right,
                        color: net < 0 ? expenseRose : incomeGreen,
                        bold: true,
                      ),
                    ],
                  );
                }).whereType<pw.TableRow>(),
              ],
            ),
            pw.SizedBox(height: 12),

            // 6. Yearly Category Breakdown
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Yearly Income Earned Table
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'YEARLY INCOME EARNED',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: incomeGreen,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (sortedYearlyIncomeEntries.isEmpty)
                        pw.Text('No yearly income recorded.',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: textMuted))
                      else
                        pw.Table(
                          border: pw.TableBorder.all(
                              color: borderLight, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration:
                                  const pw.BoxDecoration(color: bgMuted),
                              children: [
                                _tableHeader('Category'),
                                _tableHeader('Amount', align: pw.TextAlign.right),
                                _tableHeader('Share', align: pw.TextAlign.right),
                              ],
                            ),
                            ...sortedYearlyIncomeEntries.map((e) {
                              final pct = yearlyIncome > 0
                                  ? (e.value / yearlyIncome * 100)
                                  : 0.0;
                              return pw.TableRow(
                                children: [
                                  _tableCell(e.key),
                                  _tableCell('+BDT ${e.value.toStringAsFixed(2)}',
                                      align: pw.TextAlign.right,
                                      color: incomeGreen,
                                      bold: true),
                                  _tableCell('${pct.toStringAsFixed(1)}%',
                                      align: pw.TextAlign.right),
                                ],
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                // Yearly Expense Spent Table
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'YEARLY EXPENSE SPENT',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: expenseRose,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (sortedYearlyExpenseEntries.isEmpty)
                        pw.Text('No yearly expense recorded.',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: textMuted))
                      else
                        pw.Table(
                          border: pw.TableBorder.all(
                              color: borderLight, width: 0.5),
                          children: [
                            pw.TableRow(
                              decoration:
                                  const pw.BoxDecoration(color: bgMuted),
                              children: [
                                _tableHeader('Category'),
                                _tableHeader('Amount', align: pw.TextAlign.right),
                                _tableHeader('Share', align: pw.TextAlign.right),
                              ],
                            ),
                            ...sortedYearlyExpenseEntries.map((e) {
                              final pct = yearlyExpense > 0
                                  ? (e.value / yearlyExpense * 100)
                                  : 0.0;
                              return pw.TableRow(
                                children: [
                                  _tableCell(e.key),
                                  _tableCell('-BDT ${e.value.toStringAsFixed(2)}',
                                      align: pw.TextAlign.right,
                                      color: expenseRose,
                                      bold: true),
                                  _tableCell('${pct.toStringAsFixed(1)}%',
                                      align: pw.TextAlign.right),
                                ],
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // 7. Period Transactions Table
            pw.Text(
              '3. TRANSACTIONS IN PERIOD (${periodTxs.length} records)',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: darkEmerald,
              ),
            ),
            pw.SizedBox(height: 4),
            if (periodTxs.isEmpty)
              pw.Text('No transactions recorded for this period.',
                  style: const pw.TextStyle(fontSize: 8.5, color: textMuted))
            else
              pw.Table(
                border: pw.TableBorder.all(color: borderLight, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: bgMuted),
                    children: [
                      _tableHeader('Date'),
                      _tableHeader('Type'),
                      _tableHeader('Category'),
                      _tableHeader('Account'),
                      _tableHeader('Note'),
                      _tableHeader('Amount', align: pw.TextAlign.right),
                    ],
                  ),
                  ...periodTxs.map((t) {
                    final isInc =
                        t.type == 'income' || t.category == 'Cash Received';
                    return pw.TableRow(
                      children: [
                        _tableCell(DateFormat('yyyy-MM-dd').format(t.date)),
                        _tableCell(t.type.toUpperCase(),
                            color: isInc ? incomeGreen : expenseRose,
                            bold: true),
                        _tableCell(t.category),
                        _tableCell(t.account.toUpperCase()),
                        _tableCell(t.note.isNotEmpty ? t.note : '-'),
                        _tableCell(
                          "${isInc ? '+' : '-'}BDT ${t.amount.toStringAsFixed(2)}",
                          align: pw.TextAlign.right,
                          color: isInc ? incomeGreen : expenseRose,
                          bold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Downloads/Saves the PDF and opens the native share/save/print dialog
  static Future<String?> exportAndDownloadPdf({
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
  }) async {
    final bytes = await generateStatementPdf(
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
      sortedYearlyIncomeEntries: sortedYearlyIncomeEntries,
      sortedYearlyExpenseEntries: sortedYearlyExpenseEntries,
    );

    final monthName = AppCategories.months[selectedMonth];
    final fileName = "Perfinax_Statement_${monthName}_$selectedYear.pdf";

    String? savedFilePath;
    try {
      if (!kIsWeb) {
        Directory directory;
        if (Platform.isAndroid || Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          directory = (await getDownloadsDirectory()) ??
              (await getApplicationDocumentsDirectory());
        }
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        savedFilePath = file.path;
      }
    } catch (_) {}

    // Invoke native print/share/download dialog
    await Printing.sharePdf(bytes: bytes, filename: fileName);

    return savedFilePath;
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: pw.BoxDecoration(
          color: bgMuted,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: borderLight, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 6.5, color: textMuted),
            ),
            pw.SizedBox(height: 3),
            pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: textDark,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? textDark,
        ),
      ),
    );
  }
}

import '../models/transaction_item.dart';

class TaxController {
  static Map<String, dynamic> getFiscalYearWindow(String ay) {
    if (ay == 'AY 2025-2026') {
      return {
        'start': DateTime(2025, 7, 1),
        'end': DateTime(2026, 6, 30, 23, 59, 59),
        'label': 'July 1, 2025 – June 30, 2026'
      };
    }
    return {
      'start': DateTime(2026, 7, 1),
      'end': DateTime(2027, 6, 30, 23, 59, 59),
      'label': 'July 1, 2026 – June 30, 2027'
    };
  }

  static Map<String, double> autoPullTaxIncome({
    required String ay,
    required List<TransactionItem> transactions,
  }) {
    final fy = getFiscalYearWindow(ay);
    final DateTime start = fy['start'];
    final DateTime end = fy['end'];

    final fyTxs = transactions.where((t) =>
        t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        t.date.isBefore(end.add(const Duration(seconds: 1))));

    double salary = 0;
    double business = 0;
    double investment = 0;

    for (var t in fyTxs) {
      if (t.type == 'income' || (t.type == 'transfer' && t.category == 'Cash Received')) {
        if (t.category == 'Salary') salary += t.amount;
        if (t.category == 'Business' || t.category == 'Freelance') business += t.amount;
      } else if (t.type == 'saving') {
        investment += t.amount;
      }
    }

    return {
      'salary': salary,
      'business': business,
      'investment': investment,
    };
  }

  static Map<String, double> calculateTaxResults({
    required double salary,
    required double business,
    required double investment,
    required double ait,
    required double categoryThreshold,
    required bool isFirstTime,
  }) {
    final double grossIncome = salary + business;
    final double salaryExemption = (salary / 3) < 450000.0 ? (salary / 3) : 450000.0;
    final double taxableIncome = (grossIncome - salaryExemption) > 0 ? (grossIncome - salaryExemption) : 0.0;

    double tempIncome = taxableIncome;
    double grossTax = 0.0;

    if (tempIncome > categoryThreshold) {
      tempIncome -= categoryThreshold;

      // Slab 1: Next 300,000 @ 10%
      double slab1 = tempIncome > 300000.0 ? 300000.0 : tempIncome;
      grossTax += slab1 * 0.10;
      tempIncome -= slab1;

      // Slab 2: Next 400,000 @ 15%
      if (tempIncome > 0) {
        double slab2 = tempIncome > 400000.0 ? 400000.0 : tempIncome;
        grossTax += slab2 * 0.15;
        tempIncome -= slab2;
      }

      // Slab 3: Next 500,000 @ 20%
      if (tempIncome > 0) {
        double slab3 = tempIncome > 500000.0 ? 500000.0 : tempIncome;
        grossTax += slab3 * 0.20;
        tempIncome -= slab3;
      }

      // Slab 4: Next 2,000,000 @ 25%
      if (tempIncome > 0) {
        double slab4 = tempIncome > 2000000.0 ? 2000000.0 : tempIncome;
        grossTax += slab4 * 0.25;
        tempIncome -= slab4;
      }

      // Slab 5: Rest @ 30%
      if (tempIncome > 0) {
        grossTax += tempIncome * 0.30;
      }
    }

    double rebateLimit1 = investment * 0.15;
    double rebateLimit2 = taxableIncome * 0.03;
    double rebateLimit3 = 1000000.0;
    double rebate = rebateLimit1 < rebateLimit2 ? rebateLimit1 : rebateLimit2;
    rebate = rebate < rebateLimit3 ? rebate : rebateLimit3;

    double taxAfterRebate = (grossTax - rebate) > 0 ? (grossTax - rebate) : 0.0;
    double minTax = isFirstTime ? 1000.0 : 5000.0;

    double payableBeforeAit = 0.0;
    if (taxableIncome > categoryThreshold) {
      payableBeforeAit = taxAfterRebate > minTax ? taxAfterRebate : minTax;
    }

    double finalPayableTax = (payableBeforeAit - ait) > 0 ? (payableBeforeAit - ait) : 0.0;

    return {
      'gross': grossIncome,
      'exemption': salaryExemption,
      'taxable': taxableIncome,
      'grossTax': grossTax,
      'rebate': rebate,
      'ait': ait,
      'finalTax': finalPayableTax,
    };
  }
}

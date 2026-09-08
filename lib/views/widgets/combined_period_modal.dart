import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_categories.dart';

void openCombinedPeriodModal({
  required BuildContext context,
  required int selectedYear,
  required int selectedMonth,
  required Function(int year, int month) onPeriodSelected,
}) {
  int tempYear = selectedYear;

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0A221C),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final curY = DateTime.now().year;
          final years = [for (var i = curY - 3; i <= curY + 1; i++) i];

          return Container(
            padding: const EdgeInsets.all(20),
            height: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Period (Month & Year)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                const Text('1. Select Year',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: years.map((y) {
                      final isSel = y == tempYear;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(y.toString()),
                          selected: isSel,
                          selectedColor: const Color(0xFF10B981),
                          backgroundColor: const Color(0xFF030A08),
                          labelStyle: TextStyle(
                              color: isSel ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold),
                          onSelected: (val) {
                            setModalState(() {
                              tempYear = y;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('2. Select Month for $tempYear',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981))),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8),
                    itemCount: 12,
                    itemBuilder: (context, idx) {
                      final isSel = idx == selectedMonth && tempYear == selectedYear;
                      return InkWell(
                        onTap: () {
                          onPeriodSelected(tempYear, idx);
                          Navigator.pop(context);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF10B981)
                                : const Color(0xFF030A08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.emerald.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                              AppCategories.months[idx].substring(0, 3),
                              style: TextStyle(
                                  color: isSel ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

import 'package:flutter/material.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';

void showThemeSelectorModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const ThemeSelectorModal(),
  );
}

class ThemeSelectorModal extends StatelessWidget {
  const ThemeSelectorModal({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final currentMode = themeController.themeMode;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Theme Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Dark Theme Option Card
              _buildThemeOptionCard(
                context: context,
                title: 'Dark / Night Theme',
                description: 'Sleek dark interface with emerald accents',
                icon: Icons.dark_mode_rounded,
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  themeController.setThemeMode(ThemeMode.dark);
                  Navigator.of(context).pop();
                },
              ),

              const SizedBox(height: 12),

              // Light Theme Option Card
              _buildThemeOptionCard(
                context: context,
                title: 'Light Theme',
                description: 'Clean bright interface with emerald accents',
                icon: Icons.light_mode_rounded,
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  themeController.setThemeMode(ThemeMode.light);
                  Navigator.of(context).pop();
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = isDark ? AppColors.slate400 : const Color(0xFF64748B);

    final cardBg = isSelected
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF030A08) : const Color(0xFFF8FAFC));

    final borderColor = isSelected
        ? const Color(0xFF10B981)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : (isDark ? const Color(0xFF0A221C) : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? AppColors.slate400 : const Color(0xFF64748B)),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

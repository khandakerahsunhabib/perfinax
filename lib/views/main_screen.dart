import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_categories.dart';
import '../controllers/data_controller.dart';
import 'dashboard/dashboard_tab.dart';
import 'calendar/calendar_tab.dart';
import 'analytics/analytics_tab.dart';
import 'tax/tax_tab.dart';
import 'profile/profile_tab.dart';
import 'widgets/combined_period_modal.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey _inputFormKey = GlobalKey();
  final GlobalKey<ProfileTabState> _profileTabKey = GlobalKey<ProfileTabState>();

  final DataController _dataController = DataController();

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month - 1; // 0-indexed month (0..11)

  @override
  void initState() {
    super.initState();
    // Normalize _selectedMonth if month returns 1..12
    if (_selectedMonth < 0) _selectedMonth = 11;
    _initData();
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _dataController.loadStorageData();
    if (mounted) {
      setState(() {});
    }
  }

  void _goToHomeAndScroll() {
    setState(() {
      _currentIndex = 0;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_inputFormKey.currentContext != null) {
        Scrollable.ensureVisible(_inputFormKey.currentContext!,
            duration: const Duration(milliseconds: 500));
      }
    });
  }

  void _navigateToProfile() {
    setState(() {
      _currentIndex = 4;
    });
    _profileTabKey.currentState?.showViewMode();
  }

  void _openPeriodModal() {
    openCombinedPeriodModal(
      context: context,
      selectedYear: _selectedYear,
      selectedMonth: _selectedMonth,
      onPeriodSelected: (year, month) {
        setState(() {
          _selectedYear = year;
          _selectedMonth = month;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _dataController.userProfile;
    final bool isProfileCreated = user.name.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF2DD4BF)]),
              ),
              child: const Center(
                child: Text('Px',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wealth Manager',
                    style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.w600)),
                Text('PERFINAX',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ],
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: _navigateToProfile,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A221C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isProfileCreated
                        ? AppColors.emerald.withValues(alpha: 0.3)
                        : const Color(0xFF10B981)),
              ),
              child: Row(
                children: [
                  user.avatarPath.isNotEmpty &&
                          File(user.avatarPath).existsSync()
                      ? CircleAvatar(
                          radius: 10,
                          backgroundImage: FileImage(File(user.avatarPath)))
                      : Icon(
                          isProfileCreated
                              ? Icons.person
                              : Icons.person_add_alt_1_rounded,
                          size: 16,
                          color: const Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                      isProfileCreated
                          ? user.name.split(' ')[0]
                          : 'Create Profile',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isProfileCreated
                              ? Colors.white
                              : const Color(0xFF10B981))),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text('Period: ',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate400)),
                Expanded(
                  child: InkWell(
                    onTap: _openPeriodModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A221C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.emerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              "${AppCategories.months[_selectedMonth]} $_selectedYear",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const Icon(Icons.arrow_drop_down,
                              size: 18, color: Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardTab(
            dataController: _dataController,
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            homeScrollController: _homeScrollController,
            inputFormKey: _inputFormKey,
            onDataChanged: () => setState(() {}),
          ),
          CalendarTab(
            dataController: _dataController,
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            onDataChanged: () => setState(() {}),
          ),
          AnalyticsTab(
            dataController: _dataController,
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            onNavigateToProfile: _navigateToProfile,
          ),
          TaxTab(
            dataController: _dataController,
          ),
          ProfileTab(
            key: _profileTabKey,
            dataController: _dataController,
            onDataChanged: () => setState(() {}),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF030A08),
        elevation: 10,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.calendar_month_rounded, 'Calendar'),
              const SizedBox(width: 40), // Space for centered Floating Button
              _buildNavItem(2, Icons.analytics_rounded, 'Analytics'),
              _buildNavItem(
                  3,
                  isProfileCreated
                      ? Icons.calculate_rounded
                      : Icons.person_rounded,
                  isProfileCreated ? 'Income TAX' : 'Profile'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToHomeAndScroll,
        backgroundColor: const Color(0xFF10B981),
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected
                  ? const Color(0xFF10B981)
                  : AppColors.slate500,
              size: 20),
          Text(label,
              style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : AppColors.slate500,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

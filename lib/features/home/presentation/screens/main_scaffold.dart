import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bazzargo/features/home/presentation/screens/home_screen.dart';
import 'package:bazzargo/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:bazzargo/features/sender/presentation/screens/active_deliveries_screen.dart';
import 'package:bazzargo/features/auth/presentation/screens/profile_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ActiveDeliveriesScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          // Responsive height — avoids overflow on small screens
          height: 60.h.clamp(56.0, 72.0),
          elevation: 0,
          backgroundColor: Color(0xFFF8F9FA),
          indicatorColor: Color(0xFF86EFAC),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined,
                  color: Color(0xFF334155), size: 22.sp),
              selectedIcon: Icon(Icons.home,
                  color: Color(0xFF065F2C), size: 22.sp),
              label: 'nav_home'.tr(),
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined,
                  color: Color(0xFF334155), size: 22.sp),
              selectedIcon: Icon(Icons.inventory_2,
                  color: Color(0xFF065F2C), size: 22.sp),
              label: 'nav_deliveries'.tr(),
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFF334155), size: 22.sp),
              selectedIcon: Icon(Icons.account_balance_wallet,
                  color: Color(0xFF065F2C), size: 22.sp),
              label: 'nav_wallet'.tr(),
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline,
                  color: Color(0xFF334155), size: 22.sp),
              selectedIcon: Icon(Icons.person,
                  color: Color(0xFF065F2C), size: 22.sp),
              label: 'nav_profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

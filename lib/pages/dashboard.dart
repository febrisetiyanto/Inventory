import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:inventory/pages/home.dart';
import 'package:inventory/pages/inventory.dart';
import 'package:inventory/pages/profile.dart';
import 'package:inventory/pages/setting.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _bottomNavIndex = 0;

  final iconList = <IconData>[
    Icons.home,
    Icons.inventory,
    Icons.person,
    Icons.settings,
  ];

  final List<Widget> _screens = [
    HomePage(),
    InventoryPage(),
    ProfilePage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_bottomNavIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // aksi ketika tombol ditekan
        },
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.asset(
            'assets/icon/1.jpg',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }
}

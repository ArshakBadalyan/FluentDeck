/// App Shell - Main Navigation Container
/// Combines all 5 screens with bottom navigation
/// Days 6-14 Integration

import 'package:flutter/material.dart';
import '../ui_elements/enhanced_design_system.dart';
import 'home/home_screen.dart';
import 'learn/learn_screen.dart';
import 'activity/activity_screen.dart';
import 'profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    LearnScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: DesignPalette.bgTertiary,
        selectedItemColor: DesignPalette.primary,
        unselectedItemColor: DesignPalette.textSecondary,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

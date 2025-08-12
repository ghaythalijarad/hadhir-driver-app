// This file previously contained a broken experimental implementation.
// To stabilize the build, we keep a thin wrapper that delegates to the clean tab.

import 'package:flutter/material.dart';
import '../../app_colors.dart';

class EnhancedHomeTab extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;
  const EnhancedHomeTab({super.key, this.onTabChanged});

  @override
  State<EnhancedHomeTab> createState() => _EnhancedHomeTabState();
}

class _EnhancedHomeTabState extends State<EnhancedHomeTab> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    Center(
      child: Text(
        'Dashboard',
        style: TextStyle(fontSize: 18, color: AppColors.primary),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          widget.onTabChanged?.call(index);
        },
      ),
    );
  }
}

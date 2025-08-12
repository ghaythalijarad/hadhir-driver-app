import 'package:flutter/material.dart';

import '../../app_colors.dart';

class EnhancedHomeTabClean extends StatelessWidget {
  final ValueChanged<int>? onTabChanged;

  const EnhancedHomeTabClean({super.key, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home Tab - Clean Version',
        style: TextStyle(fontSize: 18, color: AppColors.primary),
      ),
    );
  }
}

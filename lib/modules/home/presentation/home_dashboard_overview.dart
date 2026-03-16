import 'package:flutter/material.dart';
import '../../../shared/widgets/zerpai_layout.dart';

/// Home Dashboard Screen
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Dashboard',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dashboard_outlined,
              size: 64,
              color: Color(0xFF3F51B5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Zerpai ERP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your dashboard is loading...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

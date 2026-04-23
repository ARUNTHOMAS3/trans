import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';

class AssemblyListScreen extends StatelessWidget {
  const AssemblyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Assemblies',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Assemblies',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ZButton.primary(
                label: 'New Assembly',
                onPressed: () => context.pushNamed(
                  AppRoutes.assembliesCreate,
                  pathParameters: {
                    'orgSystemId': GoRouterState.of(context).pathParameters['orgSystemId'] ?? '',
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(child: Text('No assemblies found.')),
        ],
      ),
    );
  }
}

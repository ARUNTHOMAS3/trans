import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/sync/sync_service.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// A wrapper widget that listens to SyncService and shows global alerts
class GlobalSyncManager extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalSyncManager({super.key, required this.child});

  @override
  ConsumerState<GlobalSyncManager> createState() => _GlobalSyncManagerState();
}

class _GlobalSyncManagerState extends ConsumerState<GlobalSyncManager> {
  bool _wasOffline = false;
  bool _hasPromptedForSync = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(syncServiceProvider, (previous, next) {
      if (previous == null) return;

      // Case 1: Went Offline
      if (previous.isConnected && !next.isConnected) {
        _showOfflineSnackBar();
        setState(() => _wasOffline = true);
      }

      // Case 2: Came Online (or Started Online) with Drafts
      if (next.isConnected && next.draftCount > 0) {
        // Prompt if we transitioned from offline OR if we haven't prompted yet (startup)
        if (!previous.isConnected || !_hasPromptedForSync) {
          _showOnlineSnackBar();
          _promptSync(next.draftCount);
        }
        setState(() => _wasOffline = false);
      }
    });

    return widget.child;
  }

  void _showOfflineSnackBar() {
    ZerpaiToast.show(
      context,
      'You are offline. Changes will be saved as drafts.',
      isError: true,
      duration: const Duration(seconds: 4),
    );
  }

  void _showOnlineSnackBar() {
    // Only show "Back online" if we were explicitly offline before
    if (_wasOffline) {
      ZerpaiToast.success(context, 'You are back online.');
    }
  }

  Future<void> _promptSync(int count) async {
    if (_hasPromptedForSync) return;
    setState(() => _hasPromptedForSync = true);

    // Wait a moment for UI to settle
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    showDialog(
      context: rootNavigatorKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 16,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      color: Color(0xFF1B8EF1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Sync Offline Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'You have $count unsaved items from your offline session. '
                'Would you like to sync them with the server now?',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSubtle,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Later',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performSync();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8EF1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Sync Now',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performSync() async {
    ZerpaiToast.show(
      context,
      'Syncing data...',
      duration: const Duration(seconds: 1),
    );

    // Trigger sync in controllers
    final result = await ref
        .read(itemsControllerProvider.notifier)
        .syncOfflineItems();

    if (!mounted) return;

    final synced = result['synced'];
    final failed = result['failed'];

    if (failed == 0) {
      ZerpaiToast.success(context, 'Successfully synced $synced items!');
    } else {
      ZerpaiToast.show(
        context,
        'Synced $synced items. Failed to sync $failed items.',
        isError: true,
        duration: const Duration(seconds: 5),
      );
    }
  }
}

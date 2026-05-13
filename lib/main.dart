import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:zerpai_erp/app.dart';
import 'package:zerpai_erp/core/utils/console_error_reporter.dart';
import 'package:zerpai_erp/shared/services/hive_adapters.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_payment_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_eway_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_model.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_transfer_model.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';

class _OpenedBox {
  const _OpenedBox({required this.name, required this.box});

  final String name;
  final Box box;
}

Future<_OpenedBox> _openTypedBox(String boxName, Type? type) async {
  Box box;

  if (type == Item) {
    box = await Hive.openBox<Item>(boxName);
  } else if (type == SalesCustomer) {
    box = await Hive.openBox<SalesCustomer>(boxName);
  } else if (type == SalesOrder) {
    box = await Hive.openBox<SalesOrder>(boxName);
  } else if (type == SalesPayment) {
    box = await Hive.openBox<SalesPayment>(boxName);
  } else if (type == SalesEWayBill) {
    box = await Hive.openBox<SalesEWayBill>(boxName);
  } else if (type == Vendor) {
    box = await Hive.openBox<Vendor>(boxName);
  } else if (type == PurchaseOrder) {
    box = await Hive.openBox<PurchaseOrder>(boxName);
  } else if (type == PurchasesBill) {
    box = await Hive.openBox<PurchasesBill>(boxName);
  } else if (type == Stock) {
    box = await Hive.openBox<Stock>(boxName);
  } else if (type == InventoryAdjustment) {
    box = await Hive.openBox<InventoryAdjustment>(boxName);
  } else if (type == StockTransfer) {
    box = await Hive.openBox<StockTransfer>(boxName);
  } else if (type == AccountNode) {
    box = await Hive.openBox<AccountNode>(boxName);
  } else if (type == BatchData) {
    box = await Hive.openBox<BatchData>(boxName);
  } else if (type == SerialData) {
    box = await Hive.openBox<SerialData>(boxName);
  } else if (type == TransactionData) {
    box = await Hive.openBox<TransactionData>(boxName);
  } else {
    box = await Hive.openBox(boxName);
  }

  return _OpenedBox(name: boxName, box: box);
}

Future<void> main() async {
  BindingBase.debugZoneErrorsAreFatal = true;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ConsoleErrorReporter.log(
      'FlutterError.onError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
    ConsoleErrorReporter.log(
      'PlatformDispatcher.onError',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  };

  await Sentry.runZonedGuarded<Future<void>>(() async {
    var sentryDsn = const String.fromEnvironment('SENTRY_DSN');
    if (sentryDsn.isEmpty) {
      try {
        await dotenv.load(fileName: 'assets/.env');
        sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
      } catch (e, st) {
        ConsoleErrorReporter.log(
          'main dotenv.load assets/.env',
          error: e,
          stackTrace: st,
        );
      }
    }

    if (sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = kDebugMode ? 0.0 : 0.2;
          options.environment = kDebugMode ? 'development' : 'production';
        },
        appRunner: _initApp,
      );
      return;
    }

    await _initApp();
  }, (error, stackTrace) {
    ConsoleErrorReporter.log(
      'Sentry.runZonedGuarded',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

Future<void> _initApp() async {
  final appBootWatch = Stopwatch()..start();

  // Use path URLs on web (removes the # from URLs for deep linking)
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  debugPrint('Build Version: 1.0.1 - Fix Alpha Crash');

  assert(() {
    if (kIsWeb) {
      // Flutter web can receive early key events before the framework
      // registers the listener for this engine channel.
      ui.channelBuffers.allowOverflow('flutter/keyevent', true);
    }
    return true;
  }());

  try {
    debugPrint('Starting application initialization...');

    // Initialize Hive for offline storage (PRD Section 12.2)
    final hiveInitWatch = Stopwatch()..start();
    await Hive.initFlutter().timeout(const Duration(seconds: 8));
    hiveInitWatch.stop();
    debugPrint('Hive initialized');
    debugPrint('⏱️ [boot] hive_init=${hiveInitWatch.elapsedMilliseconds}ms');

    // Register all adapters
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ItemAdapter());
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(SalesCustomerAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SalesOrderAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(AccountNodeAdapter());
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(SalesPaymentAdapter());
    if (!Hive.isAdapterRegistered(6))
      Hive.registerAdapter(SalesEWayBillAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(VendorAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(PurchaseAdapter());
    if (!Hive.isAdapterRegistered(9))
      Hive.registerAdapter(PurchaseBillAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(StockAdapter());
    if (!Hive.isAdapterRegistered(11))
      Hive.registerAdapter(InventoryAdjustmentAdapter());
    if (!Hive.isAdapterRegistered(12))
      Hive.registerAdapter(StockTransferAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(BatchDataAdapter());
    if (!Hive.isAdapterRegistered(14))
      Hive.registerAdapter(SerialDataAdapter());
    if (!Hive.isAdapterRegistered(15))
      Hive.registerAdapter(TransactionDataAdapter());

    // Open all core boxes for offline support
    final boxDefinitions = {
      'auth': null,
      'settings': null,
      'products': Item,
      'customers': SalesCustomer,
      'pos_drafts': SalesOrder,
      'sales_orders': SalesOrder,
      'payments': SalesPayment,
      'eway_bills': SalesEWayBill,
      'vendors': Vendor,
      'purchase_orders': PurchaseOrder,
      'bills': PurchasesBill,
      'stock': Stock,
      'adjustments': InventoryAdjustment,
      'transfers': StockTransfer,
      'Accountant': AccountNode,
      'stock_batches': BatchData,
      'stock_serials': SerialData,
      'stock_transactions': TransactionData,
      'price_lists': null,
      'config': null,
    };

    // 1. Open config box first to check version
    final configWatch = Stopwatch()..start();
    final configBox = await Hive.openBox('config').timeout(
      const Duration(seconds: 6),
    );
    configWatch.stop();
    debugPrint(
      '⏱️ [boot] config_box_open=${configWatch.elapsedMilliseconds}ms',
    );
    const String currentVersion = '1.0.1';
    final String? lastVersion = configBox.get('app_version');
    final bool isVersionBump = lastVersion != currentVersion;

    if (isVersionBump) {
      debugPrint(
        '🆕 Version bump detected ($lastVersion -> $currentVersion). Resetting local caches...',
      );
    }

    // 2. Open all other core boxes in parallel (faster startup).
    final hiveBoxesWatch = Stopwatch()..start();
    final boxesToOpen = boxDefinitions.entries
        .where((entry) => entry.key != 'config')
        .map((entry) => _openTypedBox(entry.key, entry.value))
        .toList();
    final openedBoxes = await Future.wait(boxesToOpen).timeout(
      const Duration(seconds: 15),
    );
    hiveBoxesWatch.stop();
    debugPrint(
      '⏱️ [boot] core_boxes_open_parallel=${hiveBoxesWatch.elapsedMilliseconds}ms',
    );

    if (isVersionBump) {
      await Future.wait(
        openedBoxes.map((entry) async {
          await entry.box.clear();
          debugPrint('🧹 Cleared box: ${entry.name}');
        }),
      );
    }
    for (final entry in openedBoxes) {
      debugPrint('Hive box opened: ${entry.name}');
    }

    if (isVersionBump) {
      await configBox.put('app_version', currentVersion);
      debugPrint('✅ Local caches reset and version updated to $currentVersion');
    }

    // Open the local_drafts box AFTER the version-bump clear loop so that
    // user-authored form drafts are never wiped by an app update.
    await Hive.openBox('local_drafts').timeout(const Duration(seconds: 4));
    debugPrint('Hive box opened: local_drafts');

    debugPrint('Loading environment variables...');

    // 1. Try to get from dart-define (Best for Web/Firebase)
    String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    // 2. Fallback to .env (for local development/mobile)
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint('dart-define missing, attempting to load from asset file...');
      try {
        final envLoadWatch = Stopwatch()..start();
        await dotenv
            .load(fileName: "assets/.env")
            .timeout(const Duration(seconds: 3));
        envLoadWatch.stop();
        supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        debugPrint('.env loaded fallback values');
        debugPrint(
          '⏱️ [boot] env_load=${envLoadWatch.elapsedMilliseconds}ms',
        );
      } catch (e) {
        debugPrint('Error loading env file: $e');
      }
    }

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint('CRITICAL ERROR: Supabase configuration missing!');
      throw Exception(
        'Supabase URL or Anon Key is missing. Pass them via --dart-define or check assets/.env',
      );
    }

    debugPrint('Initializing Supabase...');
    final supabaseWatch = Stopwatch()..start();
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    ).timeout(const Duration(seconds: 8));
    supabaseWatch.stop();
    debugPrint('Supabase initialized successfully');
    debugPrint('⏱️ [boot] supabase_init=${supabaseWatch.elapsedMilliseconds}ms');

    debugPrint('🚀 Launching ZerpaiApp...');
    runApp(const ProviderScope(child: ZerpaiApp()));
    appBootWatch.stop();
    debugPrint('⏱️ [boot] first_frame_trigger=${appBootWatch.elapsedMilliseconds}ms');
    debugPrint('✅ ZerpaiApp launched (first build triggered)');
  } catch (e, stack) {
    debugPrint('FATAL ERROR DURING INITIALIZATION:');
    debugPrint(e.toString());
    debugPrint(stack.toString());

    // Provide a fallback error UI
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(e.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

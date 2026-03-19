import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/app.dart';
import 'package:zerpai_erp/shared/services/hive_adapters.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_payment_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_eway_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/models/vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/models/purchase_model.dart';
import 'package:zerpai_erp/modules/purchases/models/purchase_bill_model.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_model.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_transfer_model.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';

void main() async {
  // Use path URLs on web (removes the # from URLs for deep linking)
  usePathUrlStrategy();

  debugPrint('Build Version: 1.0.1 - Fix Alpha Crash');
  WidgetsFlutterBinding.ensureInitialized();

  assert(() {
    if (kIsWeb) {
      // Flutter web can receive early key events before the framework
      // registers the listener for this engine channel.
      ui.channelBuffers.allowOverflow('flutter/keyevent', true);
    }
    return true;
  }());

  if (kIsWeb) {
    FlutterError.onError = (details) {
      final collector = details.informationCollector;
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(
          exception: details.exception,
          stack: details.stack,
          library: details.library,
          context: details.context,
          silent: details.silent,
          informationCollector: collector == null
              ? null
              : () sync* {
                  try {
                    for (final item in collector()) {
                      yield item;
                    }
                  } catch (e) {
                    yield DiagnosticsProperty<Object?>(
                      'info',
                      e,
                      showName: false,
                    );
                  }
                },
        ),
      );
    };
  }

  try {
    debugPrint('Starting application initialization...');

    // Initialize Hive for offline storage (PRD Section 12.2)
    await Hive.initFlutter();
    debugPrint('Hive initialized');

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
      'products': Item,
      'customers': SalesCustomer,
      'pos_drafts': SalesOrder,
      'sales_orders': SalesOrder,
      'payments': SalesPayment,
      'eway_bills': SalesEWayBill,
      'vendors': Vendor,
      'purchase_orders': Purchase,
      'bills': PurchaseBill,
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
    final configBox = await Hive.openBox('config');
    const String currentVersion = '1.0.1';
    final String? lastVersion = configBox.get('app_version');
    final bool isVersionBump = lastVersion != currentVersion;

    if (isVersionBump) {
      debugPrint(
        '🆕 Version bump detected ($lastVersion -> $currentVersion). Resetting local caches...',
      );
    }

    // 2. Open all other core boxes
    for (var entry in boxDefinitions.entries) {
      final boxName = entry.key;
      if (boxName == 'config') continue;

      final type = entry.value;
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
      } else if (type == Purchase) {
        box = await Hive.openBox<Purchase>(boxName);
      } else if (type == PurchaseBill) {
        box = await Hive.openBox<PurchaseBill>(boxName);
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

      if (isVersionBump) {
        await box.clear();
        debugPrint('🧹 Cleared box: $boxName');
      }
      debugPrint('Hive box opened: $boxName');
    }

    if (isVersionBump) {
      await configBox.put('app_version', currentVersion);
      debugPrint('✅ Local caches reset and version updated to $currentVersion');
    }

    // Open the local_drafts box AFTER the version-bump clear loop so that
    // user-authored form drafts are never wiped by an app update.
    await Hive.openBox('local_drafts');
    debugPrint('Hive box opened: local_drafts');

    debugPrint('Loading environment variables...');

    // 1. Try to get from dart-define (Best for Web/Firebase)
    String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    // 2. Fallback to .env (for local development/mobile)
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint('dart-define missing, attempting to load from asset file...');
      try {
        await dotenv.load(fileName: "assets/.env");
        supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        debugPrint('.env loaded fallback values');
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
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    debugPrint('Supabase initialized successfully');

    debugPrint('🚀 Launching ZerpaiApp...');
    runApp(const ProviderScope(child: ZerpaiApp()));
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

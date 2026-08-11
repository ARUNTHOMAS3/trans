import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';

class TaxGroupItem {
  final String id;
  final String name;
  final double rate;

  const TaxGroupItem({
    required this.id,
    required this.name,
    required this.rate,
  });

  String get displayLabel => '$name [${fmtRate(rate)}%]';

  static String fmtRate(double r) =>
      r == r.truncateToDouble() ? r.toInt().toString() : r.toString();

  factory TaxGroupItem.fromJson(Map<String, dynamic> json) {
    return TaxGroupItem(
      id: json['id']?.toString() ?? '',
      name: json['tax_group_name']?.toString() ?? '',
      rate: double.tryParse(json['tax_rate']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class TaxRateItem {
  final String id;
  final String name;
  final double rate;
  final String type;

  const TaxRateItem({
    required this.id,
    required this.name,
    required this.rate,
    required this.type,
  });

  String get displayLabel => '$name [${TaxGroupItem.fmtRate(rate)}%]';

  factory TaxRateItem.fromJson(Map<String, dynamic> json) {
    return TaxRateItem(
      id: json['id']?.toString() ?? '',
      name: json['tax_name']?.toString() ?? '',
      rate: double.tryParse(json['tax_rate']?.toString() ?? '0') ?? 0.0,
      type: json['tax_type']?.toString() ?? '',
    );
  }
}

final taxGroupsProvider = FutureProvider<List<TaxGroupItem>>((ref) async {
  try {
    final rows = await Supabase.instance.client
        .from('tax_groups')
        .select('id, tax_group_name, tax_rate')
        .eq('is_active', true)
        .order('tax_rate');

    return (rows as List)
        .map((r) => TaxGroupItem.fromJson(Map<String, dynamic>.from(r as Map)))
        .where((t) => t.id.isNotEmpty && t.name.isNotEmpty)
        .toList();
  } catch (e) {
    AppLogger.warning(
      'tax_groups fetch failed',
      error: e,
      module: 'vendor_credits',
    );
    return const [];
  }
});

final igstTaxRatesProvider = FutureProvider<List<TaxRateItem>>((ref) async {
  try {
    final rows = await Supabase.instance.client
        .from('tax_rates')
        .select('id, tax_name, tax_rate, tax_type')
        .eq('is_active', true)
        .eq('tax_type', 'IGST')
        .order('tax_rate');

    return (rows as List)
        .map((r) => TaxRateItem.fromJson(Map<String, dynamic>.from(r as Map)))
        .where((t) => t.id.isNotEmpty && t.name.isNotEmpty && t.type == 'IGST')
        .toList(growable: false);
  } catch (e) {
    AppLogger.warning(
      'tax_rates IGST fetch failed',
      error: e,
      module: 'vendor_credits',
    );
    return const [];
  }
});

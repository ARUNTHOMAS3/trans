import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

/// The result of a TaxEngine resolution.
enum GstTaxType {
  /// Customer and org are in the same state → apply CGST + SGST.
  intraState,

  /// Customer and org are in different states → apply IGST.
  interState,

  /// State IDs are missing or org is not configured → no suggestion.
  unknown,
}

/// Pure static utility that determines which GST tax type to apply based on
/// the org's registered state vs. the contact's billing state.
///
/// Usage:
///   final type = TaxEngine.resolve(orgStateId, customerStateId);
class TaxEngine {
  const TaxEngine._();

  /// Compares [orgStateId] and [contactStateId] (both UUID references to the
  /// `states` table) and returns the applicable [GstTaxType].
  static GstTaxType resolve(String? orgStateId, String? contactStateId) {
    if (orgStateId == null || orgStateId.isEmpty) return GstTaxType.unknown;
    if (contactStateId == null || contactStateId.isEmpty) {
      return GstTaxType.unknown;
    }
    return orgStateId == contactStateId
        ? GstTaxType.intraState
        : GstTaxType.interState;
  }

  /// Human-readable label for display in the UI.
  static String label(GstTaxType type) {
    switch (type) {
      case GstTaxType.intraState:
        return 'Intra-State (CGST + SGST)';
      case GstTaxType.interState:
        return 'Inter-State (IGST)';
      case GstTaxType.unknown:
        return 'Tax type unknown';
    }
  }
}

/// Fetches the current org's state_id from GET /lookups/org/:orgId.
/// Returns null when the org has no state configured.
final orgStateIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return null;

  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/lookups/org/${user.orgId}');
    if (response.statusCode == 200 && response.data is Map) {
      final data = Map<String, dynamic>.from(response.data as Map);
      return data['state_id'] as String?;
    }
  } catch (_) {
    // Fail silently — Smart-Tax is a UX helper, not a hard dependency.
  }
  return null;
});

import 'package:flutter/widgets.dart';

/// Mixin that adds on-blur, context-aware licence field validation to any
/// [StatefulWidget] state that manages drug-licence / FSSAI / MSME inputs.
///
/// ## How to use
///
/// 1. Add `with LicenceValidationMixin` to your state class.
/// 2. Implement all abstract getters (the existing field declarations in your
///    state class satisfy them automatically — no extra boilerplate needed).
/// 3. Call `initLicenceValidation()` in [initState].
/// 4. Call `disposeLicenceNodes()` in [dispose] (replaces individual `.dispose()` calls).
/// 5. In checkbox / type-change handlers call the clear helpers:
///    - `clearDrugLicenceErrors()` when `isDrugRegistered` is toggled off
///    - `clearDrugLicenceErrorsForType(newType)` when `drugLicenceType` changes
///    - `clearFssaiError()` when `isFssaiRegistered` is toggled off
///    - `clearMsmeError()` when `isMsmeRegistered` is toggled off
///
/// ## Example
///
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen>
///     with LicenceValidationMixin {
///
///   // Fields below satisfy the abstract getters automatically:
///   bool isDrugRegistered = false;
///   String? drugLicenceType;
///   bool isFssaiRegistered = false;
///   bool isMsmeRegistered = false;
///
///   final drugLicense20Focus = FocusNode();
///   final drugLicense20Ctrl  = TextEditingController();
///   // … etc.
///
///   // msmeCtrl getter — maps your local name to the mixin's contract:
///   @override
///   TextEditingController get msmeCtrl => msmeNumberCtrl;
///
///   @override
///   void initState() {
///     super.initState();
///     initLicenceValidation();
///   }
///
///   @override
///   void dispose() {
///     disposeLicenceNodes();
///     super.dispose();
///   }
/// }
/// ```
mixin LicenceValidationMixin<W extends StatefulWidget> on State<W> {
  // ── Abstract interface ────────────────────────────────────────────────────
  // The implementing state must expose these. A plain field declaration in
  // the state class satisfies each abstract getter automatically in Dart.

  bool get isDrugRegistered;
  String? get drugLicenceType;
  bool get isFssaiRegistered;
  bool get isMsmeRegistered;

  FocusNode get drugLicense20Focus;
  FocusNode get drugLicense21Focus;
  FocusNode get drugLicense20BFocus;
  FocusNode get drugLicense21BFocus;
  FocusNode get fssaiFocus;
  FocusNode get msmeFocus;

  TextEditingController get drugLicense20Ctrl;
  TextEditingController get drugLicense21Ctrl;
  TextEditingController get drugLicense20BCtrl;
  TextEditingController get drugLicense21BCtrl;
  TextEditingController get fssaiCtrl;

  /// Override to map your local MSME controller name to the mixin contract.
  /// e.g. `@override TextEditingController get msmeCtrl => msmeNumberCtrl;`
  TextEditingController get msmeCtrl;

  // ── Mixin-owned error state ───────────────────────────────────────────────
  // These become fields on the implementing state class.

  String? drugLicense20Error;
  String? drugLicense21Error;
  String? drugLicense20BError;
  String? drugLicense21BError;
  String? fssaiError;
  String? msmeError;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call in [initState] to wire up focus-based validation.
  void initLicenceValidation() {
    drugLicense20Focus.addListener(() => _onLicenceFocusChange('drugLicense20'));
    drugLicense21Focus.addListener(() => _onLicenceFocusChange('drugLicense21'));
    drugLicense20BFocus.addListener(() => _onLicenceFocusChange('drugLicense20B'));
    drugLicense21BFocus.addListener(() => _onLicenceFocusChange('drugLicense21B'));
    fssaiFocus.addListener(() => _onLicenceFocusChange('fssai'));
    msmeFocus.addListener(() => _onLicenceFocusChange('msme'));
  }

  /// Call in [dispose] to dispose all six focus nodes.
  void disposeLicenceNodes() {
    drugLicense20Focus.dispose();
    drugLicense21Focus.dispose();
    drugLicense20BFocus.dispose();
    drugLicense21BFocus.dispose();
    fssaiFocus.dispose();
    msmeFocus.dispose();
  }

  // ── Public clear helpers (call on checkbox/type changes) ──────────────────

  /// Clear all drug licence errors (call when `isDrugRegistered` → false).
  void clearDrugLicenceErrors() {
    if (!mounted) return;
    setState(() {
      drugLicense20Error = null;
      drugLicense21Error = null;
      drugLicense20BError = null;
      drugLicense21BError = null;
    });
  }

  /// Clear errors for fields hidden by a licence-type change.
  void clearDrugLicenceErrorsForType(String? newType) {
    if (!mounted) return;
    setState(() {
      if (newType == 'Wholesale') {
        drugLicense20Error = null;
        drugLicense21Error = null;
      } else if (newType == 'Retail') {
        drugLicense20BError = null;
        drugLicense21BError = null;
      }
    });
  }

  /// Clear FSSAI error (call when `isFssaiRegistered` → false).
  void clearFssaiError() {
    if (!mounted) return;
    setState(() => fssaiError = null);
  }

  /// Clear MSME error (call when `isMsmeRegistered` → false).
  void clearMsmeError() {
    if (!mounted) return;
    setState(() => msmeError = null);
  }

  // ── Public error-message resolver (override to customise messages) ────────

  /// Returns an error string when [value] is blank, null otherwise.
  /// Context-specific message per [field] key.
  String? getLicenceErrorMessage(String field, String value) {
    if (value.trim().isEmpty) {
      switch (field) {
        case 'drugLicense20':
          return 'Enter a valid Drug License 20.';
        case 'drugLicense21':
          return 'Enter a valid Drug License 21.';
        case 'drugLicense20B':
          return 'Enter a valid Drug License 20B.';
        case 'drugLicense21B':
          return 'Enter a valid Drug License 21B.';
        case 'fssai':
          return 'Enter a valid FSSAI Number.';
        case 'msme':
          return 'Enter a valid MSME/Udyam Registration Number. '
              'Ensure that the number is in the format UDYAM-XX-00-0000000.';
      }
    }
    return null;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onLicenceFocusChange(String field) {
    final node = _focusNodeFor(field);
    if (!node.hasFocus) _validateLicenceField(field);
  }

  FocusNode _focusNodeFor(String field) {
    switch (field) {
      case 'drugLicense20':  return drugLicense20Focus;
      case 'drugLicense21':  return drugLicense21Focus;
      case 'drugLicense20B': return drugLicense20BFocus;
      case 'drugLicense21B': return drugLicense21BFocus;
      case 'fssai':          return fssaiFocus;
      case 'msme':           return msmeFocus;
      default:               return FocusNode();
    }
  }

  void _validateLicenceField(String field) {
    if (!mounted) return;
    setState(() {
      switch (field) {
        case 'drugLicense20':
          if (isDrugRegistered &&
              (drugLicenceType == 'Retail' || drugLicenceType == 'Wholesale and Retail')) {
            drugLicense20Error = getLicenceErrorMessage(field, drugLicense20Ctrl.text);
          }
          break;
        case 'drugLicense21':
          if (isDrugRegistered &&
              (drugLicenceType == 'Retail' || drugLicenceType == 'Wholesale and Retail')) {
            drugLicense21Error = getLicenceErrorMessage(field, drugLicense21Ctrl.text);
          }
          break;
        case 'drugLicense20B':
          if (isDrugRegistered &&
              (drugLicenceType == 'Wholesale' || drugLicenceType == 'Wholesale and Retail')) {
            drugLicense20BError = getLicenceErrorMessage(field, drugLicense20BCtrl.text);
          }
          break;
        case 'drugLicense21B':
          if (isDrugRegistered &&
              (drugLicenceType == 'Wholesale' || drugLicenceType == 'Wholesale and Retail')) {
            drugLicense21BError = getLicenceErrorMessage(field, drugLicense21BCtrl.text);
          }
          break;
        case 'fssai':
          if (isFssaiRegistered) {
            fssaiError = getLicenceErrorMessage(field, fssaiCtrl.text);
          }
          break;
        case 'msme':
          if (isMsmeRegistered) {
            msmeError = getLicenceErrorMessage(field, msmeCtrl.text);
          }
          break;
      }
    });
  }
}

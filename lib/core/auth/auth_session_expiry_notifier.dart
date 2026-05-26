import 'package:flutter/foundation.dart';

class AuthSessionExpiryNotifier extends ChangeNotifier {
  bool _forceLogin = false;

  bool get forceLogin => _forceLogin;

  void markForceLogin() {
    if (_forceLogin) return;
    _forceLogin = true;
    notifyListeners();
  }

  void clear() {
    if (!_forceLogin) return;
    _forceLogin = false;
    notifyListeners();
  }

  void clearSilently() {
    _forceLogin = false;
  }
}

final AuthSessionExpiryNotifier authSessionExpiryNotifier =
    AuthSessionExpiryNotifier();

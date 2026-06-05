import 'package:zerpai_erp/modules/auth/models/user_model.dart';

const Set<String> kPlatformAdminOverrideEmails = <String>{
  'zabnixprivatelimited@gmail.com',
};

bool isPlatformAdminOverride(User? user) {
  if (user == null) return false;
  final normalizedEmail = user.email.trim().toLowerCase();
  if (normalizedEmail.isEmpty) return false;
  return kPlatformAdminOverrideEmails.contains(normalizedEmail);
}

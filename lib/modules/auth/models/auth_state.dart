import '../models/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final String token;

  Authenticated({required this.user, required this.token});
}

class Unauthenticated extends AuthState {
  final String? errorMessage;

  Unauthenticated({this.errorMessage});
}

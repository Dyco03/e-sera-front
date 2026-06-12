/*

Auth Cubit: State Management

*/

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:e_sera/features/auth/domain/entities/app_user.dart';
import 'package:e_sera/features/auth/domain/repos/auth_repo.dart';
import 'package:e_sera/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;
  static const _authTimeout = Duration(seconds: 10);

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  //check if user is already authenticated
  void checkAuth() async {
    emit(Authloading());

    try {
      if (!await _hasNetworkConnection()) {
        emit(NoInternet());
        return;
      }

      final AppUser? user = await authRepo.getCurrentUser().timeout(
        _authTimeout,
      );

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        _currentUser = null;
        emit(Unauthenticated());
      }
    } on TimeoutException {
      emit(NoInternet());
    } catch (e) {
      if (_isNetworkException(e)) {
        emit(NoInternet());
        return;
      }

      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  // get current user
  AppUser? get currentUser => _currentUser;

  // login with email + password
  Future<void> login(String email, String pw) async {
    try {
      if (!await _hasNetworkConnection()) {
        emit(NoInternet());
        return;
      }

      emit(Authloading()); // for display the loading
      final user = await authRepo
          .loginWithEmailPassword(email, pw)
          .timeout(_authTimeout);

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        _currentUser = null;
        emit(Unauthenticated());
      }
    } on TimeoutException {
      emit(NoInternet());
    } catch (e) {
      if (_isNetworkException(e)) {
        emit(NoInternet());
        return;
      }

      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  // register with email + password
  Future<void> register(String name, String email, String pw) async {
    try {
      if (!await _hasNetworkConnection()) {
        emit(NoInternet());
        return;
      }

      emit(Authloading());
      final user = await authRepo
          .registerWithEmailPassword(name, email, pw)
          .timeout(_authTimeout);

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        _currentUser = null;
        emit(Unauthenticated());
      }
    } on TimeoutException {
      emit(NoInternet());
    } catch (e) {
      if (_isNetworkException(e)) {
        emit(NoInternet());
        return;
      }

      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  // logout
  Future<void> logout() async {
    authRepo.logout();
    _currentUser = null;
    emit(Unauthenticated());
  }

  Future<bool> _hasNetworkConnection() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
  }

  bool _isNetworkException(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('clientexception') ||
        message.contains('xmlhttprequest error');
  }
}

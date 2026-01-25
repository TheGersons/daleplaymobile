import 'package:flutter/material.dart';
import '../models/auth_user.dart';

class UserProvider extends ChangeNotifier {
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isVendedor => _currentUser?.isVendedor ?? false;


  void setUser(AuthUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
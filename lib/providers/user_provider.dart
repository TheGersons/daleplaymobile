import 'dart:convert'; // Importante para JSON
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

class UserProvider extends ChangeNotifier {
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Cargar usuario al iniciar la app
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_session');
    if (userJson != null) {
      _currentUser = AuthUser.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  // Guardar usuario al hacer login
  void setUser(AuthUser user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user.toJson()));
    notifyListeners();
  }

  // Borrar usuario al cerrar sesión
  void clearUser() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    notifyListeners();
  }
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isVendedor => _currentUser?.isVendedor ?? false;
}
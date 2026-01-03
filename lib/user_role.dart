import 'package:flutter/material.dart';

class UserRole with ChangeNotifier {
  String _role = 'user';

  String get role => _role;

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }
}

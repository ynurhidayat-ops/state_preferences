import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

// UserProvider kini adalah ChangeNotifier: menyimpan state + logika,
// dan memanggil notifyListeners() setiap state berubah.
class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  int get visitCount => _visitCount;
  List<String> get favorites => List.unmodifiable(_favorites);

  UserProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    final visits = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visits);

    _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _favorites = prefs.getStringList('favorites') ?? [];
    _visitCount = visits;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(User newUser) async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    final registered = <String>[
      ...(prefs.getStringList('registered_emails') ?? <String>[]),
    ];
    final normalized = newUser.email.toLowerCase();
    if (!registered.contains(normalized)) {
      registered.add(normalized);
      await prefs.setStringList('registered_emails', registered);
    }

    _user = newUser;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    _user = _user.copyWith(name: '', isLoggedIn: false);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);

    _isDarkMode = value;
    notifyListeners();
  }

  Future<void> addFavorite(String item) async {
    final updated = [..._favorites, item];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updated);

    _favorites = updated;
    notifyListeners();
  }

  Future<void> removeFavorite(String item) async {
    final updated = _favorites.where((f) => f != item).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updated);

    _favorites = updated;
    notifyListeners();
  }

  Future<String?> validateProfile(String name, String email) async {
    final dangerous = RegExp(r'[<>]|javascript:', caseSensitive: false);
    if (dangerous.hasMatch(name)) {
      return 'Nama mengandung karakter yang tidak diizinkan (< > atau '
          'javascript:)';
    }

    final prefs = await SharedPreferences.getInstance();
    final registered = prefs.getStringList('registered_emails') ?? [];
    final normalized = email.toLowerCase();
    final isOwnEmail = normalized == _user.email.toLowerCase();
    if (registered.contains(normalized) && !isOwnEmail) {
      return 'Email sudah digunakan oleh akun lain';
    }
    return null;
  }
}

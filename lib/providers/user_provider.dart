import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider extends InheritedWidget {
  final User user;
  final bool isLoading;
  final bool isDarkMode; 
  final int visitCount; 
  final List<String> favorites; 
  final Future<void> Function(User) updateUser;
  final Future<void> Function() logout;
  final Future<void> Function(bool) setDarkMode; 
  final Future<void> Function(String) addFavorite; 
  final Future<void> Function(String) removeFavorite; 
  final Future<String?> Function(String, String) validateProfile; 

  const UserProvider({
    super.key,
    required this.user,
    required this.isLoading,
    required this.isDarkMode,
    required this.visitCount,
    required this.favorites,
    required this.updateUser,
    required this.logout,
    required this.setDarkMode,
    required this.addFavorite,
    required this.removeFavorite,
    required this.validateProfile,
    required super.child,
  });

  static UserProvider of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<UserProvider>();
    assert(provider != null, 'UserProvider tidak ditemukan di context');
    return provider!;
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) {
    return oldWidget.user != user ||
        oldWidget.isLoading != isLoading ||
        oldWidget.isDarkMode != isDarkMode ||
        oldWidget.visitCount != visitCount ||
        oldWidget.favorites != favorites;
  }
}

class UserProviderWrapper extends StatefulWidget {
  final Widget child;

  const UserProviderWrapper({super.key, required this.child});

  @override
  State<UserProviderWrapper> createState() => _UserProviderWrapperState();
}

class _UserProviderWrapperState extends State<UserProviderWrapper> {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }


  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    final favorites = prefs.getStringList('favorites') ?? [];


    final visits = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visits);

    if (!mounted) return;
    setState(() {
      _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
      _isDarkMode = isDark;
      _favorites = favorites;
      _visitCount = visits;
      _isLoading = false;
    });
  }

  Future<void> _updateUser(User newUser) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    // [Latihan 5] catat email sebagai "sudah terdaftar" (simulasi)
    final registered = <String>[
      ...(prefs.getStringList('registered_emails') ?? <String>[]),
    ];
    final normalized = newUser.email.toLowerCase();
    if (!registered.contains(normalized)) {
      registered.add(normalized);
      await prefs.setStringList('registered_emails', registered);
    }

    if (!mounted) return;
    setState(() {
      _user = newUser;
      _isLoading = false;
    });
  }


  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    if (!mounted) return;
    setState(() {
      _user = _user.copyWith(name: '', isLoggedIn: false);
    });
  }

  Future<void> _setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);

    if (!mounted) return;
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _addFavorite(String item) async {
    final updated = [..._favorites, item];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updated);

    if (!mounted) return;
    setState(() {
      _favorites = updated;
    });
  }

  Future<void> _removeFavorite(String item) async {
    final updated = _favorites.where((f) => f != item).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updated);

    if (!mounted) return;
    setState(() {
      _favorites = updated;
    });
  }

  // [Latihan 5] validasi keamanan; mengembalikan pesan error atau null
  Future<String?> _validateProfile(String name, String email) async {
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

  @override
  Widget build(BuildContext context) {
    return UserProvider(
      user: _user,
      isLoading: _isLoading,
      isDarkMode: _isDarkMode,
      visitCount: _visitCount,
      favorites: _favorites,
      updateUser: _updateUser,
      logout: _logout,
      setDarkMode: _setDarkMode,
      addFavorite: _addFavorite,
      removeFavorite: _removeFavorite,
      validateProfile: _validateProfile,
      child: widget.child,
    );
  }
}

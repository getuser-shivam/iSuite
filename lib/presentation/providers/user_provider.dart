import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
    );
  }
}

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  UserProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Simulate loading user from local storage
    // In a real app, this would load from secure storage
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For demo purposes, start with no user
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Demo login - accept any email/password
      if (email.isNotEmpty && password.isNotEmpty) {
        _user = User(
          id: '1',
          name: email.split('@')[0],
          email: email,
        );
        _error = null;
      } else {
        _error = 'Please enter email and password';
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
        _user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          email: email,
        );
        _error = null;
      } else {
        _error = 'Please fill all fields';
      }
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate logout
      await Future.delayed(const Duration(milliseconds: 500));
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Logout failed: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      _user = _user!.copyWith(
        name: name ?? _user!.name,
        email: email ?? _user!.email,
      );
      _error = null;
    } catch (e) {
      _error = 'Update failed: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

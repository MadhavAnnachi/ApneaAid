import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

// Auth service to handle user authentication
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal() {
    _userController = StreamController<User?>.broadcast();
    _loadCurrentUser();
  }
  
  // Stream controller for user state
  late StreamController<User?> _userController;
  User? _currentUser;
  
  // Stream of current user - null when not logged in
  Stream<User?> get userStream => _userController.stream;
  
  // Current user getter
  User? get currentUser => _currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;
  
  // Load current user from storage on startup
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        final userMap = json.decode(userJson);
        _currentUser = User.fromMap(userMap);
        _userController.add(_currentUser);
        debugPrint('👤 AuthService: Loaded user from storage: ${_currentUser!.fullName}');
      } else {
        _userController.add(null);
        debugPrint('👤 AuthService: No user found in storage');
      }
    } catch (e) {
      debugPrint('👤 AuthService ERROR loading user: $e');
      _userController.add(null);
    }
  }
  
  // Save user to storage
  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(user.toMap()));
    } catch (e) {
      debugPrint('👤 AuthService ERROR saving user: $e');
    }
  }
  
  // Store user credentials for login
  Future<void> _saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final credentials = await prefs.getStringList('user_credentials') ?? [];
      
      // Check if email already exists
      final exists = credentials.any((cred) {
        final parts = cred.split(':');
        return parts.length > 0 && parts[0] == email;
      });
      
      if (!exists) {
        credentials.add('$email:$password');
        await prefs.setStringList('user_credentials', credentials);
      }
    } catch (e) {
      debugPrint('👤 AuthService ERROR saving credentials: $e');
    }
  }
  
  // Signup new user
  Future<User?> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Create new user
      final user = User(
        id: const Uuid().v4(),
        firstName: firstName,
        lastName: lastName,
        email: email,
        createdAt: DateTime.now(),
      );
      
      // Save user and credentials
      await _saveUserToStorage(user);
      await _saveCredentials(email, password);
      
      // Update current user
      _currentUser = user;
      _userController.add(_currentUser);
      
      return user;
    } catch (e) {
      debugPrint('👤 AuthService ERROR during signup: $e');
      return null;
    }
  }
  
  // Login user
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Get saved credentials
      final prefs = await SharedPreferences.getInstance();
      final credentials = prefs.getStringList('user_credentials') ?? [];
      
      // Check if credentials match
      final match = credentials.firstWhere(
        (cred) {
          final parts = cred.split(':');
          return parts.length > 1 && parts[0] == email && parts[1] == password;
        },
        orElse: () => '',
      );
      
      if (match.isEmpty) {
        // No matching credentials
        debugPrint('👤 AuthService: Login failed - incorrect credentials');
        return null;
      }
      
      // Get saved users
      final userList = await getRegisteredUsers();
      
      // Find user with matching email
      final user = userList.firstWhere(
        (u) => u.email == email,
        orElse: () => User(
          id: const Uuid().v4(),
          firstName: 'User',
          lastName: '',
          email: email,
          createdAt: DateTime.now(),
        ),
      );
      
      // Save and update current user
      await _saveUserToStorage(user);
      _currentUser = user;
      _userController.add(_currentUser);
      
      debugPrint('👤 AuthService: Login successful for ${user.fullName}');
      return user;
    } catch (e) {
      debugPrint('👤 AuthService ERROR during login: $e');
      return null;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      
      _currentUser = null;
      _userController.add(null);
      
      debugPrint('👤 AuthService: User logged out');
    } catch (e) {
      debugPrint('👤 AuthService ERROR during logout: $e');
    }
  }
  
  // Get all registered users (for demo purposes)
  Future<List<User>> getRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userListJson = prefs.getStringList('registered_users') ?? [];
      
      return userListJson
          .map((json) => User.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('👤 AuthService ERROR getting users: $e');
      return [];
    }
  }
  
  // Update user profile
  Future<User?> updateProfile({
    required String firstName,
    required String lastName,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return null;
    
    try {
      // Create updated user
      final updatedUser = User(
        id: _currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        email: _currentUser!.email,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
        createdAt: _currentUser!.createdAt,
      );
      
      // Save to storage
      await _saveUserToStorage(updatedUser);
      
      // Update current user
      _currentUser = updatedUser;
      _userController.add(_currentUser);
      
      return updatedUser;
    } catch (e) {
      debugPrint('👤 AuthService ERROR updating profile: $e');
      return null;
    }
  }
  
  // Dispose resources
  void dispose() {
    _userController.close();
  }
} 
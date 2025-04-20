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
  
  // Save user credentials for login
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
        
        // Also add to registered_users list if not exists
        try {
          final userListJson = prefs.getStringList('registered_users') ?? [];
          final existingUsers = userListJson
              .map((json) => User.fromMap(jsonDecode(json)))
              .toList();
              
          final existingEmails = existingUsers.map((u) => u.email).toList();
          
          if (!existingEmails.contains(email)) {
            final newUser = User(
              id: const Uuid().v4(),
              firstName: email.split('@')[0],
              lastName: '',
              email: email,
              createdAt: DateTime.now(),
            );
            
            userListJson.add(jsonEncode(newUser.toMap()));
            await prefs.setStringList('registered_users', userListJson);
          }
        } catch (e) {
          // If error occurs, create the registered_users list
          debugPrint('Creating registered_users list for the first time');
          final newUser = User(
            id: const Uuid().v4(),
            firstName: email.split('@')[0],
            lastName: '',
            email: email,
            createdAt: DateTime.now(),
          );
          
          await prefs.setStringList('registered_users', [jsonEncode(newUser.toMap())]);
        }
      }
    } catch (e) {
      debugPrint('👤 AuthService ERROR saving credentials: $e');
      rethrow; // Rethrow to let callers handle the error
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
      // Check for existing users with the same email
      final prefs = await SharedPreferences.getInstance();
      final credentials = prefs.getStringList('user_credentials') ?? [];
      
      // Check if email already exists
      final exists = credentials.any((cred) {
        final parts = cred.split(':');
        return parts.length > 0 && parts[0] == email;
      });
      
      if (exists) {
        debugPrint('👤 AuthService: Signup failed - email already exists');
        throw 'Email already exists';
      }
      
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
      
      // Initialize registered_users if it doesn't exist
      try {
        // Get existing users
        final userListJson = prefs.getStringList('registered_users') ?? [];
        userListJson.add(jsonEncode(user.toMap()));
        await prefs.setStringList('registered_users', userListJson);
      } catch (e) {
        // If error occurs, create the registered_users list
        await prefs.setStringList('registered_users', [jsonEncode(user.toMap())]);
      }
      
      // Save user and credentials
      await _saveUserToStorage(user);
      await _saveCredentials(email, password);
      
      // Update current user
      _currentUser = user;
      _userController.add(_currentUser);
      
      return user;
    } catch (e) {
      debugPrint('👤 AuthService ERROR during signup: $e');
      rethrow; // Rethrow for specific error handling
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
      
      if (credentials.isEmpty) {
        debugPrint('👤 AuthService: Login failed - no credentials found');
        throw 'No user accounts found. Please sign up first.';
      }
      
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
        // Check if the email exists but password is wrong
        final emailExists = credentials.any((cred) {
          final parts = cred.split(':');
          return parts.length > 0 && parts[0] == email;
        });
        
        if (emailExists) {
          debugPrint('👤 AuthService: Login failed - incorrect password');
          throw 'Incorrect password';
        } else {
          debugPrint('👤 AuthService: Login failed - email not found');
          throw 'Email not found. Please sign up.';
        }
      }
      
      // Get saved users
      final userList = await getRegisteredUsers();
      
      if (userList.isEmpty) {
        // Initialize registered_users if empty
        final newUser = User(
          id: const Uuid().v4(),
          firstName: email.split('@')[0],
          lastName: '',
          email: email,
          createdAt: DateTime.now(),
        );
        
        await prefs.setStringList('registered_users', [jsonEncode(newUser.toMap())]);
        
        // Save and update current user
        await _saveUserToStorage(newUser);
        _currentUser = newUser;
        _userController.add(_currentUser);
        
        return newUser;
      }
      
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
      rethrow; // Rethrow for specific error handling
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
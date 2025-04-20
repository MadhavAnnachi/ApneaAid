class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
  });
  
  // Get initials for avatar
  String get initials {
    if (firstName.isEmpty) return '';
    return firstName[0].toUpperCase();
  }
  
  // Get full name
  String get fullName => '$firstName $lastName';
  
  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  
  // Create user from map (for storage retrieval)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
} 
/// Modèle de données pour un utilisateur
class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role; // 'admin' ou 'prestataire'
  final String? avatar; // URL de l'avatar
  final String? contact;
  final String? poste;
  final String? bio;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.avatar,
    this.contact,
    this.poste,
    this.bio,
  });

  /// Nom complet de l'utilisateur
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  /// Initiales pour l'avatar
  String get initials {
    try {
      if (firstName != null && firstName!.isNotEmpty && lastName != null && lastName!.isNotEmpty) {
        final a = firstName!.length >= 1 ? firstName!.substring(0, 1) : '';
        final b = lastName!.length >= 1 ? lastName!.substring(0, 1) : '';
        final result = (a + b).isNotEmpty ? (a + b) : username;
        return result.toUpperCase();
      }

      if (username.isNotEmpty) {
        return username.length >= 2 ? username.substring(0, 2).toUpperCase() : username.substring(0, 1).toUpperCase();
      }
    } catch (_) {
      // Defensive fallback in case of unexpected string contents
      if (username.isNotEmpty) {
        return (username.length >= 1 ? username.substring(0, 1) : 'P').toUpperCase();
      }
    }

    return '??';
  }

  /// Vérifie si l'utilisateur est admin
  bool get isAdmin => role == 'admin';

  /// Vérifie si l'utilisateur est prestataire
  bool get isPrestataire => role == 'prestataire';

  /// Helper pour parser l'URL de l'avatar
  static String? _parseAvatarUrl(dynamic avatar) {
    if (avatar == null) return null;
    final avatarStr = avatar.toString();
    if (avatarStr.isEmpty) return null;
    if (avatarStr.startsWith('http')) return avatarStr;
    return avatarStr.startsWith('/') ? avatarStr : '/$avatarStr';
  }

  /// Création depuis JSON (API)
  factory User.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où l'ID pourrait être une chaîne ou un entier
    int userId;
    if (json['id'] is int) {
      userId = json['id'] as int;
    } else if (json['id'] is String) {
      userId = int.tryParse(json['id'] as String) ?? 0;
    } else {
      userId = 0;
    }

    return User(
      id: userId,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      role: json['role'] as String? ?? 'prestataire',
      avatar: _parseAvatarUrl(json['avatar']),
      contact: json['contact'] as String?,
      poste: json['poste'] as String?,
      bio: json['bio'] as String?,
    );
  }

  /// Conversion en JSON (pour l'API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'avatar': avatar,
      'contact': contact,
      'poste': poste,
      'bio': bio,
    };
  }

  /// Copie avec modifications
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? avatar,
    String? contact,
    String? poste,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      contact: contact ?? this.contact,
      poste: poste ?? this.poste,
      bio: bio ?? this.bio,
    );
  }
}

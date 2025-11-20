/// Modèle de données pour un élève
class Student {
  final int id;
  final String matricule;
  final String nom;
  final String prenom;
  final int? classeId;
  final String? classe;
  final String? classeNom; // Pour la compatibilité avec l'API
  final DateTime dateInscription;
  final bool actif;
  final String? contactParent;
  final String? emailParent;
  final String? notes;
  final String? photo; // URL de la photo

  Student({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    this.classeId,
    this.classe,
    this.classeNom,
    required this.dateInscription,
    required this.actif,
    this.contactParent,
    this.emailParent,
    this.notes,
    this.photo,
  });

  /// Nom complet de l'élève
  String get fullName => '$prenom $nom';
  
  /// Nom de la classe (utilise classeNom si disponible, sinon classe)
  String get classeDisplay => classeNom ?? classe ?? 'Sans classe';

  /// Helper pour convertir un ID en int
  static int _parseId(dynamic id) {
    if (id is int) {
      return id;
    } else if (id is String) {
      return int.tryParse(id) ?? 0;
    } else if (id is num) {
      return id.toInt();
    }
    return 0;
  }

  /// Création depuis JSON (API)
  factory Student.fromJson(Map<String, dynamic> json) {
    // Gérer la photo - peut être une URL complète ou relative
    String? photoUrl;
    if (json['photo'] != null) {
      final photo = json['photo'] as String;
      if (photo.startsWith('http')) {
        photoUrl = photo;
      } else if (photo.isNotEmpty) {
        // Construire l'URL complète avec le baseUrl
        photoUrl = photo.startsWith('/') ? photo : '/$photo';
      }
    }
    
    return Student(
      id: _parseId(json['id']),
      matricule: json['matricule'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      classeId: json['classe'] is int ? json['classe'] as int? : null,
      classe: json['classe'] is String ? json['classe'] as String? : null,
      classeNom: json['classe_nom'] as String?,
      dateInscription: DateTime.parse(json['date_inscription'] as String),
      actif: json['actif'] as bool? ?? true,
      contactParent: json['contact_parent'] as String?,
      emailParent: json['email_parent'] as String?,
      notes: json['notes'] as String?,
      photo: photoUrl,
    );
  }

  /// Conversion en JSON (pour l'API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
      'classe': classe,
      'date_inscription': dateInscription.toIso8601String(),
      'actif': actif,
      'contact_parent': contactParent,
      'email_parent': emailParent,
      'notes': notes,
      'photo': photo,
    };
  }

  /// Copie avec modifications
  Student copyWith({
    int? id,
    String? matricule,
    String? nom,
    String? prenom,
    String? classe,
    DateTime? dateInscription,
    bool? actif,
    String? contactParent,
    String? emailParent,
    String? notes,
    String? photo,
  }) {
    return Student(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      classe: classe ?? this.classe,
      dateInscription: dateInscription ?? this.dateInscription,
      actif: actif ?? this.actif,
      contactParent: contactParent ?? this.contactParent,
      emailParent: emailParent ?? this.emailParent,
      notes: notes ?? this.notes,
      photo: photo ?? this.photo,
    );
  }
}



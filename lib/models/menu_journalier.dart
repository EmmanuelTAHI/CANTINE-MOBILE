/// Modèle de données pour un menu journalier
class MenuJournalier {
  final int id;
  final DateTime date;
  final String? entree;
  final String platPrincipal;
  final String? accompagnement;
  final String? dessert;
  final String? boisson;
  final String? commentaires;
  final String? photo; // URL de la photo

  MenuJournalier({
    required this.id,
    required this.date,
    this.entree,
    required this.platPrincipal,
    this.accompagnement,
    this.dessert,
    this.boisson,
    this.commentaires,
    this.photo,
  });

  /// Helper pour convertir un ID en int
  static int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    if (id is num) return id.toInt();
    return 0;
  }

  /// Création depuis JSON (API)
  factory MenuJournalier.fromJson(Map<String, dynamic> json) {
    String? photoUrl;
    if (json['photo'] != null) {
      final photo = json['photo'] as String;
      if (photo.startsWith('http')) {
        photoUrl = photo;
      } else if (photo.isNotEmpty) {
        photoUrl = photo.startsWith('/') ? photo : '/$photo';
      }
    }

    return MenuJournalier(
      id: _parseId(json['id']),
      date: DateTime.parse(json['date'] as String),
      entree: json['entree'] as String?,
      platPrincipal: json['plat_principal'] as String,
      accompagnement: json['accompagnement'] as String?,
      dessert: json['dessert'] as String?,
      boisson: json['boisson'] as String?,
      commentaires: json['commentaires'] as String?,
      photo: photoUrl,
    );
  }

  /// Conversion en JSON (pour l'API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'entree': entree,
      'plat_principal': platPrincipal,
      'accompagnement': accompagnement,
      'dessert': dessert,
      'boisson': boisson,
      'commentaires': commentaires,
    };
  }

  /// Description complète du menu
  String get description {
    final parts = <String>[];
    if (entree != null && entree!.isNotEmpty) parts.add('Entrée: $entree');
    parts.add('Plat: $platPrincipal');
    if (accompagnement != null && accompagnement!.isNotEmpty) {
      parts.add('Accompagnement: $accompagnement');
    }
    if (dessert != null && dessert!.isNotEmpty) parts.add('Dessert: $dessert');
    if (boisson != null && boisson!.isNotEmpty) parts.add('Boisson: $boisson');
    return parts.join(' • ');
  }
}



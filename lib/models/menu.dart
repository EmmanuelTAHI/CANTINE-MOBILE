/// Modèle de données pour un menu de cantine
class Menu {
  final int id;
  final DateTime date;
  final String titre;
  final String description;
  final String platPrincipal;
  final String? entree;
  final String? dessert;
  final String? accompagnement;
  final bool disponible;
  final double? prix;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Menu({
    required this.id,
    required this.date,
    required this.titre,
    required this.description,
    required this.platPrincipal,
    this.entree,
    this.dessert,
    this.accompagnement,
    required this.disponible,
    this.prix,
    this.createdAt,
    this.updatedAt,
  });

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

  /// Helper pour convertir un prix
  static double? _parsePrice(dynamic price) {
    if (price == null) return null;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price);
    return null;
  }

  /// Création depuis JSON (API)
  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: _parseId(json['id']),
      date: DateTime.parse(json['date'] as String),
      titre: json['titre'] as String,
      description: json['description'] as String,
      platPrincipal: json['plat_principal'] as String,
      entree: json['entree'] as String?,
      dessert: json['dessert'] as String?,
      accompagnement: json['accompagnement'] as String?,
      disponible: json['disponible'] as bool? ?? true,
      prix: _parsePrice(json['prix']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Conversion en JSON (pour l'API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'titre': titre,
      'description': description,
      'plat_principal': platPrincipal,
      'entree': entree,
      'dessert': dessert,
      'accompagnement': accompagnement,
      'disponible': disponible,
      'prix': prix,
    };
  }

  /// Copie avec modifications
  Menu copyWith({
    int? id,
    DateTime? date,
    String? titre,
    String? description,
    String? platPrincipal,
    String? entree,
    String? dessert,
    String? accompagnement,
    bool? disponible,
    double? prix,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Menu(
      id: id ?? this.id,
      date: date ?? this.date,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      platPrincipal: platPrincipal ?? this.platPrincipal,
      entree: entree ?? this.entree,
      dessert: dessert ?? this.dessert,
      accompagnement: accompagnement ?? this.accompagnement,
      disponible: disponible ?? this.disponible,
      prix: prix ?? this.prix,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



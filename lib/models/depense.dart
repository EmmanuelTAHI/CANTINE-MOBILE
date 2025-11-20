/// Catégorie de dépense
enum CategorieDepense {
  ingredients,
  gaz,
  mainOeuvre,
  logistique,
  autre;

  String get displayName {
    switch (this) {
      case CategorieDepense.ingredients:
        return 'Ingrédients';
      case CategorieDepense.gaz:
        return 'Gaz / Énergie';
      case CategorieDepense.mainOeuvre:
        return 'Main d\'œuvre';
      case CategorieDepense.logistique:
        return 'Logistique';
      case CategorieDepense.autre:
        return 'Autre';
    }
  }

  String get apiValue {
    switch (this) {
      case CategorieDepense.ingredients:
        return 'ingredients';
      case CategorieDepense.gaz:
        return 'gaz';
      case CategorieDepense.mainOeuvre:
        return 'main_oeuvre';
      case CategorieDepense.logistique:
        return 'logistique';
      case CategorieDepense.autre:
        return 'autre';
    }
  }

  static CategorieDepense fromApi(String value) {
    switch (value) {
      case 'ingredients':
        return CategorieDepense.ingredients;
      case 'gaz':
        return CategorieDepense.gaz;
      case 'main_oeuvre':
        return CategorieDepense.mainOeuvre;
      case 'logistique':
        return CategorieDepense.logistique;
      default:
        return CategorieDepense.autre;
    }
  }
}

/// Modèle de données pour une dépense
class Depense {
  final int id;
  final String libelle;
  final CategorieDepense categorie;
  final double montant;
  final DateTime date;
  final String? notes;

  Depense({
    required this.id,
    required this.libelle,
    required this.categorie,
    required this.montant,
    required this.date,
    this.notes,
  });

  /// Helper pour convertir un ID en int
  static int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    if (id is num) return id.toInt();
    return 0;
  }

  /// Helper pour convertir un montant
  static double _parseMontant(dynamic montant) {
    if (montant is double) return montant;
    if (montant is int) return montant.toDouble();
    if (montant is String) return double.tryParse(montant) ?? 0.0;
    if (montant is num) return montant.toDouble();
    return 0.0;
  }

  /// Création depuis JSON (API)
  factory Depense.fromJson(Map<String, dynamic> json) {
    return Depense(
      id: _parseId(json['id']),
      libelle: json['libelle'] as String,
      categorie: CategorieDepense.fromApi(json['categorie'] as String),
      montant: _parseMontant(json['montant']),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Conversion en JSON (pour l'API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'categorie': categorie.apiValue,
      'montant': montant,
      'date': date.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }

  /// Copie avec modifications
  Depense copyWith({
    int? id,
    String? libelle,
    CategorieDepense? categorie,
    double? montant,
    DateTime? date,
    String? notes,
  }) {
    return Depense(
      id: id ?? this.id,
      libelle: libelle ?? this.libelle,
      categorie: categorie ?? this.categorie,
      montant: montant ?? this.montant,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}



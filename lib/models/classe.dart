/// Modèle de données pour une classe
class Classe {
  final int id;
  final String nom;
  final String? niveau;
  final String? responsable;

  Classe({
    required this.id,
    required this.nom,
    this.niveau,
    this.responsable,
  });

  /// Helper pour convertir un ID en int
  static int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    if (id is num) return id.toInt();
    return 0;
  }

  /// Création depuis JSON (API)
  factory Classe.fromJson(Map<String, dynamic> json) {
    return Classe(
      id: _parseId(json['id']),
      nom: json['nom'] as String,
      niveau: json['niveau'] as String?,
      responsable: json['responsable'] as String?,
    );
  }

  /// Conversion en JSON (pour l'API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'niveau': niveau,
      'responsable': responsable,
    };
  }
}



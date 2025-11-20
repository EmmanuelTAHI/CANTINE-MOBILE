/// Modèle de données pour un menu mensuel
class MenuMensuel {
  final int id;
  final String titre;
  final int mois;
  final int annee;
  final String? description;
  final String? couverture; // URL de l'image de couverture
  final String? document; // URL du document PDF
  final DateTime createdAt;

  MenuMensuel({
    required this.id,
    required this.titre,
    required this.mois,
    required this.annee,
    this.description,
    this.couverture,
    this.document,
    required this.createdAt,
  });

  /// Helper pour convertir un ID en int
  static int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    if (id is num) return id.toInt();
    return 0;
  }

  /// Nom du mois
  String get moisNom {
    const moisNoms = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return moisNoms[mois - 1];
  }

  /// Création depuis JSON (API)
  factory MenuMensuel.fromJson(Map<String, dynamic> json) {
    String? couvertureUrl;
    if (json['couverture'] != null) {
      final cover = json['couverture'] as String;
      if (cover.startsWith('http')) {
        couvertureUrl = cover;
      } else if (cover.isNotEmpty) {
        couvertureUrl = cover.startsWith('/') ? cover : '/$cover';
      }
    }

    String? documentUrl;
    if (json['document'] != null) {
      final doc = json['document'] as String;
      if (doc.startsWith('http')) {
        documentUrl = doc;
      } else if (doc.isNotEmpty) {
        documentUrl = doc.startsWith('/') ? doc : '/$doc';
      }
    }

    return MenuMensuel(
      id: _parseId(json['id']),
      titre: json['titre'] as String,
      mois: json['mois'] as int,
      annee: json['annee'] as int,
      description: json['description'] as String?,
      couverture: couvertureUrl,
      document: documentUrl,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Conversion en JSON (pour l'API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'mois': mois,
      'annee': annee,
      'description': description,
    };
  }
}



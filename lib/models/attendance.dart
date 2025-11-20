import 'student.dart';

/// Type de repas
enum RepasType {
  dejeuner,
  diner;

  String get displayName {
    switch (this) {
      case RepasType.dejeuner:
        return 'Déjeuner';
      case RepasType.diner:
        return 'Dîner';
    }
  }

  String get apiValue {
    switch (this) {
      case RepasType.dejeuner:
        return 'dejeuner';
      case RepasType.diner:
        return 'diner';
    }
  }

  static RepasType fromApi(String? value) {
    switch (value) {
      case 'dejeuner':
        return RepasType.dejeuner;
      case 'diner':
        return RepasType.diner;
      default:
        return RepasType.dejeuner;
    }
  }
}

/// Modèle de données pour une présence
class Attendance {
  final int id;
  final int studentId;
  final Student? student; // Optionnel, peut être chargé séparément
  final DateTime date;
  final RepasType repas;
  final bool present;
  final String? notes;
  final String? commentaire; // Alias pour notes
  final DateTime? heurePointage;
  final int? menuId; // ID du menu journalier associé
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Attendance({
    required this.id,
    required this.studentId,
    this.student,
    required this.date,
    this.repas = RepasType.dejeuner,
    required this.present,
    this.notes,
    this.commentaire,
    this.heurePointage,
    this.menuId,
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

  /// Création depuis JSON (API)
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: _parseId(json['id']),
      studentId: _parseId(json['student_id'] ?? json['eleve']),
      student: json['student'] != null
          ? Student.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      date: DateTime.parse(json['date'] as String),
      repas: RepasType.fromApi(json['repas'] as String?),
      present: json['present'] as bool? ?? false,
      notes: json['notes'] as String? ?? json['commentaire'] as String?,
      commentaire: json['commentaire'] as String? ?? json['notes'] as String?,
      heurePointage: json['heure_pointage'] != null
          ? DateTime.parse('1970-01-01 ${json['heure_pointage']}')
          : null,
      menuId: json['menu'] != null ? _parseId(json['menu']) : null,
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
      'eleve': studentId, // Backend attend 'eleve'
      'date': date.toIso8601String().split('T')[0], // Format YYYY-MM-DD
      'repas': repas.apiValue,
      'present': present,
      'commentaire': notes ?? commentaire,
      if (menuId != null) 'menu': menuId,
    };
  }

  /// Création d'une nouvelle présence (pour POST)
  factory Attendance.create({
    required int studentId,
    required DateTime date,
    required bool present,
    RepasType repas = RepasType.dejeuner,
    String? notes,
    int? menuId,
  }) {
    return Attendance(
      id: 0, // Sera assigné par le backend
      studentId: studentId,
      date: date,
      repas: repas,
      present: present,
      notes: notes,
      menuId: menuId,
    );
  }

  /// Copie avec modifications
  Attendance copyWith({
    int? id,
    int? studentId,
    Student? student,
    DateTime? date,
    bool? present,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      student: student ?? this.student,
      date: date ?? this.date,
      present: present ?? this.present,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



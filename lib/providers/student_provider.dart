import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../services/api_service.dart';

/// Provider pour la gestion des élèves
class StudentProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  StudentProvider(this._apiService);

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge la liste des élèves
  Future<void> loadStudents({String? classe, bool? actif}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await _apiService.getStudents(classe: classe, actif: actif);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère un élève par son ID
  Student? getStudentById(int id) {
    try {
      return _students.firstWhere((student) => student.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filtre les élèves actifs
  List<Student> get activeStudents {
    return _students.where((student) => student.actif).toList();
  }

  /// Liste des classes uniques
  List<String> get classes {
    final classesSet = <String>{};
    for (var student in _students) {
      final classe = student.classeNom ?? student.classe;
      if (classe != null && classe.isNotEmpty) {
        classesSet.add(classe);
      }
    }
    return classesSet.toList()..sort();
  }

  /// Filtre les élèves par classe
  List<Student> getStudentsByClasse(String? classe) {
    if (classe == null || classe.isEmpty) {
      return activeStudents;
    }
    return activeStudents.where((student) {
      final studentClasse = student.classeNom ?? student.classe;
      return studentClasse == classe;
    }).toList();
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}



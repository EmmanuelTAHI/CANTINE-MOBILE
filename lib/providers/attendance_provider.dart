import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';

/// Provider pour la gestion des présences
class AttendanceProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Attendance> _todayAttendance = [];
  bool _isLoading = false;
  String? _error;

  AttendanceProvider(this._apiService);

  List<Attendance> get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge les présences du jour
  Future<void> loadTodayAttendance({RepasType? repas}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayAttendance = await _apiService.getTodayAttendance(repas: repas);
      try {
        // ignore: avoid_print
        print('[AttendanceProvider] loadTodayAttendance: fetched ${_todayAttendance.length} records for repas=${repas?.apiValue ?? 'all'}');
        // Print first ids for quick debug
        // ignore: avoid_print
        print('[AttendanceProvider] ids: ${_todayAttendance.take(5).map((a) => a.id).toList()}');
      } catch (_) {}
      _error = null;
    } catch (e) {
      _error = e.toString();
      _todayAttendance = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enregistre une présence
  Future<bool> markAttendance(Attendance attendance) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _apiService.createAttendance(attendance);
      try {
        // ignore: avoid_print
        print('[AttendanceProvider] created attendance: ${created.id} student:${created.studentId} present:${created.present}');
      } catch (_) {}
      // Mettre à jour la liste locale (vérifier par studentId ET repas)
      final index = _todayAttendance.indexWhere(
        (a) => a.studentId == attendance.studentId && a.repas == attendance.repas,
      );
      if (index >= 0) {
        _todayAttendance[index] = created;
      } else {
        _todayAttendance.add(created);
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour une présence
  Future<bool> updateAttendance(int id, Attendance attendance) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateAttendance(id, attendance);
      final index = _todayAttendance.indexWhere((a) => a.id == id);
      if (index >= 0) {
        _todayAttendance[index] = updated;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Vérifie si un élève est présent aujourd'hui pour un type de repas
  bool isStudentPresent(int studentId, {required RepasType repas}) {
    final attendance = _todayAttendance.firstWhere(
      (a) => a.studentId == studentId && a.repas == repas,
      orElse: () => Attendance(
        id: 0,
        studentId: studentId,
        date: DateTime.now(),
        repas: repas,
        present: false,
      ),
    );
    return attendance.present;
  }

  /// Récupère les présences d'aujourd'hui pour un type de repas
  List<Attendance> getTodayAttendanceByRepas(RepasType repas) {
    return _todayAttendance
        .where((a) => a.repas == repas && a.date.year == DateTime.now().year &&
            a.date.month == DateTime.now().month &&
            a.date.day == DateTime.now().day)
        .toList();
  }

  /// Compte le nombre de présents pour un type de repas
  int getPresentCount(RepasType repas) {
    return getTodayAttendanceByRepas(repas)
        .where((a) => a.present)
        .length;
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}



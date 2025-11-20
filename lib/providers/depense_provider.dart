import 'package:flutter/foundation.dart';
import '../models/depense.dart';
import '../services/api_service.dart';

/// Provider pour la gestion des dépenses
class DepenseProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Depense> _depenses = [];
  bool _isLoading = false;
  String? _error;

  DepenseProvider(this._apiService);

  List<Depense> get depenses => _depenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge les dépenses
  Future<void> loadDepenses({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _depenses = await _apiService.getDepenses(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _depenses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajoute une dépense
  Future<bool> addDepense(Depense depense) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _apiService.createDepense(depense);
      _depenses.insert(0, created);
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

  /// Met à jour une dépense
  Future<bool> updateDepense(int id, Depense depense) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateDepense(id, depense);
      final index = _depenses.indexWhere((d) => d.id == id);
      if (index >= 0) {
        _depenses[index] = updated;
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

  /// Supprime une dépense
  Future<bool> deleteDepense(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteDepense(id);
      _depenses.removeWhere((d) => d.id == id);
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

  /// Calcule le total des dépenses
  double get totalDepenses {
    return _depenses.fold(0.0, (sum, depense) => sum + depense.montant);
  }

  /// Calcule le total des dépenses d'un mois
  double getTotalMois(int mois, int annee) {
    return _depenses
        .where((d) => d.date.month == mois && d.date.year == annee)
        .fold(0.0, (sum, depense) => sum + depense.montant);
  }

  /// Calcule le total des dépenses du jour
  double getTotalJour(DateTime date) {
    return _depenses
        .where((d) =>
            d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day)
        .fold(0.0, (sum, depense) => sum + depense.montant);
  }

  /// Groupe les dépenses par catégorie
  Map<CategorieDepense, double> getDepensesParCategorie() {
    final map = <CategorieDepense, double>{};
    for (var depense in _depenses) {
      map[depense.categorie] = (map[depense.categorie] ?? 0.0) + depense.montant;
    }
    return map;
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}



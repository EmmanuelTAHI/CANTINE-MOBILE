import 'package:flutter/foundation.dart';
import '../models/menu_journalier.dart';
import '../models/menu_mensuel.dart';
import '../services/api_service.dart';

/// Provider pour la gestion des menus
class MenuProvider with ChangeNotifier {
  final ApiService _apiService;
  MenuJournalier? _todayMenu;
  List<MenuMensuel> _mensuelsMenus = [];
  bool _isLoading = false;
  String? _error;

  MenuProvider(this._apiService);

  MenuJournalier? get todayMenu => _todayMenu;
  List<MenuMensuel> get mensuelsMenus => _mensuelsMenus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge le menu du jour
  Future<void> loadTodayMenu() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayMenu = await _apiService.getTodayMenu();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _todayMenu = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge le menu d'une date spécifique
  Future<void> loadMenuByDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayMenu = await _apiService.getMenuByDate(date);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _todayMenu = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les menus mensuels
  Future<void> loadMensuelsMenus({int? annee, int? mois}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mensuelsMenus = await _apiService.getMensuelsMenus(
        annee: annee,
        mois: mois,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _mensuelsMenus = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Crée un menu journalier via l'API et recharge le menu de la date
  Future<MenuJournalier?> createJournalierMenu(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _apiService.createMenuJournalier(payload);
      // Refresh the menu for the same date
      await loadMenuByDate(created.date);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Met à jour un menu journalier via l'API et recharge le menu de la date
  Future<MenuJournalier?> updateJournalierMenu(int id, Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _apiService.updateMenuJournalier(id, payload);
      // Refresh the menu for the same date
      await loadMenuByDate(updated.date);
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}



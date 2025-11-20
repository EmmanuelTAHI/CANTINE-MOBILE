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
}



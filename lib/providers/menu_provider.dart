import 'package:flutter/foundation.dart';
import '../models/menu_journalier.dart';
import '../models/menu_mensuel.dart';
import '../services/api_service.dart';

/// Provider pour la gestion des menus
class MenuProvider with ChangeNotifier {
  final ApiService _apiService;
  MenuJournalier? _todayMenu;
  List<MenuJournalier> _menus = [];
  List<MenuMensuel> _mensuelsMenus = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  MenuProvider(this._apiService);

  MenuJournalier? get todayMenu => _todayMenu;
  List<MenuJournalier> get menus => _menus;
  List<MenuMensuel> get mensuelsMenus => _mensuelsMenus;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
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

  /// Charge une plage de menus journaliers
  Future<void> loadMenus({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _menus = await _apiService.getMenusJournalier(
        startDate: startDate,
        endDate: endDate,
      );
      _menus.sort((a, b) => b.date.compareTo(a.date));
      _error = null;
    } catch (e) {
      _error = e.toString();
      _menus = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée ou met à jour un menu journalier
  Future<bool> saveMenu(MenuJournalier menu) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      MenuJournalier saved;
      if (menu.id > 0) {
        saved = await _apiService.updateMenuJournalier(menu.id, menu);
        final index = _menus.indexWhere((m) => m.id == saved.id);
        if (index >= 0) {
          _menus[index] = saved;
        } else {
          _menus.insert(0, saved);
        }
      } else {
        saved = await _apiService.createMenuJournalier(menu);
        _menus.insert(0, saved);
      }
      _menus.sort((a, b) => b.date.compareTo(a.date));
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Supprime un menu journalier
  Future<bool> deleteMenu(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteMenuJournalier(id);
      _menus.removeWhere((menu) => menu.id == id);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}



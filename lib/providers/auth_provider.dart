import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider pour la gestion de l'authentification
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService) {
    _checkSession();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Vérifie la session existante
  Future<void> _checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasSession = await _authService.checkSession();
      if (hasSession) {
        _user = _authService.currentUser;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Connexion
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(username, password);
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

  /// Déconnexion
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour les informations de l'utilisateur
  Future<void> updateUser(User updatedUser) async {
    _user = updatedUser;
    notifyListeners();
    // Mettre à jour dans le service d'authentification si nécessaire
    // await _authService.updateUser(updatedUser);
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}



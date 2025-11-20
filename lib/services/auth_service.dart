import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/constants.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Service d'authentification
class AuthService {
  final ApiService _apiService;
  User? _currentUser;
  String? _token;

  AuthService(this._apiService);

  /// Utilisateur actuellement connecté
  User? get currentUser => _currentUser;

  /// Token d'authentification
  String? get token => _token;

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Connexion
  Future<User> login(String username, String password) async {
    try {
      // Appel API réel
      final dio = _apiService.dio;
      final response = await dio.post(
        AppConstants.loginEndpoint,
        data: {'username': username, 'password': password},
      );

      // Vérifier que la réponse n'est pas une erreur
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Si c'est une erreur (contient 'detail' mais pas 'access')
        if (data.containsKey('detail') && !data.containsKey('access')) {
          throw data['detail'] as String;
        }
      }

      // Extraire le token et les données utilisateur
      final data = response.data as Map<String, dynamic>;
      // Try several common token keys returned by different backends
      _token = data['access'] as String? ??
          data['token'] as String? ??
          data['key'] as String? ??
          data['auth_token'] as String?;
      if (_token == null) {
        throw 'Token non reçu du serveur';
      }

      // Récupérer les informations utilisateur
      Map<String, dynamic> userData;
      if (data.containsKey('user') && data['user'] != null) {
        userData = data['user'] as Map<String, dynamic>;
      } else {
        // Si l'utilisateur n'est pas dans la réponse, le récupérer via /me
        final meResponse = await dio.get(
          '/auth/me/',
          options: Options(headers: {'Authorization': 'Bearer $_token'}),
        );
        userData = meResponse.data as Map<String, dynamic>;
      }

      _currentUser = User.fromJson(userData);

      // Sauvegarder dans le stockage local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _token!);
      await prefs.setString(
        AppConstants.userKey,
        jsonEncode(_currentUser!.toJson()),
      );

      // Configurer le token dans l'API service
      _apiService.setToken(_token!);

      return _currentUser!;
    } on DioException catch (e) {
      // Gestion spécifique des erreurs Dio
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          throw errorData['detail'] as String;
        }
        if (e.response?.statusCode == 401) {
          throw 'Identifiants incorrects';
        }
        throw 'Erreur de connexion: ${e.response?.statusCode}';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw 'Timeout: Vérifiez votre connexion internet';
      } else if (e.type == DioExceptionType.connectionError) {
        throw 'Erreur de connexion: Impossible de joindre le serveur';
      }
      throw 'Erreur de connexion: ${e.message}';
    } catch (e) {
      throw 'Erreur de connexion: ${e.toString()}';
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _apiService.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  /// Vérifie la session sauvegardée
  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(AppConstants.tokenKey);
      final savedUser = prefs.getString(AppConstants.userKey);

      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        try {
          _currentUser = User.fromJson(jsonDecode(savedUser));
        } catch (e) {
          // Si le parsing échoue, récupérer depuis l'API
          try {
            final dio = _apiService.dio;
            final response = await dio.get(
              '/auth/me',
              options: Options(headers: {'Authorization': 'Bearer $_token'}),
            );
            _currentUser = User.fromJson(response.data as Map<String, dynamic>);
          } catch (e) {
            // Si l'API échoue, la session est invalide
            await logout();
            return false;
          }
        }
        _apiService.setToken(_token!);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

import 'package:dio/dio.dart';
import 'dart:io';
import '../config/constants.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/menu_journalier.dart';
import '../models/menu_mensuel.dart';
import '../models/depense.dart';

/// Service pour les appels API
class ApiService {
  late final Dio _dio;
  String? _token;

  // Exposer dio pour auth_service
  Dio get dio => _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteur pour ajouter le token d'authentification
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Gestion des erreurs
          if (error.response?.statusCode == 401) {
            // Token expiré ou invalide
            _token = null;
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Définit le token d'authentification
  void setToken(String token) {
    _token = token;
  }

  /// Supprime le token
  void clearToken() {
    _token = null;
  }

  // ========== ÉLÈVES ==========

  /// Récupère la liste complète des élèves
  /// [classe] : Filtrer par nom de classe
  /// [actif] : Filtrer par statut actif (true/false)
  Future<List<Student>> getStudents({String? classe, bool? actif}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (classe != null) queryParams['classe'] = classe;
      if (actif != null) queryParams['actif'] = actif.toString();

      final response = await _dio.get(
        AppConstants.studentsEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère un élève par son ID
  Future<Student> getStudent(int id) async {
    try {
      final response = await _dio.get('${AppConstants.studentsEndpoint}$id/');
      return Student.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== PRÉSENCES ==========

  /// Enregistre une présence
  Future<Attendance> createAttendance(Attendance attendance) async {
    try {
      final response = await _dio.post(
        AppConstants.attendanceEndpoint,
        data: attendance.toJson(),
      );
      return Attendance.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Met à jour une présence
  Future<Attendance> updateAttendance(int id, Attendance attendance) async {
    try {
      final response = await _dio.put(
        '${AppConstants.attendanceEndpoint}$id/',
        data: attendance.toJson(),
      );
      return Attendance.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère les présences du jour
  Future<List<Attendance>> getTodayAttendance({RepasType? repas}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (repas != null) {
        queryParams['repas'] = repas.apiValue;
      }
      final response = await _dio.get(
        AppConstants.attendanceTodayEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Attendance.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupère l'historique d'un élève
  Future<List<Attendance>> getStudentAttendance(int studentId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.attendanceStudentEndpoint}$studentId/',
      );
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Attendance.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== MENUS JOURNALIERS ==========

  /// Récupère le menu du jour
  Future<MenuJournalier?> getTodayMenu() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _dio.get(
        '${AppConstants.menusJournalierEndpoint}?date=$today',
      );
      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return MenuJournalier.fromJson(data[0] as Map<String, dynamic>);
      } else if (data is Map<String, dynamic>) {
        return MenuJournalier.fromJson(data);
      }
      return null;
    } catch (e) {
      if ((e as DioException).response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  /// Récupère le menu d'une date spécifique
  Future<MenuJournalier?> getMenuByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _dio.get(
        '${AppConstants.menusJournalierEndpoint}?date=$dateStr',
      );
      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return MenuJournalier.fromJson(data[0] as Map<String, dynamic>);
      } else if (data is Map) {
        return MenuJournalier.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if ((e as DioException).response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  // ========== MENUS MENSUELS ==========

  /// Récupère les menus mensuels
  Future<List<MenuMensuel>> getMensuelsMenus({int? annee, int? mois}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (annee != null) queryParams['annee'] = annee;
      if (mois != null) queryParams['mois'] = mois;

      final response = await _dio.get(
        AppConstants.menusMensuelEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => MenuMensuel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== DÉPENSES ==========

  /// Récupère les dépenses
  Future<List<Depense>> getDepenses(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['date__gte'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['date__lte'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _dio.get(
        AppConstants.depensesEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Depense.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Crée une dépense
  Future<Depense> createDepense(Depense depense) async {
    try {
      final response = await _dio.post(
        AppConstants.depensesEndpoint,
        data: depense.toJson(),
      );
      return Depense.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Met à jour une dépense
  Future<Depense> updateDepense(int id, Depense depense) async {
    try {
      final response = await _dio.put(
        '${AppConstants.depensesEndpoint}$id/',
        data: depense.toJson(),
      );
      return Depense.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Supprime une dépense
  Future<void> deleteDepense(int id) async {
    try {
      await _dio.delete('${AppConstants.depensesEndpoint}$id/');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========== UPLOAD D'IMAGES ==========

  /// Upload une photo pour un élève
  Future<String> uploadStudentPhoto(int studentId, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.patch(
        '${AppConstants.studentsEndpoint}$studentId/',
        data: formData,
      );

      final photoUrl = response.data['photo'] as String?;
      if (photoUrl != null) {
        return photoUrl.startsWith('http')
            ? photoUrl
            : '${AppConstants.baseUrl.replaceAll('/api', '')}$photoUrl';
      }
      throw 'Photo non reçue du serveur';
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload un avatar pour l'utilisateur
  Future<String> uploadUserAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.patch(
        '/auth/me/',
        data: formData,
      );

      final avatarUrl = response.data['avatar'] as String?;
      if (avatarUrl != null) {
        return avatarUrl.startsWith('http')
            ? avatarUrl
            : '${AppConstants.baseUrl.replaceAll('/api', '')}$avatarUrl';
      }
      throw 'Avatar non reçu du serveur';
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Gestion des erreurs
  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'] as String;
        }
        if (data is Map && data.containsKey('error')) {
          return data['error'] as String;
        }
        return 'Erreur ${error.response?.statusCode}: ${error.response?.statusMessage}';
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Timeout: Vérifiez votre connexion internet';
      } else if (error.type == DioExceptionType.connectionError) {
        return 'Erreur de connexion: Impossible de joindre le serveur';
      }
      return error.message ?? 'Une erreur est survenue';
    }
    return error.toString();
  }
}

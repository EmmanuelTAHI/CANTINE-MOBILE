import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/depense_provider.dart';
import 'providers/menu_provider.dart';

/// Application principale
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation des services
    final apiService = ApiService();
    final authService = AuthService(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => StudentProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => DepenseProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => MenuProvider(apiService),
        ),
      ],
      child: MaterialApp.router(
        title: 'Cantine HEG',
        debugShowCheckedModeBanner: false,
        theme: HEGTheme.lightTheme,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}

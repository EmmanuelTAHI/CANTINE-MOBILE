import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/prestataire/dashboard_prestataire.dart';
import '../screens/prestataire/students_checklist_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/menu/menu_management_screen.dart';
import '../screens/menu/menu_today_screen.dart';
import '../screens/depenses/depenses_screen.dart';
import '../screens/reports/reports_screen.dart';

/// Configuration des routes de l'application
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String studentsChecklist = '/students-checklist';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String menuManagement = '/menu-management';
  static const String menuToday = '/menu-today';
  static const String depenses = '/depenses';
  static const String reports = '/reports';
  
  static GoRouter get router {
    return GoRouter(
      initialLocation: login,
      routes: [
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: dashboard,
          name: 'dashboard',
          builder: (context, state) => const DashboardPrestataireScreen(),
        ),
        GoRoute(
          path: studentsChecklist,
          name: 'students-checklist',
          builder: (context, state) => const StudentsChecklistScreen(),
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: menuManagement,
          name: 'menu-management',
          builder: (context, state) => const MenuManagementScreen(),
        ),
        GoRoute(
          path: menuToday,
          name: 'menu-today',
          builder: (context, state) => const MenuTodayScreen(),
        ),
        GoRoute(
          path: depenses,
          name: 'depenses',
          builder: (context, state) => const DepensesScreen(),
        ),
        GoRoute(
          path: reports,
          name: 'reports',
          builder: (context, state) => const ReportsScreen(),
        ),
      ],
    );
  }
}



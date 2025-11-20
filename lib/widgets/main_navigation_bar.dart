import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../routes/app_routes.dart';

/// Barre de navigation principale
class MainNavigationBar extends StatelessWidget {
  final String currentRoute;

  const MainNavigationBar({
    super.key,
    required this.currentRoute,
  });

  int _getCurrentIndex() {
    switch (currentRoute) {
      case AppRoutes.dashboard:
        return 0;
      case AppRoutes.studentsChecklist:
        return 1;
      case AppRoutes.menuToday:
        return 2;
      case AppRoutes.menuManagement:
        return 3;
      default:
        return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (currentRoute != AppRoutes.dashboard) {
          context.go(AppRoutes.dashboard);
        }
        break;
      case 1:
        if (currentRoute != AppRoutes.studentsChecklist) {
          context.go(AppRoutes.studentsChecklist);
        }
        break;
      case 2:
        if (currentRoute != AppRoutes.menuToday) {
          context.go(AppRoutes.menuToday);
        }
        break;
      case 3:
        if (currentRoute != AppRoutes.menuManagement) {
          context.go(AppRoutes.menuManagement);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex();
    
    // Masquer la barre sur certaines pages
    final hideOnRoutes = [
      AppRoutes.login,
      AppRoutes.profile,
      AppRoutes.settings,
    ];
    
    if (hideOnRoutes.contains(currentRoute)) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: HEGColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => _onItemTapped(context, 0),
              ),
              _buildNavItem(
                context,
                icon: Icons.checklist_outlined,
                activeIcon: Icons.checklist,
                label: 'Présences',
                isActive: currentIndex == 1,
                onTap: () => _onItemTapped(context, 1),
              ),
              _buildNavItem(
                context,
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
                label: 'Menu',
                isActive: currentIndex == 2,
                onTap: () => _onItemTapped(context, 2),
              ),
              _buildNavItem(
                context,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Gestion',
                isActive: currentIndex == 3,
                onTap: () => _onItemTapped(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? HEGColors.violet : HEGColors.gris,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? HEGColors.violet : HEGColors.gris,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



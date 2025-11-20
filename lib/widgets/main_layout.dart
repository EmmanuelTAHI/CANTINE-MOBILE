import 'package:flutter/material.dart';
import 'main_navigation_bar.dart';

/// Layout principal avec navigation bar
class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    // Déterminer si la navigation bar doit être affichée
    final showNavBar = !_shouldHideNavBar(currentRoute);

    return Scaffold(
      body: child,
      bottomNavigationBar: showNavBar
          ? MainNavigationBar(currentRoute: currentRoute)
          : null,
    );
  }

  bool _shouldHideNavBar(String route) {
    const hideRoutes = [
      '/login',
      '/profile',
      '/settings',
      '/depenses',
      '/reports',
    ];
    return hideRoutes.any((r) => route.startsWith(r));
  }
}


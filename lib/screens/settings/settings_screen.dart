import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

/// Écran de paramètres
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _language = 'fr';
  String _theme = 'light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _language = prefs.getString('language') ?? 'fr';
      _theme = prefs.getString('theme') ?? 'light';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HEGColors.error,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: HEGColors.violet,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Paramètres',
                style: TextStyle(
                  color: HEGColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HEGColors.violet,
                      HEGColors.violetDark,
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: HEGColors.white),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Notifications
                  _buildSettingsSection(
                    context,
                    title: 'Notifications',
                    children: [
                      _buildSwitchTile(
                        context,
                        icon: Icons.notifications_outlined,
                        title: 'Notifications push',
                        subtitle: 'Recevoir les notifications',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                          _saveSetting('notifications_enabled', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Sécurité
                  _buildSettingsSection(
                    context,
                    title: 'Sécurité',
                    children: [
                      _buildSwitchTile(
                        context,
                        icon: Icons.fingerprint_outlined,
                        title: 'Authentification biométrique',
                        subtitle: 'Utiliser l\'empreinte digitale ou Face ID',
                        value: _biometricEnabled,
                        onChanged: (value) {
                          setState(() => _biometricEnabled = value);
                          _saveSetting('biometric_enabled', value);
                        },
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        context,
                        icon: Icons.lock_outline,
                        title: 'Changer le mot de passe',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Changement de mot de passe à venir')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Préférences
                  _buildSettingsSection(
                    context,
                    title: 'Préférences',
                    children: [
                      _buildSelectionTile(
                        context,
                        icon: Icons.language_outlined,
                        title: 'Langue',
                        value: _language == 'fr' ? 'Français' : 'English',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Choisir la langue'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('Français'),
                                    trailing: _language == 'fr'
                                        ? const Icon(Icons.check, color: HEGColors.violet)
                                        : null,
                                    onTap: () {
                                      setState(() => _language = 'fr');
                                      _saveSetting('language', 'fr');
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: const Text('English'),
                                    trailing: _language == 'en'
                                        ? const Icon(Icons.check, color: HEGColors.violet)
                                        : null,
                                    onTap: () {
                                      setState(() => _language = 'en');
                                      _saveSetting('language', 'en');
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSelectionTile(
                        context,
                        icon: Icons.palette_outlined,
                        title: 'Thème',
                        value: _theme == 'light' ? 'Clair' : 'Sombre',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Choisir le thème'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('Clair'),
                                    trailing: _theme == 'light'
                                        ? const Icon(Icons.check, color: HEGColors.violet)
                                        : null,
                                    onTap: () {
                                      setState(() => _theme = 'light');
                                      _saveSetting('theme', 'light');
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: const Text('Sombre'),
                                    trailing: _theme == 'dark'
                                        ? const Icon(Icons.check, color: HEGColors.violet)
                                        : null,
                                    onTap: () {
                                      setState(() => _theme = 'dark');
                                      _saveSetting('theme', 'dark');
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // À propos
                  _buildSettingsSection(
                    context,
                    title: 'À propos',
                    children: [
                      _buildInfoTile(
                        context,
                        icon: Icons.info_outline,
                        title: 'Version',
                        value: AppConstants.appVersion,
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        context,
                        icon: Icons.description_outlined,
                        title: 'Politique de confidentialité',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Politique de confidentialité à venir')),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        context,
                        icon: Icons.description_outlined,
                        title: 'Conditions d\'utilisation',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Conditions d\'utilisation à venir')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Déconnexion
                  Container(
                    decoration: BoxDecoration(
                      color: HEGColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildActionTile(
                      context,
                      icon: Icons.logout,
                      title: 'Déconnexion',
                      textColor: HEGColors.error,
                      onTap: _handleLogout,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: HEGColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: HEGColors.violet,
                  ),
            ),
          ),
          Divider(height: 1, color: HEGColors.gris.withValues(alpha: 0.1)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HEGColors.violet.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: HEGColors.violet, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HEGColors.gris.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: HEGColors.violet,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (textColor ?? HEGColors.violet).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textColor ?? HEGColors.violet, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: HEGColors.gris.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HEGColors.violet.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: HEGColors.violet, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HEGColors.gris.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: HEGColors.gris.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HEGColors.violet.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: HEGColors.violet, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HEGColors.gris.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: HEGColors.gris.withValues(alpha: 0.1)),
    );
  }
}



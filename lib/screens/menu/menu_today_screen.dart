import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/menu_provider.dart';
import '../../models/menu_journalier.dart';
import '../../config/constants.dart';
import '../../widgets/main_navigation_bar.dart';
import '../../routes/app_routes.dart';

/// Écran du menu du jour
class MenuTodayScreen extends StatefulWidget {
  const MenuTodayScreen({super.key});

  @override
  State<MenuTodayScreen> createState() => _MenuTodayScreenState();
}

class _MenuTodayScreenState extends State<MenuTodayScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenu();
    });
  }

  void _loadMenu() {
    final provider = Provider.of<MenuProvider>(context, listen: false);
    provider.loadMenuByDate(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HEGColors.violet,
              onPrimary: HEGColors.white,
              onSurface: HEGColors.gris,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MainNavigationBar(currentRoute: AppRoutes.menuToday),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: HEGColors.violet,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Menu du jour',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today, color: HEGColors.white),
                onPressed: () => _selectDate(context),
                tooltip: 'Changer la date',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer<MenuProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                color: HEGColors.error, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              provider.error!,
                              style: const TextStyle(color: HEGColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMenu,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final menu = provider.todayMenu;
                  if (menu == null) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: HEGColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 64,
                            color: HEGColors.gris.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun menu disponible',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun menu n\'a été prévu pour cette date',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: HEGColors.gris.withValues(alpha: 0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildMenuCard(context, menu);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, MenuJournalier menu) {
    final photoUrl = menu.photo != null
        ? menu.photo!.startsWith('http')
            ? menu.photo!
            : '${AppConstants.baseUrl.replaceAll('/api', '')}${menu.photo}'
        : null;

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
          // Photo du menu
          if (photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: HEGColors.grisClair,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: HEGColors.grisClair,
                  child: const Icon(Icons.image_not_supported, size: 64),
                ),
              ),
            ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 18, color: HEGColors.gris.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                          .format(menu.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HEGColors.gris.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Entrée
                if (menu.entree != null && menu.entree!.isNotEmpty) ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.restaurant_menu,
                    label: 'Entrée',
                    value: menu.entree!,
                    color: HEGColors.violet,
                  ),
                  const SizedBox(height: 16),
                ],
                // Plat principal
                _buildMenuItem(
                  context,
                  icon: Icons.restaurant,
                  label: 'Plat principal',
                  value: menu.platPrincipal,
                  color: HEGColors.violetDark,
                  isMain: true,
                ),
                // Accompagnement
                if (menu.accompagnement != null &&
                    menu.accompagnement!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.set_meal,
                    label: 'Accompagnement',
                    value: menu.accompagnement!,
                    color: HEGColors.success,
                  ),
                ],
                // Dessert
                if (menu.dessert != null && menu.dessert!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.cake,
                    label: 'Dessert',
                    value: menu.dessert!,
                    color: HEGColors.warning,
                  ),
                ],
                // Boisson
                if (menu.boisson != null && menu.boisson!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.local_drink,
                    label: 'Boisson',
                    value: menu.boisson!,
                    color: HEGColors.violet,
                  ),
                ],
                // Commentaires
                if (menu.commentaires != null &&
                    menu.commentaires!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: HEGColors.gris.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note,
                          size: 20, color: HEGColors.gris.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          menu.commentaires!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMain = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: isMain
            ? Border.all(color: color.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
                        fontSize: isMain ? 16 : 14,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



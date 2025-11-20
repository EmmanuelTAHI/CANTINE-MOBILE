import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../models/menu.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/main_navigation_bar.dart';
import '../../routes/app_routes.dart';

/// Écran de gestion des menus
class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _platPrincipalController = TextEditingController();
  final TextEditingController _entreeController = TextEditingController();
  final TextEditingController _dessertController = TextEditingController();
  final TextEditingController _accompagnementController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _disponible = true;
  List<Menu> _menus = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMenus());
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _platPrincipalController.dispose();
    _entreeController.dispose();
    _dessertController.dispose();
    _accompagnementController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    final provider = Provider.of<MenuProvider>(context, listen: false);
    try {
      await provider.loadMenuByDate(_selectedDate);
      final mj = provider.todayMenu;
      setState(() {
        if (mj != null) {
          _menus = [
            Menu(
              id: mj.id,
              date: mj.date,
              titre: 'Menu du ${DateFormat('dd/MM/yyyy').format(mj.date)}',
              description: mj.commentaires ?? '',
              platPrincipal: mj.platPrincipal,
              entree: mj.entree,
              dessert: mj.dessert,
              accompagnement: mj.accompagnement,
              disponible: true,
              prix: null,
            )
          ];
        } else {
          _menus = [];
        }
      });
    } catch (_) {
      setState(() {
        _menus = [];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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
    }
  }

  void _showMenuForm({Menu? menu}) {
    if (menu != null) {
      _titreController.text = menu.titre;
      _descriptionController.text = menu.description;
      _platPrincipalController.text = menu.platPrincipal;
      _entreeController.text = menu.entree ?? '';
      _dessertController.text = menu.dessert ?? '';
      _accompagnementController.text = menu.accompagnement ?? '';
      _prixController.text = menu.prix?.toString() ?? '';
      _selectedDate = menu.date;
      _disponible = menu.disponible;
    } else {
      _titreController.clear();
      _descriptionController.clear();
      _platPrincipalController.clear();
      _entreeController.clear();
      _dessertController.clear();
      _accompagnementController.clear();
      _prixController.clear();
      _selectedDate = DateTime.now();
      _disponible = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: HEGColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HEGColors.gris.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    menu != null ? 'Modifier le menu' : 'Nouveau menu',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date
                    _buildFormField(
                      context,
                      label: 'Date',
                      controller: TextEditingController(
                        text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                      ),
                      enabled: false,
                      suffixIcon: Icons.calendar_today,
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    // Titre
                    _buildFormField(
                      context,
                      label: 'Titre du menu',
                      controller: _titreController,
                      hint: 'Ex: Menu du jour',
                    ),
                    const SizedBox(height: 16),
                    // Description
                    _buildFormField(
                      context,
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'Description du menu',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Plat principal
                    _buildFormField(
                      context,
                      label: 'Plat principal *',
                      controller: _platPrincipalController,
                      hint: 'Ex: Poulet rôti',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    // Entrée
                    _buildFormField(
                      context,
                      label: 'Entrée',
                      controller: _entreeController,
                      hint: 'Ex: Salade verte',
                    ),
                    const SizedBox(height: 16),
                    // Dessert
                    _buildFormField(
                      context,
                      label: 'Dessert',
                      controller: _dessertController,
                      hint: 'Ex: Tarte aux pommes',
                    ),
                    const SizedBox(height: 16),
                    // Accompagnement
                    _buildFormField(
                      context,
                      label: 'Accompagnement',
                      controller: _accompagnementController,
                      hint: 'Ex: Riz, Légumes',
                    ),
                    const SizedBox(height: 16),
                    // Prix
                    _buildFormField(
                      context,
                      label: 'Prix (CHF)',
                      controller: _prixController,
                      hint: 'Ex: 12.50',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    // Disponible
                    SwitchListTile(
                      title: const Text('Menu disponible'),
                      subtitle: const Text('Le menu sera visible pour les élèves'),
                      value: _disponible,
                      onChanged: (value) {
                        setState(() => _disponible = value);
                      },
                      activeColor: HEGColors.violet,
                    ),
                    const SizedBox(height: 32),
                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: HEGColors.gris.withValues(alpha: 0.3)),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              _saveMenu(menu);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HEGColors.violet,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Enregistrer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? hint,
    bool enabled = true,
    IconData? suffixIcon,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: HEGColors.error),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          onTap: onTap,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: HEGColors.gris.withValues(alpha: 0.5))
                : null,
            filled: true,
            fillColor: enabled ? HEGColors.white : HEGColors.grisClair,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HEGColors.gris.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HEGColors.gris.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HEGColors.violet, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _saveMenu(Menu? menu) {
    if (_platPrincipalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le plat principal est requis'),
          backgroundColor: HEGColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final provider = Provider.of<MenuProvider>(context, listen: false);

    final payload = {
      'date': _selectedDate.toIso8601String().split('T')[0],
      'entree': _entreeController.text,
      'plat_principal': _platPrincipalController.text,
      'accompagnement': _accompagnementController.text,
      'dessert': _dessertController.text,
      'boisson': '',
      'commentaires': _descriptionController.text,
    };
    try {
      // ignore: avoid_print
      print('[MenuManagementScreen] saveMenu payload: $payload');
    } catch (_) {}

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Enregistrement du menu...'),
              ],
            ),
          ),
        );
      },
    );

    // Try create first, fallback to update if duplicate date error
    provider.createJournalierMenu(payload)
        .then((created) {
          if (!mounted) return;
          
          try {
            // ignore: avoid_print
            print('[MenuManagementScreen] Menu créé avec succès: id=${created?.id}');
          } catch (_) {}
          
          // Close loading dialog
          Navigator.of(context, rootNavigator: true).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu créé avec succès!'),
              backgroundColor: HEGColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          
          _loadMenus();
          
          // Close the form after a short delay to ensure UI updates
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && context.mounted) {
              Navigator.of(context, rootNavigator: false).maybePop();
            }
          });
        })
        .catchError((err) {
          if (!mounted) {
            return null;
          }
          
          // Check if error is due to duplicate date
          final errStr = err.toString();
          if (errStr.contains('existe déjà') || 
              errStr.contains('duplicate') || 
              errStr.contains('unique') ||
              errStr.contains('Un menu existe')) {
            try {
              // ignore: avoid_print
              print('[MenuManagementScreen] Duplicate date detected, attempting update...');
            } catch (_) {}
            
            // Close loading dialog first
            Navigator.of(context, rootNavigator: true).pop();
            
            // Load the existing menu first, then update it
            provider.loadMenuByDate(_selectedDate).then((_) {
              // If menu exists, get its ID and update
              if (provider.todayMenu != null) {
                final existingId = provider.todayMenu!.id;
                
                // Show loading again for update
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Dialog(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Mise à jour du menu...'),
                          ],
                        ),
                      ),
                    );
                  },
                );
                
                return provider.updateJournalierMenu(existingId, payload)
                    .then((updated) {
                      if (!mounted) return;
                      
                      try {
                        // ignore: avoid_print
                        print('[MenuManagementScreen] Menu mis à jour avec succès: id=${updated?.id}');
                      } catch (_) {}
                      
                      // Close loading dialog
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menu mis à jour avec succès!'),
                          backgroundColor: HEGColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      _loadMenus();
                      
                      // Close the form after a short delay
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted && context.mounted) {
                          Navigator.of(context, rootNavigator: false).maybePop();
                        }
                      });
                    })
                    .catchError((updateErr) {
                      if (!mounted) return;
                      
                      try {
                        // ignore: avoid_print
                        print('[MenuManagementScreen] Erreur mise à jour menu: $updateErr');
                      } catch (_) {}
                      
                      // Close loading dialog
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la mise à jour: $updateErr'),
                          backgroundColor: HEGColors.error,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    });
              } else {
                // Can't find menu to update, show error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Un menu existe déjà pour cette date. Veuillez choisir une autre date.'),
                    backgroundColor: HEGColors.error,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            });
          } else {
            // Show error for non-duplicate errors
            try {
              // ignore: avoid_print
              print('[MenuManagementScreen] Erreur sauvegarde menu: $err');
            } catch (_) {}
            
            // Close loading dialog
            Navigator.of(context, rootNavigator: true).pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $err'),
                backgroundColor: HEGColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MainNavigationBar(currentRoute: AppRoutes.menuManagement),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: HEGColors.violet,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Gestion des menus',
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
                icon: const Icon(Icons.add, color: HEGColors.white),
                onPressed: () => _showMenuForm(),
                tooltip: 'Nouveau menu',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _menus.isEmpty
                  ? _buildEmptyState(context)
                  : Column(
                      children: _menus.map((menu) => _buildMenuCard(context, menu)).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 80,
            color: HEGColors.gris.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun menu',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier menu pour commencer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HEGColors.gris.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showMenuForm(),
            icon: const Icon(Icons.add),
            label: const Text('Créer un menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HEGColors.violet,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, Menu menu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _showMenuForm(menu: menu),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.titre,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: HEGColors.violet,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMMM yyyy', 'fr_FR').format(menu.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: HEGColors.gris.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: menu.disponible
                          ? HEGColors.success.withValues(alpha: 0.1)
                          : HEGColors.gris.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      menu.disponible ? 'Disponible' : 'Indisponible',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: menu.disponible ? HEGColors.success : HEGColors.gris,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              if (menu.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  menu.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Divider(height: 1, color: HEGColors.gris.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.restaurant, color: HEGColors.violet, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plat principal: ${menu.platPrincipal}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (menu.prix != null) ...[
                    Text(
                      '${menu.prix!.toStringAsFixed(2)} CHF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: HEGColors.violet,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ],
              ),
              if (menu.entree != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.set_meal, color: HEGColors.gris.withValues(alpha: 0.6), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Entrée: ${menu.entree}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (menu.dessert != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.cake, color: HEGColors.gris.withValues(alpha: 0.6), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Dessert: ${menu.dessert}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


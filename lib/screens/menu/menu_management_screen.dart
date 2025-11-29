import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/menu_journalier.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _platPrincipalController = TextEditingController();
  final TextEditingController _entreeController = TextEditingController();
  final TextEditingController _accompagnementController = TextEditingController();
  final TextEditingController _dessertController = TextEditingController();
  final TextEditingController _boissonController = TextEditingController();
  final TextEditingController _commentairesController = TextEditingController();

  DateTime _formDate = DateTime.now();
  MenuJournalier? _editingMenu;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenus();
    });
  }

  @override
  void dispose() {
    _platPrincipalController.dispose();
    _entreeController.dispose();
    _accompagnementController.dispose();
    _dessertController.dispose();
    _boissonController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  Future<void> _loadMenus() async {
    final provider = Provider.of<MenuProvider>(context, listen: false);
    await provider.loadMenus(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  void _openMenuForm({MenuJournalier? menu}) {
    setState(() {
      _editingMenu = menu;
      _formDate = menu?.date ?? DateTime.now();
      _platPrincipalController.text = menu?.platPrincipal ?? '';
      _entreeController.text = menu?.entree ?? '';
      _accompagnementController.text = menu?.accompagnement ?? '';
      _dessertController.text = menu?.dessert ?? '';
      _boissonController.text = menu?.boisson ?? '';
      _commentairesController.text = menu?.commentaires ?? '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Container(
            height: mediaQuery.size.height * 0.9,
            decoration: BoxDecoration(
              color: HEGColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HEGColors.gris.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDateField(context),
                          const SizedBox(height: 16),
                          _buildFormField(
                            context,
                            label: 'Plat principal *',
                            controller: _platPrincipalController,
                            hint: 'Ex: Riz au poisson',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le plat principal est requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            context,
                            label: 'Entrée',
                            controller: _entreeController,
                            hint: 'Ex: Salade de crudités',
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            context,
                            label: 'Accompagnement',
                            controller: _accompagnementController,
                            hint: 'Ex: Légumes sautés',
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            context,
                            label: 'Dessert',
                            controller: _dessertController,
                            hint: 'Ex: Fruits frais',
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            context,
                            label: 'Boisson',
                            controller: _boissonController,
                            hint: 'Ex: Jus de bissap',
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            context,
                            label: 'Commentaires',
                            controller: _commentairesController,
                            maxLines: 3,
                            hint: 'Informations complémentaires',
                          ),
                          const SizedBox(height: 32),
                          Consumer<MenuProvider>(
                            builder: (context, provider, _) {
                              final isSaving = provider.isSaving;
                              return Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: isSaving ? null : () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: BorderSide(
                                          color: HEGColors.gris.withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Text('Annuler'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: isSaving ? null : () => _saveMenu(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: HEGColors.violet,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      icon: isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: HEGColors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save),
                                      label: Text(menu != null ? 'Mettre à jour' : 'Créer'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date *',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectFormDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: HEGColors.grisClair,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HEGColors.gris.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: HEGColors.violet),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_formDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectFormDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _formDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
    if (picked != null && picked != _formDate) {
      setState(() {
        _formDate = picked;
      });
    }
  }

  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: HEGColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HEGColors.gris.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HEGColors.gris.withOpacity(0.3)),
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

  Future<void> _saveMenu() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = Provider.of<MenuProvider>(context, listen: false);

    final menu = MenuJournalier(
      id: _editingMenu?.id ?? 0,
      date: DateTime(_formDate.year, _formDate.month, _formDate.day),
      entree: _emptyToNull(_entreeController.text),
      platPrincipal: _platPrincipalController.text.trim(),
      accompagnement: _emptyToNull(_accompagnementController.text),
      dessert: _emptyToNull(_dessertController.text),
      boisson: _emptyToNull(_boissonController.text),
      commentaires: _emptyToNull(_commentairesController.text),
      photo: _editingMenu?.photo,
    );

    final success = await provider.saveMenu(menu);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingMenu == null ? 'Menu créé avec succès' : 'Menu mis à jour'),
          backgroundColor: HEGColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Impossible de sauvegarder le menu'),
          backgroundColor: HEGColors.error,
        ),
      );
    }
  }

  String? _emptyToNull(String value) {
    return value.trim().isEmpty ? null : value.trim();
  }

  Future<void> _confirmDelete(MenuJournalier menu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le menu'),
        content: Text(
          'Confirmez-vous la suppression du menu du ${DateFormat('dd/MM/yyyy').format(menu.date)} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: HEGColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<MenuProvider>(context, listen: false);
      final success = await provider.deleteMenu(menu.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu supprimé'),
            backgroundColor: HEGColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Suppression impossible'),
            backgroundColor: HEGColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MainNavigationBar(currentRoute: AppRoutes.menuManagement),
      body: RefreshIndicator(
        color: HEGColors.violet,
        onRefresh: _loadMenus,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  onPressed: () => _openMenuForm(),
                  tooltip: 'Nouveau menu',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Consumer<MenuProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.menus.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (provider.error != null && provider.menus.isEmpty) {
                      return Column(
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: HEGColors.error.withOpacity(0.8)),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: HEGColors.error),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMenus,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      );
                    }

                    if (provider.menus.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return Column(
                      children: provider.menus
                          .map((menu) => _buildMenuCard(context, menu))
                          .toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
            color: HEGColors.gris.withOpacity(0.3),
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
                  color: HEGColors.gris.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openMenuForm(),
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

  Widget _buildMenuCard(BuildContext context, MenuJournalier menu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: HEGColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                        DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(menu.date),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: HEGColors.violet,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        menu.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HEGColors.gris.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: () => _openMenuForm(menu: menu),
                      icon: const Icon(Icons.edit, color: HEGColors.violet),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => _confirmDelete(menu),
                      icon: const Icon(Icons.delete, color: HEGColors.error),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMenuRow(
              context,
              icon: Icons.restaurant,
              label: 'Plat principal',
              value: menu.platPrincipal,
              color: HEGColors.violetDark,
              isBold: true,
            ),
            if (menu.entree != null && menu.entree!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildMenuRow(
                context,
                icon: Icons.restaurant_menu,
                label: 'Entrée',
                value: menu.entree!,
              ),
            ],
            if (menu.accompagnement != null && menu.accompagnement!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildMenuRow(
                context,
                icon: Icons.set_meal,
                label: 'Accompagnement',
                value: menu.accompagnement!,
              ),
            ],
            if (menu.dessert != null && menu.dessert!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildMenuRow(
                context,
                icon: Icons.cake,
                label: 'Dessert',
                value: menu.dessert!,
              ),
            ],
            if (menu.boisson != null && menu.boisson!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildMenuRow(
                context,
                icon: Icons.local_drink,
                label: 'Boisson',
                value: menu.boisson!,
              ),
            ],
            if (menu.commentaires != null && menu.commentaires!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: HEGColors.gris.withOpacity(0.1)),
              const SizedBox(height: 8),
              _buildMenuRow(
                context,
                icon: Icons.info_outline,
                label: 'Commentaires',
                value: menu.commentaires!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color color = HEGColors.gris,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


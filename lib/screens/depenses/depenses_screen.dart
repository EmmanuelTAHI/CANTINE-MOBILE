import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/depense_provider.dart';
import '../../models/depense.dart';

/// Écran de gestion des dépenses
class DepensesScreen extends StatefulWidget {
  const DepensesScreen({super.key});

  @override
  State<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends State<DepensesScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  CategorieDepense? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDepenses();
    });
  }

  void _loadDepenses() {
    final provider = Provider.of<DepenseProvider>(context, listen: false);
    provider.loadDepenses(startDate: _startDate, endDate: _endDate);
  }

  void _showAddDepenseDialog({Depense? depense}) {
    final formKey = GlobalKey<FormState>();
    final libelleController = TextEditingController(text: depense?.libelle ?? '');
    final montantController = TextEditingController(text: depense?.montant.toString() ?? '');
    final notesController = TextEditingController(text: depense?.notes ?? '');
    CategorieDepense categorie = depense?.categorie ?? CategorieDepense.ingredients;
    DateTime selectedDate = depense?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(depense != null ? 'Modifier la dépense' : 'Nouvelle dépense'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: libelleController,
                    decoration: const InputDecoration(
                      labelText: 'Libellé *',
                      hintText: 'Ex: Achat de riz',
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CategorieDepense>(
                    value: categorie,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: CategorieDepense.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => categorie = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: montantController,
                    decoration: const InputDecoration(
                      labelText: 'Montant (CHF) *',
                      hintText: '0.00',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Requis';
                      if (double.tryParse(value!) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optionnel)',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final provider = Provider.of<DepenseProvider>(context, listen: false);
                  final newDepense = Depense(
                    id: depense?.id ?? 0,
                    libelle: libelleController.text,
                    categorie: categorie,
                    montant: double.parse(montantController.text),
                    date: selectedDate,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );

                  bool success;
                  if (depense != null) {
                    success = await provider.updateDepense(depense.id, newDepense);
                  } else {
                    success = await provider.addDepense(newDepense);
                  }

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(depense != null ? 'Dépense modifiée' : 'Dépense ajoutée'),
                        backgroundColor: HEGColors.success,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? 'Erreur'),
                        backgroundColor: HEGColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
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
                'Gestion des dépenses',
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
                icon: const Icon(Icons.filter_list, color: HEGColors.white),
                onPressed: _showFilterDialog,
                tooltip: 'Filtres',
              ),
              IconButton(
                icon: const Icon(Icons.add, color: HEGColors.white),
                onPressed: () => _showAddDepenseDialog(),
                tooltip: 'Ajouter une dépense',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSummary(context),
                  const SizedBox(height: 20),
                  _buildDepensesList(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Consumer<DepenseProvider>(
      builder: (context, provider, child) {
        final total = provider.totalDepenses;
        final today = provider.getTotalJour(DateTime.now());
        final thisMonth = provider.getTotalMois(
          DateTime.now().month,
          DateTime.now().year,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HEGColors.violet.withOpacity(0.1),
                HEGColors.violetDark.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HEGColors.violet.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Résumé financier',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HEGColors.violet,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Aujourd\'hui',
                      today.toStringAsFixed(2),
                      Icons.today,
                      HEGColors.violet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Ce mois',
                      thisMonth.toStringAsFixed(2),
                      Icons.calendar_month,
                      HEGColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HEGColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total général',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} CHF',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: HEGColors.violet,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HEGColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$value CHF',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HEGColors.gris.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepensesList(BuildContext context) {
    return Consumer<DepenseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: HEGColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: const TextStyle(color: HEGColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDepenses,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        var depenses = provider.depenses;
        if (_selectedCategory != null) {
          depenses = depenses.where((d) => d.categorie == _selectedCategory).toList();
        }

        if (depenses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: HEGColors.gris.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune dépense',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez votre première dépense',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HEGColors.gris.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dépenses (${depenses.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_selectedCategory != null)
                  Chip(
                    label: Text(_selectedCategory!.displayName),
                    onDeleted: () {
                      setState(() => _selectedCategory = null);
                      _loadDepenses();
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...depenses.map((depense) => _buildDepenseCard(context, depense, provider)),
          ],
        );
      },
    );
  }

  Widget _buildDepenseCard(
    BuildContext context,
    Depense depense,
    DepenseProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HEGColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HEGColors.violet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(depense.categorie),
            color: HEGColors.violet,
            size: 24,
          ),
        ),
        title: Text(
          depense.libelle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: HEGColors.violet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    depense.categorie.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HEGColors.violet,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(depense.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HEGColors.gris.withOpacity(0.7),
                      ),
                ),
              ],
            ),
            if (depense.notes != null && depense.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                depense.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${depense.montant.toStringAsFixed(2)} CHF',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: HEGColors.violet,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      _showAddDepenseDialog(depense: depense);
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: HEGColors.error),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: HEGColors.error)),
                    ],
                  ),
                  onTap: () async {
                    Future.delayed(Duration.zero, () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer'),
                          content: const Text('Êtes-vous sûr de vouloir supprimer cette dépense ?'),
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
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        final success = await provider.deleteDepense(depense.id);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dépense supprimée'),
                              backgroundColor: HEGColors.success,
                            ),
                          );
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(CategorieDepense categorie) {
    switch (categorie) {
      case CategorieDepense.ingredients:
        return Icons.restaurant;
      case CategorieDepense.gaz:
        return Icons.local_gas_station;
      case CategorieDepense.mainOeuvre:
        return Icons.people;
      case CategorieDepense.logistique:
        return Icons.local_shipping;
      case CategorieDepense.autre:
        return Icons.category;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtres'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Période'),
                subtitle: Text(
                  _startDate != null && _endDate != null
                      ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                      : 'Toutes les dates',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _startDate != null && _endDate != null
                        ? DateTimeRange(start: _startDate!, end: _endDate!)
                        : null,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                  }
                },
              ),
              DropdownButtonFormField<CategorieDepense?>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes les catégories')),
                  ...CategorieDepense.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.displayName),
                    );
                  }),
                ],
                onChanged: (value) {
                  setDialogState(() => _selectedCategory = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _startDate = null;
                  _endDate = null;
                  _selectedCategory = null;
                });
              },
              child: const Text('Réinitialiser'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadDepenses();
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }
}



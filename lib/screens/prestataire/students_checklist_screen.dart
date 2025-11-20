import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../models/attendance.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/student_card.dart';
import '../../widgets/main_navigation_bar.dart';
import '../../routes/app_routes.dart';

/// Écran de checklist des présences
class StudentsChecklistScreen extends StatefulWidget {
  const StudentsChecklistScreen({super.key});

  @override
  State<StudentsChecklistScreen> createState() =>
      _StudentsChecklistScreenState();
}

class _StudentsChecklistScreenState extends State<StudentsChecklistScreen> {
  final Map<String, bool> _checkedStudents = {}; // Clé: '${studentId}_${repas.apiValue}'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClasse;
  RepasType _selectedRepas = RepasType.dejeuner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    await studentProvider.loadStudents();
    await attendanceProvider.loadTodayAttendance(repas: _selectedRepas);
    
    // Réinitialiser les cases cochées
    _checkedStudents.clear();
    
    // Initialiser les cases cochées avec les présences du jour pour le repas sélectionné
    final todayAttendance = attendanceProvider.getTodayAttendanceByRepas(_selectedRepas);
    for (var attendance in todayAttendance) {
      if (attendance.present) {
        final key = '${attendance.studentId}_${attendance.repas.apiValue}';
        _checkedStudents[key] = true;
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleCheckChanged(int studentId, bool isChecked) async {
    final key = '${studentId}_${_selectedRepas.apiValue}';
    
    // Mise à jour optimiste de l'UI
    if (mounted) {
      setState(() {
        _checkedStudents[key] = isChecked;
      });
    }

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final today = DateTime.now();

    // Vérifier si une présence existe déjà pour ce repas et cette date
    final existingAttendance = attendanceProvider.todayAttendance.firstWhere(
      (a) => a.studentId == studentId && 
             a.repas == _selectedRepas &&
             a.date.year == today.year &&
             a.date.month == today.month &&
             a.date.day == today.day,
      orElse: () => Attendance(
        id: 0,
        studentId: studentId,
        date: today,
        repas: _selectedRepas,
        present: false,
      ),
    );

    final attendance = Attendance.create(
      studentId: studentId,
      date: today,
      repas: _selectedRepas,
      present: isChecked,
    );

    bool success = false;
    try {
      if (existingAttendance.id > 0) {
        success = await attendanceProvider.updateAttendance(
          existingAttendance.id,
          attendance,
        );
      } else {
        success = await attendanceProvider.markAttendance(attendance);
      }
      
      // Recharger les données pour synchroniser
      if (success) {
        // Keep optimistic UI state (already set above). Refresh in background
        // but do not overwrite the optimistic state if the server response
        // doesn't return any records (avoid UI flicker).
        if (mounted) setState(() {});

        await attendanceProvider.loadTodayAttendance(repas: _selectedRepas);
        final todayAttendance = attendanceProvider.getTodayAttendanceByRepas(_selectedRepas);
        if (todayAttendance.isNotEmpty) {
          // Replace local mapping only if server returned records
          _checkedStudents.clear();
          for (var att in todayAttendance) {
            if (att.present) {
              final attKey = '${att.studentId}_${att.repas.apiValue}';
              _checkedStudents[attKey] = true;
            }
          }
          if (mounted) setState(() {});
        } // else keep optimistic state
      }
    } catch (e) {
      success = false;
    }

    if (mounted) {
      if (!success) {
        // Revenir en arrière en cas d'erreur
        setState(() {
          _checkedStudents[key] = !isChecked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${attendanceProvider.error ?? "Impossible d'enregistrer"}'),
            backgroundColor: HEGColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {}); // Mettre à jour l'UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isChecked ? 'Présence enregistrée ✓' : 'Absence enregistrée',
            ),
            backgroundColor: HEGColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  List<Student> _getFilteredStudents(List<Student> students) {
    var filtered = students;

    // Filtrer par classe
    if (_selectedClasse != null && _selectedClasse!.isNotEmpty) {
      filtered = filtered.where((student) {
        final studentClasse = student.classeNom ?? student.classe;
        return studentClasse == _selectedClasse;
      }).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        final fullName = student.fullName.toLowerCase();
        final matricule = student.matricule.toLowerCase();
        final classe = (student.classeNom ?? student.classe ?? '').toLowerCase();
        return fullName.contains(_searchQuery) ||
            matricule.contains(_searchQuery) ||
            classe.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marquer les présences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
            tooltip: 'Filtres',
          ),
        ],
      ),
      bottomNavigationBar: MainNavigationBar(currentRoute: AppRoutes.studentsChecklist),
      body: Column(
        children: [
          // Barre de sélection du repas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: HEGColors.violet.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, color: HEGColors.violet),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<RepasType>(
                    segments: RepasType.values.map((repas) {
                      return ButtonSegment(
                        value: repas,
                        label: Text(repas.displayName),
                      );
                    }).toList(),
                    selected: {_selectedRepas},
                    onSelectionChanged: (Set<RepasType> newSelection) {
                      setState(() {
                        _selectedRepas = newSelection.first;
                      });
                      _loadData(); // Recharger les données après changement de repas
                    },
                  ),
                ),
              ],
            ),
          ),
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un élève...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filtre par classe (si sélectionné)
          if (_selectedClasse != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: HEGColors.grisClair,
              child: Row(
                children: [
                  Chip(
                    label: Text('Classe: $_selectedClasse'),
                    onDeleted: () {
                      setState(() {
                        _selectedClasse = null;
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          // Liste des élèves
          Expanded(
            child: Consumer2<StudentProvider, AttendanceProvider>(
              builder: (context, studentProvider, attendanceProvider, child) {
                if (studentProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (studentProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: HEGColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          studentProvider.error!,
                          style: const TextStyle(color: HEGColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final students = _getFilteredStudents(
                  studentProvider.activeStudents,
                );

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: HEGColors.gris.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty && _selectedClasse == null
                              ? 'Aucun élève inscrit'
                              : 'Aucun élève trouvé',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                // Compteur
                final checkedCount = _checkedStudents.values
                    .where((checked) => checked)
                    .length;

                return Column(
                  children: [
                    // Compteur de présences
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: HEGColors.violet.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${students.length} élève${students.length > 1 ? 's' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: HEGColors.violet,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '$checkedCount présent${checkedCount > 1 ? 's' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: HEGColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Liste
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final key = '${student.id}_${_selectedRepas.apiValue}';
                          final isChecked = _checkedStudents[key] ?? false;

                          return StudentCard(
                            student: student,
                            isChecked: isChecked,
                            onCheckedChanged: (checked) {
                              _handleCheckChanged(student.id, checked);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtres'),
          content: Consumer<StudentProvider>(
            builder: (context, provider, child) {
              final classes = provider.classes;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    value: _selectedClasse,
                    decoration: const InputDecoration(labelText: 'Classe'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes les classes')),
                      ...classes.map((classe) {
                        return DropdownMenuItem(
                          value: classe,
                          child: Text(classe),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _selectedClasse = value);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedClasse = null;
                });
              },
              child: const Text('Réinitialiser'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/depense_provider.dart';
import '../../models/attendance.dart';

/// Écran de rapports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();
  RepasType _selectedRepas = RepasType.dejeuner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final depenseProvider = Provider.of<DepenseProvider>(context, listen: false);

    attendanceProvider.loadTodayAttendance();
    studentProvider.loadStudents();
    depenseProvider.loadDepenses();
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
                'Rapports',
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
                  _buildReportTypeSelector(context),
                  const SizedBox(height: 20),
                  _buildReportsContent(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HEGColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildReportTab(
              context,
              'Journalier',
              Icons.today,
              () => setState(() {}),
            ),
          ),
          Expanded(
            child: _buildReportTab(
              context,
              'Mensuel',
              Icons.calendar_month,
              () => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTab(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: HEGColors.violet),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HEGColors.violet,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsContent(BuildContext context) {
    return Column(
      children: [
        _buildDailyReport(context),
        const SizedBox(height: 20),
        _buildMonthlyReport(context),
      ],
    );
  }

  Widget _buildDailyReport(BuildContext context) {
    return Consumer2<AttendanceProvider, StudentProvider>(
      builder: (context, attendanceProvider, studentProvider, child) {
        final presentCount = attendanceProvider.getPresentCount(_selectedRepas);
        final totalStudents = studentProvider.activeStudents.length;
        final absentCount = totalStudents - presentCount;

        return Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HEGColors.violet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.today, color: HEGColors.violet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rapport journalier',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: HEGColors.gris.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<RepasType>(
                    value: _selectedRepas,
                    items: RepasType.values.map((repas) {
                      return DropdownMenuItem(
                        value: repas,
                        child: Text(repas.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRepas = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      context,
                      'Présents',
                      presentCount.toString(),
                      Icons.check_circle,
                      HEGColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      context,
                      'Absents',
                      absentCount.toString(),
                      Icons.cancel,
                      HEGColors.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      context,
                      'Total',
                      totalStudents.toString(),
                      Icons.people,
                      HEGColors.violet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HEGColors.grisClair,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Taux de présence',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      totalStudents > 0
                          ? '${((presentCount / totalStudents) * 100).toStringAsFixed(1)}%'
                          : '0%',
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

  Widget _buildMonthlyReport(BuildContext context) {
    return Consumer3<AttendanceProvider, StudentProvider, DepenseProvider>(
      builder: (context, attendanceProvider, studentProvider, depenseProvider, child) {
        final monthDepenses = depenseProvider.getTotalMois(
          _selectedMonth.month,
          _selectedMonth.year,
        );

        return Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HEGColors.violet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month, color: HEGColors.violet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rapport mensuel',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: HEGColors.gris.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        helpText: 'Sélectionner le mois',
                      );
                      if (picked != null) {
                        setState(() => _selectedMonth = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStatBox(
                context,
                'Total dépenses du mois',
                '${monthDepenses.toStringAsFixed(2)} CHF',
                Icons.receipt_long,
                HEGColors.error,
                fullWidth: true,
              ),
              const SizedBox(height: 16),
              _buildStatBox(
                context,
                'Nombre d\'élèves inscrits',
                studentProvider.activeStudents.length.toString(),
                Icons.people,
                HEGColors.violet,
                fullWidth: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HEGColors.gris.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
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



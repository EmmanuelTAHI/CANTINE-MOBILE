import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/main_navigation_bar.dart';
import '../../routes/app_routes.dart';
import '../../models/student.dart';

/// Tableau de bord du prestataire
class DashboardPrestataireScreen extends StatefulWidget {
  const DashboardPrestataireScreen({super.key});

  @override
  State<DashboardPrestataireScreen> createState() =>
      _DashboardPrestataireScreenState();
}

class _DashboardPrestataireScreenState
    extends State<DashboardPrestataireScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    studentProvider.loadStudents();
    attendanceProvider.loadTodayAttendance();
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

  void _showProfileMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: HEGColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HEGColors.gris.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Avatar
            Builder(
              builder: (context) {
                final avatarUrl = user?.avatar != null && user!.avatar!.isNotEmpty
                    ? (user.avatar!.startsWith('http')
                        ? user.avatar!
                        : '${AppConstants.baseUrl.replaceAll('/api', '')}${user.avatar}')
                    : null;

                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: HEGColors.violet.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: HEGColors.violet,
                      width: 3,
                    ),
                  ),
                  child: avatarUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: Text(
                                user?.initials ?? 'P',
                                style: const TextStyle(
                                  color: HEGColors.violet,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                user?.initials ?? 'P',
                                style: const TextStyle(
                                  color: HEGColors.violet,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            user?.initials ?? 'P',
                            style: const TextStyle(
                              color: HEGColors.violet,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Nom
            Text(
              user?.fullName ?? 'Prestataire',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HEGColors.gris.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            // Actions
            _buildMenuOption(
              context,
              icon: Icons.person_outline,
              title: 'Mon profil',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.profile);
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.settings);
              },
            ),
            Divider(color: HEGColors.gris.withOpacity(0.2)),
            _buildMenuOption(
              context,
              icon: Icons.logout,
              title: 'Déconnexion',
              textColor: HEGColors.error,
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? HEGColors.violet,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor ?? HEGColors.gris,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: HEGColors.gris.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MainNavigationBar(currentRoute: AppRoutes.dashboard),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar personnalisée
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: HEGColors.violet,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Tableau de bord',
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
              actions: [
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    return GestureDetector(
                      onTap: () => _showProfileMenu(context),
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HEGColors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: HEGColors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user?.initials ?? 'P',
                            style: const TextStyle(
                              color: HEGColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            // Contenu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête de bienvenue
                    _buildWelcomeHeader(context),
                    const SizedBox(height: 24),
                    // Statistiques
                    _buildStats(context),
                    const SizedBox(height: 24),
                    // Actions rapides
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    // Liste des élèves
                    _buildStudentsPreview(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
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
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HEGColors.violet,
                      HEGColors.violetDark,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: HEGColors.violet.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user?.initials ?? 'P',
                    style: const TextStyle(
                      color: HEGColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HEGColors.gris.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.fullName ?? 'Prestataire',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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

  Widget _buildStats(BuildContext context) {
    return Consumer2<StudentProvider, AttendanceProvider>(
      builder: (context, studentProvider, attendanceProvider, child) {
        final totalStudents = studentProvider.activeStudents.length;
        final todayPresent = attendanceProvider.todayAttendance
            .where((a) => a.present)
            .length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Élèves inscrits',
                totalStudents.toString(),
                Icons.people_rounded,
                HEGColors.violet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Présents aujourd\'hui',
                todayPresent.toString(),
                Icons.check_circle_rounded,
                HEGColors.success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
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

  Widget _buildQuickActions(BuildContext context) {
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
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: HEGColors.violet,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Actions rapides',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
            CustomButton(
              text: 'Marquer les présences',
              icon: Icons.checklist_rtl_rounded,
              onPressed: () {
                context.push(AppRoutes.studentsChecklist);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Menu du jour',
                    icon: Icons.restaurant_menu,
                    isOutlined: true,
                    onPressed: () {
                      context.push(AppRoutes.menuToday);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Gérer menus',
                    icon: Icons.settings,
                    isOutlined: true,
                    onPressed: () {
                      context.push(AppRoutes.menuManagement);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Dépenses',
                    icon: Icons.receipt_long,
                    isOutlined: true,
                    onPressed: () {
                      context.push(AppRoutes.depenses);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Rapports',
                    icon: Icons.assessment,
                    isOutlined: true,
                    onPressed: () {
                      context.push(AppRoutes.reports);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStudentsPreview(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        if (studentProvider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: HEGColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (studentProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HEGColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    color: HEGColors.error, size: 48),
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

        final students = studentProvider.activeStudents.take(5).toList();

        if (students.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: HEGColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: HEGColors.gris.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun élève inscrit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return Container(
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: HEGColors.violet.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people_rounded,
                            color: HEGColors.violet,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Élèves inscrits',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.studentsChecklist);
                      },
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      label: const Text('Voir tout'),
                      style: TextButton.styleFrom(
                        foregroundColor: HEGColors.violet,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: HEGColors.gris.withOpacity(0.1)),
              ...students.map((student) => _buildStudentTile(student)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentTile(Student student) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to student details
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    HEGColors.violet.withOpacity(0.2),
                    HEGColors.violetDark.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${student.prenom[0]}${student.nom[0]}'.toUpperCase(),
                  style: const TextStyle(
                    color: HEGColors.violet,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (student.classe != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: HEGColors.violet.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            student.classe!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: HEGColors.violet,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        student.matricule,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HEGColors.gris.withOpacity(0.7),
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: HEGColors.gris.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';

/// Écran de profil utilisateur
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _localAvatarFile;
  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: HEGColors.violet,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Mon profil',
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
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.user;
                  if (user == null) {
                    return const Center(
                      child: Text('Aucune donnée utilisateur'),
                    );
                  }

                  return Column(
                    children: [
                      // Avatar
                      _buildAvatar(context, user),
                      const SizedBox(height: 24),
                      // Informations personnelles
                      _buildInfoCard(
                        context,
                        title: 'Informations personnelles',
                        children: [
                          _buildInfoRow(
                            context,
                            icon: Icons.person_outline,
                            label: 'Nom d\'utilisateur',
                            value: user.username,
                          ),
                          _buildDivider(),
                          _buildInfoRow(
                            context,
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email,
                          ),
                          if (user.firstName != null) ...[
                            _buildDivider(),
                            _buildInfoRow(
                              context,
                              icon: Icons.badge_outlined,
                              label: 'Prénom',
                              value: user.firstName!,
                            ),
                          ],
                          if (user.lastName != null) ...[
                            _buildDivider(),
                            _buildInfoRow(
                              context,
                              icon: Icons.badge_outlined,
                              label: 'Nom',
                              value: user.lastName!,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Informations professionnelles
                      _buildInfoCard(
                        context,
                        title: 'Informations professionnelles',
                        children: [
                          _buildInfoRow(
                            context,
                            icon: Icons.work_outline,
                            label: 'Rôle',
                            value: user.role == 'admin'
                                ? 'Administrateur'
                                : 'Prestataire',
                          ),
                          if (user.poste != null) ...[
                            _buildDivider(),
                            _buildInfoRow(
                              context,
                              icon: Icons.business_center_outlined,
                              label: 'Poste',
                              value: user.poste!,
                            ),
                          ],
                          if (user.contact != null) ...[
                            _buildDivider(),
                            _buildInfoRow(
                              context,
                              icon: Icons.phone_outlined,
                              label: 'Contact',
                              value: user.contact!,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Actions
                      _buildActionCard(context),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, User user) {
    final localFile = _localAvatarFile;
    final avatarUrl = user.avatar != null && user.avatar!.isNotEmpty
        ? (user.avatar!.startsWith('http')
            ? user.avatar!
            : '${AppConstants.baseUrl.replaceAll('/api', '')}${user.avatar}')
        : null;

    Widget avatarContent;
    if (localFile != null) {
      avatarContent = ClipOval(
        child: Image.file(
          localFile,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (avatarUrl != null) {
      avatarContent = ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: Text(
              user.initials,
              style: const TextStyle(
                color: HEGColors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Center(
            child: Text(
              user.initials,
              style: const TextStyle(
                color: HEGColors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else {
      avatarContent = Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: HEGColors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showImagePicker(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
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
                  color: HEGColors.violet.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: avatarContent,
          ),
          if (_isUploadingAvatar)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(HEGColors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: HEGColors.violet,
                shape: BoxShape.circle,
                border: Border.all(color: HEGColors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: HEGColors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (mounted) {
          setState(() {
            _localAvatarFile = file;
          });
        }
        await _uploadAvatar(context, file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: HEGColors.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatar(BuildContext context, File imageFile) async {
    if (!mounted) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final avatarUrl = await apiService.uploadUserAvatar(imageFile);
      final normalizedUrl = avatarUrl.startsWith('http')
          ? avatarUrl
          : '${AppConstants.baseUrl.replaceAll('/api', '')}$avatarUrl';
      await CachedNetworkImage.evictFromCache(normalizedUrl);

      // Mettre à jour l'utilisateur dans le provider
      if (authProvider.user != null) {
        final updatedUser = authProvider.user!.copyWith(avatar: avatarUrl);
        await authProvider.updateUser(updatedUser);
      }

      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _localAvatarFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour avec succès'),
            backgroundColor: HEGColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: ${e.toString()}'),
            backgroundColor: HEGColors.error,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard(
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
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: HEGColors.violet,
                  ),
            ),
          ),
          Divider(height: 1, color: HEGColors.gris.withOpacity(0.1)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HEGColors.violet.withOpacity(0.1),
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
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HEGColors.gris.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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
      child: Divider(height: 1, color: HEGColors.gris.withOpacity(0.1)),
    );
  }

  Widget _buildActionCard(BuildContext context) {
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
        children: [
          _buildActionTile(
            context,
            icon: Icons.settings_outlined,
            title: 'Paramètres',
            onTap: () => context.push(AppRoutes.settings),
          ),
          Divider(height: 1, color: HEGColors.gris.withOpacity(0.1)),
          _buildActionTile(
            context,
            icon: Icons.help_outline,
            title: 'Aide & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aide & Support à venir')),
              );
            },
          ),
          Divider(height: 1, color: HEGColors.gris.withOpacity(0.1)),
          _buildActionTile(
            context,
            icon: Icons.info_outline,
            title: 'À propos',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Cantine HEG',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: HEGColors.violet,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'HEG',
                      style: TextStyle(
                        color: HEGColors.white,
                        fontSize: 24,
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
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
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
                color: HEGColors.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: HEGColors.violet, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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

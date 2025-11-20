import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/student.dart';
import '../config/constants.dart';

/// Carte d'affichage d'un élève
class StudentCard extends StatelessWidget {
  final Student student;
  final bool isPresent;
  final bool isChecked;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onCheckedChanged;

  const StudentCard({
    super.key,
    required this.student,
    this.isPresent = false,
    this.isChecked = false,
    this.onTap,
    this.onCheckedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: HEGColors.violet.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: student.photo != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: student.photo!.startsWith('http')
                              ? student.photo!
                              : '${AppConstants.baseUrl.replaceAll('/api', '')}${student.photo}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildInitials(),
                          errorWidget: (context, url, error) => _buildInitials(),
                        ),
                      )
                    : _buildInitials(),
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: HEGColors.violet,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (student.classeDisplay != 'Sans classe') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: HEGColors.violet.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              student.classeDisplay,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: HEGColors.violet,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          student.matricule,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Checkbox
              if (onCheckedChanged != null)
                Checkbox(
                  value: isChecked,
                  onChanged: (value) => onCheckedChanged?.call(value ?? false),
                  activeColor: HEGColors.violet,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else if (isPresent)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HEGColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: HEGColors.success,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    final initials = student.prenom.isNotEmpty && student.nom.isNotEmpty
        ? '${student.prenom[0]}${student.nom[0]}'.toUpperCase()
        : student.matricule.substring(0, 2).toUpperCase();

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: HEGColors.violet,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}



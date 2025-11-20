import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// Champ de texte personnalisé avec le style HEG
class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool enabled;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: HEGColors.gris.withValues(alpha: 0.6))
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: HEGColors.gris.withValues(alpha: 0.6)),
                onPressed: onSuffixTap,
              )
            : null,
        filled: true,
        fillColor: enabled ? HEGColors.white : HEGColors.grisClair,
      ),
    );
  }
}



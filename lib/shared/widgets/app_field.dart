import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.errorText,
    this.errorMaxLines,
    this.onChanged,
    this.onFieldSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.autocorrect = true,
    this.obscureText = false,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.onCard = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final int? errorMaxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool autocorrect;
  final bool obscureText;
  final bool enabled;
  final int? minLines;
  final int maxLines;
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: onCard
          ? theme.copyWith(
              inputDecorationTheme: AppTheme.fieldTheme(
                AppColors.of(context),
                ShadowTints.of(context),
                theme.textTheme,
                onCard: true,
              ),
            )
          : theme,
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        autofocus: autofocus,
        autocorrect: autocorrect,
        obscureText: obscureText,
        enabled: enabled,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          errorMaxLines: errorMaxLines,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

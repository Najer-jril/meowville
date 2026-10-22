import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateRequired(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null;

String? validateEmail(String? value) {
  final required = validateRequired(value);
  if (required != null) return required;
  return _emailPattern.hasMatch(value!.trim())
      ? null
      : 'Format email tidak valid';
}

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.helperText,
    this.textInputAction,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final TextInputAction? textInputAction;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _focusNode = FocusNode();
  late bool _hidden = widget.obscure;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: BorderSide(color: color, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final caption = text.bodySmall!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: text.labelLarge!.copyWith(fontSize: 14)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _hidden,
          validator: widget.validator,
          style: text.bodyLarge,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            helperMaxLines: 2,
            helperStyle: caption,
            errorStyle: caption.copyWith(color: AppColors.danger),
            errorMaxLines: 2,
            filled: true,
            fillColor: _focusNode.hasFocus
                ? AppColors.surface
                : AppColors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.md,
              ),
              child: Icon(widget.icon, size: 22, color: AppColors.muted),
            ),
            prefixIconConstraints: const BoxConstraints(minHeight: 52),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    tooltip: _hidden ? 'Lihat kata sandi' : 'Sembunyikan',
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 22,
                      color: AppColors.muted,
                    ),
                  )
                : null,
            focusedBorder: _border(AppColors.primary),
            errorBorder: _border(AppColors.danger),
            focusedErrorBorder: _border(AppColors.danger),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class AppTheme {
  static const primary       = Color(0xFF007AFF);
  static const success       = Color(0xFF34C759);
  static const error         = Color(0xFFFF3B30);
  static const background    = Color(0xFFF5F5F7);
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);

  static ButtonStyle get primaryButton => FilledButton.styleFrom(
        backgroundColor: primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  static InputDecoration inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      );
}

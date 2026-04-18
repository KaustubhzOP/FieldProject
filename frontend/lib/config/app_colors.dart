import 'package:flutter/material.dart';

class AppColors {
  // Midnight Theme Palette
  static const Color primary = Color(0xFF0F172A); // Dark Navy
  static const Color secondary = Color(0xFF1E293B); // Slate
  static const Color accent = Color(0xFF38BDF8); // Sky Blue
  static const Color teal = Color(0xFF2DD4BF); // Teal
  
  static const Color background = Color(0xFF020617); // Almost Black
  static const Color surface = Color(0xFF1E293B);
  static const Color card = Color(0xFF1E293B);
  
  static const Color textHeader = Colors.white;
  static const Color textBody = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF2DD4BF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

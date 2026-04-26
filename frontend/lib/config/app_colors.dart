import 'package:flutter/material.dart';

class AppColors {
  // Government / Municipal Theme Palette
  static const Color primary = Color(0xFF1565C0); // Deep Blue
  static const Color secondary = Color(0xFF0D47A1); // Darker Blue
  static const Color accent = Color(0xFF0288D1); // Light Blue accent
  static const Color teal = Color(0xFF00796B); // Teal/Green accent for success/nature
  
  static const Color background = Color(0xFFF4F6F8); // Off-white / light grey
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color card = Color(0xFFFFFFFF);
  
  static const Color textHeader = Color(0xFF1E293B); // Dark grey
  static const Color textBody = Color(0xFF334155); // Medium dark grey
  static const Color textMuted = Color(0xFF64748B); // Muted grey
  static const Color border = Color(0xFFE2E8F0); // Subtle border
  
  // Status Colors
  static const Color success = Color(0xFF2E7D32); // Green
  static const Color error = Color(0xFFD32F2F); // Red
  static const Color warning = Color(0xFFED6C02); // Orange

  // Gradients (Avoid flashy gradients, but keeping definitions simple if used)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0288D1), Color(0xFF0277BD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

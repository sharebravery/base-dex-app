import 'package:flutter/material.dart';

/// Web3-styled dark palette. Change values here to re-skin the entire app.
abstract final class AppColors {
  // Backgrounds (3-layer depth)
  static const bg = Color(0xFF0A0B0F); // Root
  static const surface = Color(0xFF12141C); // Cards
  static const surfaceElevated = Color(0xFF1A1D28); // Elevated / dialogs
  static const border = Color(0xFF232838); // Card borders / dividers

  // Text
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFF8B93A7);
  static const textMuted = Color(0xFF5A6178);

  // Brand / accent
  static const accent = Color(0xFF00E5FF); // Cyan
  static const accentPurple = Color(0xFFA855F7); // Violet
  static const gradientStart = Color(0xFF00E5FF);
  static const gradientEnd = Color(0xFFA855F7);

  // Semantic
  static const positive = Color(0xFF10D876);
  static const negative = Color(0xFFF43F5E);
  static const warning = Color(0xFFFBBF24);
}

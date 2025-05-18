import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppColors {
  // Ana renkler
  static const Color primaryColor = Color(0xFF6A2C70); // Koyu mor
  static const Color accentColor = Color(0xFFFF5D8F); // Pembe aksan
  static const Color backgroundColor = Color(0xFF1A1A2E); // Koyu arka plan
  static const Color cardColor = Color(0xFF2D2D3E); // Kart arka planı
  static const Color inputColor = Color(0xFF30303F); // Form alanları
  static const Color textColor = Colors.white; // Beyaz metin
  static const Color secondaryTextColor = Color(0xFFB5B5B5); // Gri metin

  // Gradient renkler
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF30243B), // Koyu mor
      Color(0xFF321B35), // Bordo-mor
    ],
  );

  static const Gradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF5D8F), // Pembe
      Color(0xFFFF7B9B), // Açık pembe
    ],
  );

  // Form elementleri
  static const Color inputBorderColor =
      Color.fromARGB(255, 177, 51, 154); // Form kenarlıkları
  static const Color inputFillColor = Color(0xFF30303F); // Form dolgu rengi
  static const Color inputHintColor = Color(0xFF9E9E9E); // Hint rengi

  // İkon renkleri
  static const Color iconColor = Color(0xFFFF5D8F);

  // Shadow
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      spreadRadius: 0,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Animasyon renkleri
  static const Color shimmerBaseColor = Color(0xFF3A3A48);
  static const Color shimmerHighlightColor = Color(0xFF494957);
}

import 'package:flutter/material.dart';

class CategoryTheme {
  final List<Color> gradient;
  final Color particleColor;
  final String particleType;
  final Color fogTint;

  const CategoryTheme({
    required this.gradient,
    required this.particleColor,
    required this.particleType,
    required this.fogTint,
  });

  static const Map<String, CategoryTheme> themes = {
    'senderismo': CategoryTheme(
      gradient: [Color(0xFF1B4332), Color(0xFF52B788)],
      particleColor: Color(0xFF95D5B2),
      particleType: 'leaves',
      fogTint: Color(0x402D6A4F),
    ),
    'pesca': CategoryTheme(
      gradient: [Color(0xFF023E8A), Color(0xFF90E0EF)],
      particleColor: Color(0xFFCAF0F8),
      particleType: 'bubbles',
      fogTint: Color(0x400077B6),
    ),
    'camping': CategoryTheme(
      gradient: [Color(0xFF6B3A2A), Color(0xFFF4A261)],
      particleColor: Color(0xFFFFE08A),
      particleType: 'fireflies',
      fogTint: Color(0x40D4A373),
    ),
    'escalada': CategoryTheme(
      gradient: [Color(0xFF4A4A4A), Color(0xFFB0A999)],
      particleColor: Color(0xFFD4C5A9),
      particleType: 'dust',
      fogTint: Color(0x408B7355),
    ),
    'kayak': CategoryTheme(
      gradient: [Color(0xFF0077B6), Color(0xFFADE8F4)],
      particleColor: Color(0xFFCAF0F8),
      particleType: 'waves',
      fogTint: Color(0x400096C7),
    ),
    'observacion': CategoryTheme(
      gradient: [Color(0xFF2B9348), Color(0xFF80ED99)],
      particleColor: Color(0xFFB7E4C7),
      particleType: 'feathers',
      fogTint: Color(0x4052B788),
    ),
    'mirador': CategoryTheme(
      gradient: [Color(0xFF4A6FA5), Color(0xFFBFC6D4)],
      particleColor: Color(0xFFD6E2E9),
      particleType: 'mist',
      fogTint: Color(0x407B8FA1),
    ),
    'natural': CategoryTheme(
      gradient: [Color(0xFF1B4332), Color(0xFF74C69D)],
      particleColor: Color(0xFFB7E4C7),
      particleType: 'mist',
      fogTint: Color(0x4040916C),
    ),
    'running': CategoryTheme(
      gradient: [Color(0xFFE07A00), Color(0xFFFFC300)],
      particleColor: Color(0xFFFFE08A),
      particleType: 'sparks',
      fogTint: Color(0x40F4A261),
    ),
    'otro': CategoryTheme(
      gradient: [Color(0xFF5C4033), Color(0xFFC79A5E)],
      particleColor: Color(0xFFD4A373),
      particleType: 'sparks',
      fogTint: Color(0x408B7355),
    ),
  };

  static CategoryTheme forCategoria(String? cat) => themes[cat] ?? themes['otro']!;
}

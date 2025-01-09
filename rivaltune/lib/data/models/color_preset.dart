import 'package:flutter/material.dart';

class ColorPreset {
  final String name;
  final Color topColor;
  final Color middleColor;
  final Color bottomColor;
  final Color logoColor;
  final String effect;

  const ColorPreset({
    required this.name,
    required this.topColor,
    required this.middleColor,
    required this.bottomColor,
    required this.logoColor,
    this.effect = 'steady',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'topColor': topColor.value,
    'middleColor': middleColor.value,
    'bottomColor': bottomColor.value,
    'logoColor': logoColor.value,
    'effect': effect,
  };

  factory ColorPreset.fromJson(Map<String, dynamic> json) => ColorPreset(
    name: json['name'],
    topColor: Color(json['topColor']),
    middleColor: Color(json['middleColor']),
    bottomColor: Color(json['bottomColor']),
    logoColor: Color(json['logoColor']),
    effect: json['effect'],
  );
} 
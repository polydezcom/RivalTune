import 'package:flutter/material.dart';

String colorToHex(Color color) {
  return color.value.toRadixString(16).substring(2).padLeft(6, '0');
} 
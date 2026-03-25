// Ayla app smoke tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:ayla/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  test('AppColors primary is defined', () {
    expect(AppColors.primary, isA<Color>());
  });
}

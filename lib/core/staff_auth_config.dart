import 'package:flutter/foundation.dart';

/// Staff PINs for in-app gates — compile-time only, not strong security.
/// Pass at build: --dart-define=MANAGER_PIN=... --dart-define=EMPLOYEE_PIN=...
/// In release builds, empty PIN disables that login (no hardcoded defaults).
abstract final class StaffAuthConfig {
  static const managerPin = String.fromEnvironment('MANAGER_PIN', defaultValue: '');
  static const employeePin = String.fromEnvironment('EMPLOYEE_PIN', defaultValue: '');

  static String get effectiveManagerPin =>
      managerPin.isNotEmpty ? managerPin : (kDebugMode ? '1234' : '');

  static String get effectiveEmployeePin =>
      employeePin.isNotEmpty ? employeePin : (kDebugMode ? '4321' : '');

  static bool get isManagerLoginEnabled => effectiveManagerPin.isNotEmpty;
  static bool get isEmployeeLoginEnabled => effectiveEmployeePin.isNotEmpty;
}

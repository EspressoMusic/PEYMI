import 'package:bakery_shop_app/core/accessibility_settings.dart';
import 'package:bakery_shop_app/core/app_config_scope.dart';
import 'package:bakery_shop_app/core/app_locale.dart';
import 'package:bakery_shop_app/core/app_theme_mode.dart';
import 'package:bakery_shop_app/core/bakery_navigator.dart';
import 'package:bakery_shop_app/core/business_store.dart';
import 'package:bakery_shop_app/core/manager_notifications_store.dart';
import 'package:bakery_shop_app/core/reviews_store.dart';
import 'package:bakery_shop_app/main.dart';
import 'package:bakery_shop_app/manager_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _bootApp(WidgetTester tester) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await AppLocale.instance.load();
  await AppThemeController.instance.load();
  await AccessibilitySettings.instance.load();
  await BusinessStore.instance.load();
  await ReviewsStore.instance.load();
  await ManagerNotificationsStore.instance.load();

  await tester.pumpWidget(const BakeryApp());
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('Pushing ManagerHomePage on BakeryApp does not throw', (tester) async {
    await _bootApp(tester);

    bakeryNavigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ManagerHomePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(ManagerHomePage), findsOneWidget);
  });

  testWidgets('showManagerLogin opens manager panel without assertion', (tester) async {
    await _bootApp(tester);

    final strings = AppLocale.instance.s;
    final home = tester.element(find.byType(BakeryHomePage));
    final loginFuture = showManagerLogin(home);
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '1234');
    await tester.tap(find.text(strings.login));
    await tester.pumpAndSettle();
    await loginFuture;

    expect(tester.takeException(), isNull);
    expect(find.byType(ManagerHomePage), findsOneWidget);
  });
}

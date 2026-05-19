import 'package:bakery_shop_app/core/app_locale.dart';
import 'package:bakery_shop_app/core/app_theme_mode.dart';
import 'package:bakery_shop_app/core/business_store.dart';
import 'package:bakery_shop_app/core/manager_notifications_store.dart';
import 'package:bakery_shop_app/core/reviews_store.dart';
import 'package:bakery_shop_app/manager_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ManagerHomePage builds without error', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppLocale.instance.load();
    await AppThemeController.instance.load();
    await BusinessStore.instance.load();
    await ReviewsStore.instance.load();
    await ManagerNotificationsStore.instance.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeController.instance.theme(),
        home: const ManagerHomePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(ManagerHomePage), findsOneWidget);
  });
}

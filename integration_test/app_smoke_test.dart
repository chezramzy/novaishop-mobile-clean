import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:novaishop_mobile/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts without an external API and shows onboarding',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('NovAiShop'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}

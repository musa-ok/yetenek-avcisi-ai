import 'package:flutter_test/flutter_test.dart';

import 'package:yetenek_avcisi/main.dart';

void main() {
  testWidgets('login screen renders core copy', (WidgetTester tester) async {
    await tester.pumpWidget(const ScoutiqApp());
    await tester.pumpAndSettle();

    expect(find.text(L10n(AppLanguage.tr).appTitle), findsOneWidget);
    expect(find.text(L10n(AppLanguage.tr).loginSubtitle), findsOneWidget);
    expect(find.text(L10n(AppLanguage.tr).login), findsOneWidget);
  });
}

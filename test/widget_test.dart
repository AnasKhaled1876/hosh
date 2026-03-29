import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosh/app/di/app_dependencies.dart';
import 'package:hosh/app/view/hoosh_app.dart';

void main() {
  testWidgets('app boots into repel screen and navigates core tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(HooshApp(dependencies: AppDependencies.create()));
    await tester.pumpAndSettle();

    expect(find.text('ACTIVE PROTECTION'), findsOneWidget);
    expect(find.text('REPEL'), findsWidgets);

    await tester.tap(find.text('REPORT').first);
    await tester.pumpAndSettle();
    expect(find.text('Report Sighting'), findsOneWidget);

    await tester.tap(find.text('MAP').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('HOTSPOT', findRichText: true), findsWidgets);
    expect(find.text('Recommended Routes'), findsNothing);
    expect(find.textContaining('route', findRichText: true), findsNothing);

    await tester.scrollUntilVisible(
      find.text('REPORT A SIGHTING'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('REPORT A SIGHTING'), findsOneWidget);

    await tester.tap(find.text('REPORT A SIGHTING'));
    await tester.pumpAndSettle();
    expect(find.text('Report Sighting'), findsOneWidget);

    await tester.tap(find.text('INFO').first);
    await tester.pumpAndSettle();
    expect(find.text('Non-lethal street safety'), findsOneWidget);
  });
}

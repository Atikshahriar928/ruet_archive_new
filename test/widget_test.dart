import 'package:flutter_test/flutter_test.dart';
import 'package:ruet_archive_new/main.dart';

void main() {
  testWidgets('Login screen loads test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen title is present.
    expect(find.textContaining('Login Now'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}

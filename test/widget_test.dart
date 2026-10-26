import 'package:flutter_test/flutter_test.dart';
import 'package:photo_app/main.dart';

void main() {
  testWidgets('PhotoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoApp());
    expect(find.byType(PhotoApp), findsOneWidget);
  });
}

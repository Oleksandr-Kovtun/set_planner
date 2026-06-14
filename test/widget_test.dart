import 'package:flutter_test/flutter_test.dart';
import 'package:set_planner/main.dart';

void main() {
  testWidgets('Застосунок будується без помилок',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SetPlannerApp());
  });
}
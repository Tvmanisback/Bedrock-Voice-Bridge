import 'package:flutter_test/flutter_test.dart';
import 'package:bedrock_voice_bridge/main.dart';

void main() {
  testWidgets('shows Bedrock Voice Bridge microphone screen', (tester) async {
    await tester.pumpWidget(const BvbApp());
    expect(find.text('Bedrock Voice Bridge'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
  });
}

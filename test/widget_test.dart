import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netflix_clone/main.dart';

void main() {
  testWidgets('renders the StreamFlix home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NetflixCloneApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('STREAMFLIX'), findsOneWidget);
    expect(find.text('Search movies and series'), findsOneWidget);
    expect(find.text('Oppenheimer'), findsOneWidget);
  });
}

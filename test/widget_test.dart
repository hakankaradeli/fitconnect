import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fitconnect/main.dart';
import 'package:fitconnect/view_models/theme_view_model.dart';
import 'package:fitconnect/repositories/gym_repository.dart';
import 'package:fitconnect/services/api_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final apiService = ApiService(customUrl: ApiService.defaultCustomUrl);
    final gymRepo = GymRepository(apiService: apiService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeViewModel(gymRepository: gymRepo)),
        ],
        child: const MyApp(
          home: Scaffold(body: Center(child: Text('FitConnect'))),
        ),
      ),
    );

    expect(find.text('FitConnect'), findsOneWidget);
  });
}

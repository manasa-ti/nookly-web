import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/pages/profile/edit_profile_page.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([AuthRepository])
import 'edit_profile_page_test.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late User testUser;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    GetIt.instance.registerSingleton<AuthRepository>(mockAuthRepository);

    testUser = User(
      id: '1',
      email: 'test@example.com',
      name: 'Test User',
      bio: 'Test bio',
      interests: ['Deep Conversations'],
      objectives: ['Long Term'],
      preferredAgeRange: {
        'lower_limit': 18,
        'upper_limit': 30,
      },
    );
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('EditProfilePage', () {
    testWidgets('should load with user data and API interests/objectives',
        (WidgetTester tester) async {
      // Arrange
      when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockAuthRepository.getPredefinedInterests()).thenAnswer(
        (_) async => ['Deep Conversations', 'Coffee Dates'],
      );
      when(mockAuthRepository.getPredefinedObjectives()).thenAnswer(
        (_) async => ['Long Term', 'Short Term'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditProfilePage(user: testUser),
          ),
        ),
      );

      // Wait for all async work to finish
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
      expect(find.text('Deep Conversations'), findsOneWidget); // Selected interest
      expect(find.text('Long Term'), findsOneWidget); // Selected objective
      expect(find.text('18 years'), findsOneWidget); // Age range start
      expect(find.text('30 years'), findsOneWidget); // Age range end
    });

    testWidgets('should use fallback lists when API fails',
        (WidgetTester tester) async {
      // Arrange
      when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockAuthRepository.getPredefinedInterests()).thenThrow(Exception('API Error'));
      when(mockAuthRepository.getPredefinedObjectives()).thenThrow(Exception('API Error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditProfilePage(user: testUser),
          ),
        ),
      );

      // Wait for all async work to finish
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Deep Conversations'), findsOneWidget); // From fallback list
      expect(find.text('Long Term'), findsOneWidget); // From fallback list
      // Note: Fallback messages are shown as SnackBars, not as text widgets
    });

    testWidgets('should validate form changes correctly', (WidgetTester tester) async {
      // Arrange
      when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockAuthRepository.getPredefinedInterests()).thenAnswer(
        (_) async => ['Deep Conversations', 'Coffee Dates'],
      );
      when(mockAuthRepository.getPredefinedObjectives()).thenAnswer(
        (_) async => ['Long Term', 'Short Term'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditProfilePage(user: testUser),
          ),
        ),
      );

      // Wait for all async work to finish
      await tester.pumpAndSettle();

      // Change name
      await tester.enterText(find.byType(TextFormField).first, 'New Name');
      await tester.pumpAndSettle(); // Wait for all animations and state updates

      // Assert
      expect(find.text('New Name'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      // The button should be enabled since we have valid form data
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed != null, true);
    });
  });
} 
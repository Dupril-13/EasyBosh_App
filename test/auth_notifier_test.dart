/*import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easybosh_v2/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_notifier_test.mocks.dart';

@GenerateMocks([SupabaseClient, GoTrueClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
void main() {
  group('AuthNotifier Unit Test', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late ProviderContainer container;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();

      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

      container = ProviderContainer(
        overrides: [
          // We are mocking the supabaseClientProvider to return our mock client
          // This will be used by the AuthNotifier
        ],
      );
    });

    test('Initial state is unauthenticated', () {
      final authState = container.read(authNotifierProvider);
      expect(authState.userProfile, null);
      expect(authState.isLoading, false);
    });

    test('Sign in successfully changes state to authenticated', () async {
      final authNotifier = container.read(authNotifierProvider.notifier);

      // Define the mock response for signInWithPassword
      final authResponse = AuthResponse(session: Session(accessToken: 'test_token', tokenType: 'bearer', user: User(id: 'test_id', appMetadata: {}, userMetadata: {}, aud: 'test', createdAt: DateTime.now().toIso8601String())));
      when(mockGoTrueClient.signInWithPassword(email: 'test@example.com', password: 'password')).thenAnswer((_) async => authResponse);

      // Define the mock response for the profile fetch
      final profileResponse = {'id': 'test_id', 'first_name': 'Test', 'last_name': 'User', 'role': 'student'};
      // We need to mock the query builder chain
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();
      when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.eq('id', 'test_id')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => profileResponse);

      // Trigger the sign-in
      // This is a simplified version, in a real scenario you would call a method on the notifier
      // For now, we will just check the state change after the mocks are set up

      // We will need to adjust the AuthNotifier to be able to inject the mock client easily
      // For this test, we assume the notifier is already using the mocked client through a provider.

      // This test is more of a placeholder until we can properly inject the mock client.
      expect(authNotifier, isA<AuthNotifier>());
    });
  });
}
*/
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kompagni/shared/models/provider.dart' as models;
import 'package:kompagni/shared/repositories/user_repository.dart';
import 'package:kompagni/shared/repositories/impl/user_repository_impl.dart';
import 'package:kompagni/core/network/api_client.dart';

// Mock classes
class MockDio extends Mock implements Dio {}

void main() {
  group('UserRepository', () {
    late MockDio mockDio;
    late UserRepository repository;
    late ProviderContainer container;

    setUp(() {
      mockDio = MockDio();
      repository = UserRepositoryImpl(mockDio);
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockDio),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('getCurrentUser', () {
      test('should return user data on success', () async {
        // Arrange
        final userData = {
          'id': 'user-1',
          'email': 'test@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
          'role': 'CLIENT',
        };

        when(() => mockDio.get('/users/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 200,
            data: userData,
          ),
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result!['email'], 'test@example.com');
        expect(result['firstName'], 'John');
        verify(() => mockDio.get('/users/me')).called(1);
      });

      test('should return null when response data is null', () async {
        // Arrange
        when(() => mockDio.get('/users/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 200,
            data: null,
          ),
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });

      test('should return null when response data is empty string', () async {
        // Arrange
        when(() => mockDio.get('/users/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 200,
            data: '',
          ),
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });

      test('should return null on 404 error', () async {
        // Arrange
        when(() => mockDio.get('/users/me')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/users/me'),
            response: Response(
              requestOptions: RequestOptions(path: '/users/me'),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('syncUser', () {
      test('should call POST /users/sync with user data', () async {
        // Arrange
        when(() => mockDio.post(
              '/users/sync',
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/sync'),
            statusCode: 201,
            data: {'success': true},
          ),
        );

        // Act
        await repository.syncUser(
          role: 'CLIENT',
          firstName: 'John',
          lastName: 'Doe',
          phoneNumber: '+33612345678',
        );

        // Assert
        verify(() => mockDio.post(
              '/users/sync',
              data: {
                'role': 'CLIENT',
                'firstName': 'John',
                'lastName': 'Doe',
                'phoneNumber': '+33612345678',
                'providerProfile': null,
              },
            )).called(1);
      });

      test('should include provider profile when syncing provider', () async {
        // Arrange
        when(() => mockDio.post(
              '/users/sync',
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/sync'),
            statusCode: 201,
            data: {'success': true},
          ),
        );

        final providerProfile = {
          'businessName': 'Test Salon',
          'address': '123 Rue Test',
          'city': 'Paris',
        };

        // Act
        await repository.syncUser(
          role: 'PROVIDER',
          firstName: 'Jane',
          lastName: 'Provider',
          providerProfile: providerProfile,
          tags: ['Toiletteur', 'Chien'],
        );

        // Assert
        verify(() => mockDio.post(
              '/users/sync',
              data: {
                'role': 'PROVIDER',
                'firstName': 'Jane',
                'lastName': 'Provider',
                'phoneNumber': null,
                'providerProfile': {
                  'businessName': 'Test Salon',
                  'address': '123 Rue Test',
                  'city': 'Paris',
                  'tags': ['Toiletteur', 'Chien'],
                },
              },
            )).called(1);
      });
    });

    group('updateUser', () {
      test('should call PATCH /users/me with update data', () async {
        // Arrange
        when(() => mockDio.patch(
              '/users/me',
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 200,
            data: {'success': true},
          ),
        );

        // Act
        await repository.updateUser({
          'firstName': 'UpdatedName',
          'phoneNumber': '+33698765432',
        });

        // Assert
        verify(() => mockDio.patch(
              '/users/me',
              data: {
                'firstName': 'UpdatedName',
                'phoneNumber': '+33698765432',
              },
            )).called(1);
      });
    });

    group('deleteAccount', () {
      test('should call DELETE /users/me', () async {
        // Arrange
        when(() => mockDio.delete('/users/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 204,
          ),
        );

        // Act
        await repository.deleteAccount();

        // Assert
        verify(() => mockDio.delete('/users/me')).called(1);
      });
    });

    group('favorites', () {
      test('addFavorite should call POST /users/favorites/:id', () async {
        // Arrange
        when(() => mockDio.post('/users/favorites/provider-123')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/favorites/provider-123'),
            statusCode: 201,
          ),
        );

        // Act
        await repository.addFavorite('provider-123');

        // Assert
        verify(() => mockDio.post('/users/favorites/provider-123')).called(1);
      });

      test('removeFavorite should call DELETE /users/favorites/:id', () async {
        // Arrange
        when(() => mockDio.delete('/users/favorites/provider-456')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/favorites/provider-456'),
            statusCode: 204,
          ),
        );

        // Act
        await repository.removeFavorite('provider-456');

        // Assert
        verify(() => mockDio.delete('/users/favorites/provider-456')).called(1);
      });

      test('getFavorites should return list of providers', () async {
        // Arrange
        final mockProviders = [
          {
            'id': 'p1',
            'businessName': 'Salon A',
            'city': 'Paris',
            'address': '1 Rue A',
            'postalCode': '75001',
          },
          {
            'id': 'p2',
            'businessName': 'Salon B',
            'city': 'Lyon',
            'address': '2 Rue B',
            'postalCode': '69001',
          },
        ];

        when(() => mockDio.get('/users/favorites')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/favorites'),
            statusCode: 200,
            data: mockProviders,
          ),
        );

        // Act
        final result = await repository.getFavorites();

        // Assert
        expect(result, isA<List<models.Provider>>());
        expect(result.length, 2);
        expect(result.first.businessName, 'Salon A');
        verify(() => mockDio.get('/users/favorites')).called(1);
      });
    });
  });
}

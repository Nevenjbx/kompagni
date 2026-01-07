import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kompagni/shared/models/provider.dart' as models;
import 'package:kompagni/shared/providers/favorites_provider.dart';
import 'package:kompagni/shared/repositories/user_repository.dart';
import 'package:kompagni/shared/repositories/impl/user_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('FavoritesProvider', () {
    late MockUserRepository mockUserRepository;
    late ProviderContainer container;

    setUp(() {
      mockUserRepository = MockUserRepository();
      container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockUserRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should load favorites on initialization', () async {
      // Arrange
      final mockProviders = [
        models.Provider(
          id: '1',
          businessName: 'Test Provider',
          description: 'Test',
          city: 'Paris',
          address: '123 Test St',
          postalCode: '75001',
          workingHours: [],
          services: [],
        ),
      ];
      when(() => mockUserRepository.getFavorites())
          .thenAnswer((_) async => mockProviders);

      // Act
      final result = await container.read(favoritesProvider.future);

      // Assert
      expect(result, equals(mockProviders));
      verify(() => mockUserRepository.getFavorites()).called(1);
    });

    test('should add favorite with optimistic update', () async {
      // Arrange
      when(() => mockUserRepository.getFavorites())
          .thenAnswer((_) async => []);
      when(() => mockUserRepository.addFavorite(any()))
          .thenAnswer((_) async {});

      final provider = models.Provider(
        id: '2',
        businessName: 'New Provider',
        description: 'Test',
        city: 'Lyon',
        address: '456 Test Ave',
        postalCode: '69001',
        workingHours: [],
        services: [],
      );

      // Wait for initial load
      await container.read(favoritesProvider.future);

      // Act
      await container.read(favoritesProvider.notifier).addFavorite(provider);

      // Assert
      verify(() => mockUserRepository.addFavorite('2')).called(1);
    });

    test('should remove favorite with optimistic update', () async {
      // Arrange
      final mockProviders = [
        models.Provider(
          id: '1',
          businessName: 'Test Provider',
          description: 'Test',
          city: 'Paris',
          address: '123 Test St',
          postalCode: '75001',
          workingHours: [],
          services: [],
        ),
      ];
      when(() => mockUserRepository.getFavorites())
          .thenAnswer((_) async => mockProviders);
      when(() => mockUserRepository.removeFavorite(any()))
          .thenAnswer((_) async {});

      // Wait for initial load
      await container.read(favoritesProvider.future);

      // Act
      await container.read(favoritesProvider.notifier).removeFavorite('1');

      // Assert
      verify(() => mockUserRepository.removeFavorite('1')).called(1);
    });

    test('isFavorite should return true when provider is favorited', () async {
      // Arrange
      final mockProviders = [
        models.Provider(
          id: '1',
          businessName: 'Test Provider',
          description: 'Test',
          city: 'Paris',
          address: '123 Test St',
          postalCode: '75001',
          workingHours: [],
          services: [],
        ),
      ];
      when(() => mockUserRepository.getFavorites())
          .thenAnswer((_) async => mockProviders);

      // Wait for initial load
      await container.read(favoritesProvider.future);

      // Act
      final isFavorite = container.read(isFavoriteProvider('1'));

      // Assert
      expect(isFavorite, isTrue);
    });

    test('isFavorite should return false when provider is not favorited', () async {
      // Arrange
      when(() => mockUserRepository.getFavorites())
          .thenAnswer((_) async => []);

      // Wait for initial load
      await container.read(favoritesProvider.future);

      // Act
      final isFavorite = container.read(isFavoriteProvider('999'));

      // Assert
      expect(isFavorite, isFalse);
    });
  });
}

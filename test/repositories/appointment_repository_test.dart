import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kompagni/shared/models/appointment.dart';
import 'package:kompagni/shared/models/paginated_result.dart';
import 'package:kompagni/shared/repositories/appointment_repository.dart';
import 'package:kompagni/shared/repositories/impl/appointment_repository_impl.dart';
import 'package:kompagni/core/network/api_client.dart';

// Mock classes
class MockDio extends Mock implements Dio {}

void main() {
  group('AppointmentRepository', () {
    late MockDio mockDio;
    late AppointmentRepository repository;
    late ProviderContainer container;

    setUp(() {
      mockDio = MockDio();
      repository = AppointmentRepositoryImpl(mockDio);
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockDio),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('getMyAppointments', () {
      test('should return list of appointments on success', () async {
        // Arrange
        final mockData = [
          {
            'id': '1',
            'startTime': '2026-01-15T10:00:00Z',
            'endTime': '2026-01-15T11:00:00Z',
            'status': 'CONFIRMED',
            'service': {'name': 'Toilettage', 'price': 50.0, 'duration': 60},
            'provider': {
              'id': 'p1',
              'businessName': 'Salon Test',
              'city': 'Paris',
              'address': '123 Rue Test',
              'postalCode': '75001',
            },
          },
        ];

        when(() => mockDio.get(
              '/appointments',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/appointments'),
            statusCode: 200,
            data: {
              'items': mockData,
              'total': 1,
              'page': 1,
              'limit': 20,
            },
          ),
        );

        // Act
        final result = await repository.getMyAppointments();

        // Assert
        expect(result, isA<PaginatedResult<Appointment>>());
        expect(result.items.length, 1);
        expect(result.items.first.id, '1');
        verify(() => mockDio.get(
              '/appointments',
              queryParameters: any(named: 'queryParameters'),
            )).called(1);
      });

      test('should return empty items when status code is not 200', () async {
        // Arrange
        when(() => mockDio.get(
              '/appointments',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/appointments'),
            statusCode: 500,
            data: null,
          ),
        );

        // Act
        final result = await repository.getMyAppointments();

        // Assert
        expect(result.items, isEmpty);
      });
    });

    group('getAvailableSlots', () {
      test('should return list of available time slots', () async {
        // Arrange
        final mockSlots = ['09:00', '10:00', '11:00', '14:00'];

        when(() => mockDio.get(
              '/appointments/available-slots',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/appointments/available-slots'),
            statusCode: 200,
            data: mockSlots,
          ),
        );

        // Act
        final result = await repository.getAvailableSlots(
          'provider-id',
          'service-id',
          DateTime(2026, 1, 15),
        );

        // Assert
        expect(result, equals(mockSlots));
      });

      test('should return empty list when no slots available', () async {
        // Arrange
        when(() => mockDio.get(
              '/appointments/available-slots',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/appointments/available-slots'),
            statusCode: 200,
            data: [],
          ),
        );

        // Act  
        final result = await repository.getAvailableSlots(
          'provider-id',
          'service-id',
          DateTime(2026, 1, 15),
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    group('createAppointment', () {
      test('should call POST /appointments with correct data', () async {
        // Arrange
        when(() => mockDio.post(
              '/appointments',
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/appointments'),
            statusCode: 201,
            data: {'id': 'new-appointment-id'},
          ),
        );

        // Act
        await repository.createAppointment(
          providerId: 'provider-1',
          serviceId: 'service-1',
          startTime: DateTime(2026, 1, 20, 10, 0),
          notes: 'Test notes',
        );

        // Assert
        verify(() => mockDio.post(
              '/appointments',
              data: {
                'providerId': 'provider-1',
                'serviceId': 'service-1',
                'startTime': '2026-01-20T10:00:00.000',
                'notes': 'Test notes',
              },
            )).called(1);
      });
    });

    group('cancelAppointment', () {
      test('should call PATCH /appointments/:id/status with CANCELLED', () async {
        // Arrange
        when(() => mockDio.patch(
              '/appointments/appointment-id/status',
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/appointments/appointment-id/status'),
            statusCode: 200,
            data: {'status': 'CANCELLED'},
          ),
        );

        // Act
        await repository.cancelAppointment('appointment-id');

        // Assert
        verify(() => mockDio.patch(
              '/appointments/appointment-id/status',
              data: {'status': 'CANCELLED'},
            )).called(1);
      });
    });
  });
}

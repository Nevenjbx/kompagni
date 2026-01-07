import 'provider.dart';
import 'service.dart';

/// Represents an appointment booking
class Appointment {
  final String id;
  final String clientId;
  final String providerId;
  final String serviceId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related entities (populated from API)
  final Provider? provider;
  final Service? service;
  final AppointmentClient? client;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.serviceId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.provider,
    this.service,
    this.client,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      providerId: json['providerId'] as String,
      serviceId: json['serviceId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: AppointmentStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      provider: json['provider'] != null
          ? Provider.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
      service: json['service'] != null
          ? Service.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      client: json['client'] != null
          ? AppointmentClient.fromJson(json['client'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'providerId': providerId,
      'serviceId': serviceId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Check if this appointment is upcoming (not past and not cancelled)
  bool get isUpcoming => 
      startTime.isAfter(DateTime.now()) && status != AppointmentStatus.cancelled;

  /// Check if this appointment is in the past or cancelled
  bool get isHistory => 
      startTime.isBefore(DateTime.now()) || status == AppointmentStatus.cancelled;

  /// Get the duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;
}

/// Appointment status enum
enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  factory AppointmentStatus.fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.pending;
      case 'CONFIRMED':
        return AppointmentStatus.confirmed;
      case 'COMPLETED':
        return AppointmentStatus.completed;
      case 'CANCELLED':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.completed:
        return 'Terminé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
    }
  }
}

/// Simplified client info returned with appointments
class AppointmentClient {
  final String id;
  final String? name;
  final String email;
  final String? phoneNumber;

  const AppointmentClient({
    required this.id,
    this.name,
    required this.email,
    this.phoneNumber,
  });

  factory AppointmentClient.fromJson(Map<String, dynamic> json) {
    return AppointmentClient(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  String get displayName => name ?? email;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/features/providers/data/models/appointment_model.dart';
import 'package:pmos_care/features/providers/domain/entities/appointment_entity.dart';

void main() {
  group('Appointment Clean Architecture Model Tests', () {
    final tDateTime = DateTime(2026, 6, 8, 10, 0);
    final tClientTimestamp = DateTime(2026, 6, 8, 18, 56);
    
    final tModel = AppointmentModel(
      id: '1',
      specialistName: 'Dr. Wumjah',
      specialistTitle: 'Ob-Gyn Endocrinologist',
      consultationType: 'Video Consultation',
      dateTime: tDateTime,
      status: 'Scheduled',
      specialistInitials: 'W',
      avatarColorValue: 4294967295, // 0xFFFFFFFF
      clientUpdatedTimestamp: tClientTimestamp,
    );

    test('should parse correctly from valid JSON document', () {
      final jsonMap = {
        'id': '1',
        'specialistName': 'Dr. Wumjah',
        'specialistTitle': 'Ob-Gyn Endocrinologist',
        'consultationType': 'Video Consultation',
        'dateTime': tDateTime.toIso8601String(),
        'status': 'Scheduled',
        'specialistInitials': 'W',
        'avatarColorValue': 4294967295,
        'clientUpdatedTimestamp': tClientTimestamp.toIso8601String(),
      };

      final result = AppointmentModel.fromJson(jsonMap);

      expect(result.id, equals(tModel.id));
      expect(result.specialistName, equals(tModel.specialistName));
      expect(result.specialistTitle, equals(tModel.specialistTitle));
      expect(result.dateTime, equals(tModel.dateTime));
      expect(result.avatarColorValue, equals(tModel.avatarColorValue));
    });

    test('should serialize correctly to a JSON map', () {
      final result = tModel.toJson();

      final expectedJson = {
        'id': '1',
        'specialistName': 'Dr. Wumjah',
        'specialistTitle': 'Ob-Gyn Endocrinologist',
        'consultationType': 'Video Consultation',
        'dateTime': tDateTime.toIso8601String(),
        'status': 'Scheduled',
        'specialistInitials': 'W',
        'avatarColorValue': 4294967295,
        'clientUpdatedTimestamp': tClientTimestamp.toIso8601String(),
      };

      expect(result, equals(expectedJson));
    });

    test('should correctly construct from an entity', () {
      final entity = AppointmentEntity(
        id: '2',
        specialistName: 'Dr. Saker',
        specialistTitle: 'Endocrine Specialist',
        consultationType: 'In-Clinic Visit',
        dateTime: tDateTime,
        status: 'Completed',
        specialistInitials: 'S',
        avatarColorValue: 4278190080,
        clientUpdatedTimestamp: tClientTimestamp,
      );

      final result = AppointmentModel.fromEntity(entity);

      expect(result.id, equals('2'));
      expect(result.status, equals('Completed'));
      expect(result.specialistName, equals('Dr. Saker'));
    });
  });
}

import 'package:url_launcher/url_launcher.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Opens the device's default email app pre-filled with appointment details.
  /// No credentials or external account needed.
  Future<bool> sendAppointmentNotification({
    required String specialistEmail,
    required String specialistName,
    required String patientName,
    required String appointmentDate,
    required String consultationType,
    required String appointmentId,
  }) async {
    if (specialistEmail.isEmpty) return false;

    final subject = 'New Appointment Request — PMOS Care (#$appointmentId)';
    final body = '''Dear $specialistName,

You have a new appointment request from your patient through PMOS Care.

Patient Name: $patientName
Consultation Type: $consultationType
Preferred Date & Time: $appointmentDate
Booking Reference: #$appointmentId

Please log in to the PMOS Care provider portal to confirm or reschedule this appointment.

This notification was sent automatically by the PMOS Care app.''';

    final uri = Uri(
      scheme: 'mailto',
      path: specialistEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

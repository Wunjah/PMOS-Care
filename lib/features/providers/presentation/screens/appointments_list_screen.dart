import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/appointment_provider.dart';
import '../../domain/entities/appointment_entity.dart';

class AppointmentsListScreen extends ConsumerWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentStateNotifierProvider);
    final now = DateTime.now();

    final upcoming = state.appointments.where((a) => a.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final past = state.appointments.where((a) => !a.dateTime.isAfter(now)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(appointmentStateNotifierProvider.notifier).loadAppointments(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.appointments.isEmpty
              ? _buildEmpty(context)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      _sectionHeader('Upcoming', Icons.event_outlined, AppTheme.primaryWellness),
                      const SizedBox(height: 8),
                      ...upcoming.map((a) => _AppointmentCard(appointment: a, isPast: false)),
                      const SizedBox(height: 20),
                    ],
                    if (past.isNotEmpty) ...[
                      _sectionHeader('Past', Icons.history, Colors.grey),
                      const SizedBox(height: 8),
                      ...past.map((a) => _AppointmentCard(appointment: a, isPast: true)),
                    ],
                  ],
                ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_outlined, size: 72, color: AppTheme.primaryWellness.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No Appointments Yet',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Book a consultation with a specialist to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.people_outline),
              label: const Text('Find a Specialist'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  final AppointmentEntity appointment;
  final bool isPast;
  const _AppointmentCard({required this.appointment, required this.isPast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('EEE, MMM d yyyy').format(appointment.dateTime);
    final timeStr = DateFormat('h:mm a').format(appointment.dateTime);
    final color = Color(appointment.avatarColorValue);

    final statusColor = isPast
        ? Colors.grey
        : appointment.status == 'Cancelled'
            ? Colors.red.shade400
            : Colors.green.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isPast ? Colors.grey.shade200 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: color,
              child: Text(
                appointment.specialistInitials,
                style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.specialistName,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPast ? Colors.grey : const Color(0xFF191C20))),
                  const SizedBox(height: 2),
                  Text(appointment.specialistTitle,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(timeStr, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryWellness.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(appointment.consultationType,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppTheme.primaryWellness, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isPast ? 'Completed' : appointment.status,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Cancel button for upcoming only
            if (!isPast && appointment.status != 'Cancelled')
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                tooltip: 'Cancel',
                onPressed: () => _confirmCancel(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Appointment?',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Text(
          'Cancel your appointment with ${appointment.specialistName}? This cannot be undone.',
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(appointmentStateNotifierProvider.notifier).cancelAppointment(appointment.id);
            },
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

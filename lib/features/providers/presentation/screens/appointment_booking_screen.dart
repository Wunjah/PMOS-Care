import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/email_service.dart';
import '../providers/appointment_provider.dart';
import 'video_call_screen.dart';

class AppointmentBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> specialist;
  const AppointmentBookingScreen({super.key, required this.specialist});

  @override
  ConsumerState<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends ConsumerState<AppointmentBookingScreen> {
  String _selectedType = 'Video Consultation';
  int _selectedDateIndex = 0;
  String _selectedTime = '10:00 AM';

  final List<Map<String, String>> _types = [
    {'name': 'Video Consultation', 'icon': 'videocam', 'subtitle': 'Secure tele-health call'},
    {'name': 'In-Clinic Visit', 'icon': 'local_hospital', 'subtitle': 'Direct face-to-face visit'},
    {'name': 'Text Consultation', 'icon': 'chat', 'subtitle': 'Q&A session via messaging'},
  ];

  final List<Map<String, String>> _dates = [
    {'day': 'Mon', 'num': '8', 'month': 'Jun'},
    {'day': 'Tue', 'num': '9', 'month': 'Jun'},
    {'day': 'Wed', 'num': '10', 'month': 'Jun'},
    {'day': 'Thu', 'num': '11', 'month': 'Jun'},
    {'day': 'Fri', 'num': '12', 'month': 'Jun'},
    {'day': 'Sat', 'num': '13', 'month': 'Jun'},
  ];

  final List<String> _timeSlots = [
    '09:00 AM', '10:00 AM', '11:30 AM',
    '02:00 PM', '03:00 PM', '04:30 PM',
  ];

  DateTime _buildDateTime() {
    final dateMap = _dates[_selectedDateIndex];
    final dayNum = int.parse(dateMap['num']!);
    final timeParts = _selectedTime.split(' ');
    final clockParts = timeParts[0].split(':');
    int hour = int.parse(clockParts[0]);
    final minute = int.parse(clockParts[1]);
    if (timeParts[1] == 'PM' && hour != 12) hour += 12;
    if (timeParts[1] == 'AM' && hour == 12) hour = 0;
    return DateTime(2026, 6, dayNum, hour, minute);
  }

  Future<void> _confirmBooking() async {
    final dateTime = _buildDateTime();
    final avatarColor = widget.specialist['avatarColor'] as Color? ?? Colors.teal;

    final bookingId = await ref.read(appointmentStateNotifierProvider.notifier).bookAppointment(
      specialistName: widget.specialist['name'] as String? ?? 'Specialist',
      specialistTitle: widget.specialist['title'] as String? ?? 'Specialist Doctor',
      consultationType: _selectedType,
      dateTime: dateTime,
      specialistInitials: widget.specialist['initials'] as String? ?? 'S',
      avatarColorValue: avatarColor.value,
    );

    if (!mounted) return;

    final dateMap = _dates[_selectedDateIndex];
    final dateStr = '${dateMap['day']}, ${dateMap['month']} ${dateMap['num']}';
    final specialistEmail = widget.specialist['email'] as String? ?? '';
    final specialistName = widget.specialist['name'] as String? ?? 'Specialist';
    final formattedDate = DateFormat("EEEE, MMMM d, yyyy 'at' h:mm a").format(dateTime);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Appointment Booked!',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Scheduled with ${widget.specialist['name']} on $dateStr at $_selectedTime.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Notify specialist button
              if (specialistEmail.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Notify Specialist by Email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryWellness,
                    side: const BorderSide(color: AppTheme.primaryWellness),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    EmailService().sendAppointmentNotification(
                      specialistEmail: specialistEmail,
                      specialistName: specialistName,
                      patientName: 'Patient',
                      appointmentDate: formattedDate,
                      consultationType: _selectedType,
                      appointmentId: bookingId,
                    );
                  },
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.primaryWellness, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fully encrypted & HIPAA-compliant virtual link created.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryWellness),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (_selectedType == 'Video Consultation') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => VideoCallScreen(specialist: widget.specialist),
                    ));
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                child: Text(_selectedType == 'Video Consultation' ? 'Join Video Room' : 'Done'),
              ),
              TextButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                child: const Text('Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specialist card
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: widget.specialist['avatarColor'] as Color,
                      child: Text(
                        widget.specialist['initials'] as String,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.specialist['name'] as String,
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          Text(
                            widget.specialist['title'] as String,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Consultation type
            const Text('Select Consultation Type', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            ..._types.map((type) {
              final isSelected = _selectedType == type['name'];
              final IconData icon;
              if (type['icon'] == 'videocam') {
                icon = Icons.videocam;
              } else if (type['icon'] == 'local_hospital') {
                icon = Icons.local_hospital;
              } else {
                icon = Icons.chat_bubble;
              }
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type['name']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryLight : Colors.white,
                    border: Border.all(color: isSelected ? AppTheme.primaryWellness : Colors.grey.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: isSelected ? AppTheme.primaryWellness : Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type['name']!, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primaryWellness : AppTheme.textDark)),
                            Text(type['subtitle']!, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryWellness, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Date
            const Text('Select Date', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                itemBuilder: (_, i) {
                  final dt = _dates[i];
                  final isSelected = _selectedDateIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = i),
                    child: Container(
                      width: 58,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryWellness : Colors.white,
                        border: Border.all(color: isSelected ? AppTheme.primaryWellness : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(dt['day']!, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: isSelected ? Colors.white70 : Colors.grey)),
                          const SizedBox(height: 4),
                          Text(dt['num']!, style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textDark)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Time
            const Text('Select Time Slot', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.2),
              itemCount: _timeSlots.length,
              itemBuilder: (_, i) {
                final slot = _timeSlots[i];
                final isSelected = _selectedTime == slot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = slot),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryWellness : Colors.white,
                      border: Border.all(color: isSelected ? AppTheme.primaryWellness : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(slot, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppTheme.textDark)),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: _confirmBooking,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Confirm Appointment', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

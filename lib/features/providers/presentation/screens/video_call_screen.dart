import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoCallScreen extends StatelessWidget {
  final Map<String, dynamic> specialist;
  const VideoCallScreen({super.key, required this.specialist});

  Future<void> _openMeet(BuildContext context) async {
    final initials = (specialist['initials'] as String? ?? 'pm').toLowerCase().replaceAll(' ', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    final roomName = 'pmoscare-$initials-$timestamp';
    final uri = Uri.parse('https://meet.google.com/$roomName');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Meet. Please install the Meet app or Chrome.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openNewMeet(BuildContext context) async {
    final uri = Uri.parse('https://meet.google.com/new');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimary = Color(0xFF5152B9);
    final avatarColor = specialist['avatarColor'] as Color? ?? kPrimary;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Video Consultation',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarColor,
                        boxShadow: [BoxShadow(color: avatarColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 4)],
                      ),
                      child: Center(
                        child: Text(
                          specialist['initials'] as String? ?? 'DR',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      specialist['name'] as String? ?? 'Specialist',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      specialist['title'] as String? ?? 'Healthcare Provider',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.video_call_outlined, color: Color(0xFF1A73E8), size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            'Join via Google Meet',
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Opens Google Meet in your browser or the Meet app. Share the room link with your specialist.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white.withOpacity(0.6), height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _openMeet(context),
                            icon: const Icon(Icons.videocam, size: 20),
                            label: const Text('Start Meeting Room'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A73E8),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _openNewMeet(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create New Meeting'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Share the meeting link with ${specialist['name'] ?? 'your specialist'} before the session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white.withOpacity(0.4), height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

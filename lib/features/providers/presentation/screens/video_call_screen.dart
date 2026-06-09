import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> specialist;
  const VideoCallScreen({super.key, required this.specialist});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  int _secondsElapsed = 0;
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _hangUp() {
    _callTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('End Consultation', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to end this clinical session?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _startTimer(); // resume timer
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.glycemicHigh),
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close video call screen
                Navigator.pop(context); // Close booking screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Consultation session ended and details archived safely.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('End Call'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background: Specialist Live Feed Mock
            Positioned.fill(
              child: Container(
                color: Colors.grey.shade900,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isVideoOff) ...[
                      const Icon(Icons.videocam_off, color: Colors.white24, size: 72),
                      const SizedBox(height: 16),
                      const Text(
                        'Video feed paused',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ] else ...[
                      // Pulsing avatar background to simulate live streaming
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.2),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (widget.specialist['avatarColor'] as Color).withOpacity(0.4),
                                width: 8 * scale,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: widget.specialist['avatarColor'] as Color,
                              child: Text(
                                widget.specialist['initials'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                        onEnd: () {},
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.specialist['name'] as String,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Connected to secure server',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Top Info Overlay (HIPAA / Timer / Name)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Specialist Details / Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Secure Session',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.specialist['title'] as String,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Call Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(_secondsElapsed),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating PiP (User Preview)
            Positioned(
              right: 16,
              bottom: 110,
              child: Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Simulated webcam view of user
                      Container(
                        color: Colors.indigo.shade900,
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white54, size: 36),
                        ),
                      ),
                      if (_isMuted)
                        const Positioned(
                          bottom: 4,
                          left: 4,
                          child: Icon(Icons.mic_off, color: Colors.redAccent, size: 14),
                        ),
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Text(
                          'You',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls panel
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Microphone
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red.shade900 : Colors.white24,
                      iconColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isMuted ? 'Microphone muted' : 'Microphone unmuted'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    // Hang Up Call
                    _buildControlButton(
                      icon: Icons.call_end,
                      color: AppTheme.glycemicHigh,
                      iconColor: Colors.white,
                      onPressed: _hangUp,
                      size: 60,
                    ),
                    // Toggle Camera Feed
                    _buildControlButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      color: _isVideoOff ? Colors.red.shade900 : Colors.white24,
                      iconColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _isVideoOff = !_isVideoOff;
                        });
                      },
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

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
        iconSize: size * 0.5,
      ),
    );
  }
}

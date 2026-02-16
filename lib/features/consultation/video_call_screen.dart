import 'package:flutter/material.dart';
import 'package:carelink/core/constants/app_colors.dart';

class VideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> consultation;

  const VideoCallScreen({super.key, required this.consultation});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  Widget build(BuildContext context) {
    final doctorName =
        widget.consultation['doctor']?['users']?['full_name'] ?? 'Doctor';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Video View (Doctor)
          Center(
            child: Container(
              color: Colors.grey.shade900,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to $doctorName...',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          // Local Preview (Patient)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _isVideoOff
                    ? const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white),
                      )
                    : Container(color: Colors.grey.shade700),
              ),
            ),
          ),

          // Header Info
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 12),
                      SizedBox(width: 8),
                      Text(
                        '00:00',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.white24 : Colors.white10,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: AppColors.error,
                  iconColor: Colors.white,
                  onTap: () => Navigator.pop(context),
                  size: 64,
                ),
                _buildControlButton(
                  icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                  color: _isVideoOff ? Colors.white24 : Colors.white10,
                  onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}

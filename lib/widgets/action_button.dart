import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isActive ? Colors.blueAccent : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.blueAccent : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

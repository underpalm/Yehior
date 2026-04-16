import 'package:flutter/material.dart';
import '../constants/theme.dart';

class DrawerIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DrawerIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: kTextPrimary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
          ],
        ),
      ),
    );
  }
}

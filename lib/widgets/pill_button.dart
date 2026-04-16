import 'package:flutter/material.dart';
import '../constants/theme.dart';

class PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const PillButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: kBgColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: kDivider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              color: kTextPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

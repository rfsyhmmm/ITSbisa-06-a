import 'package:flutter/material.dart';

/// Tombol utama ITSbisa (Login, Donate, Donasi, Ajukan).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color; // isi AppColors.navy untuk tombol Donasi
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        style: color == null
            ? null
            : FilledButton.styleFrom(backgroundColor: color),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

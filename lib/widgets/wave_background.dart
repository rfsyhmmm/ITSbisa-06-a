import 'package:flutter/material.dart';

/// Hiasan gelombang biru dari Figma (gambar hasil export).
/// - Atas (Login, Register): assets/images/wave_top.png
/// - Bawah (Splash), atBottom: true: assets/images/wave_bottom.png
class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key, this.atBottom = false});

  final bool atBottom;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      atBottom ? 'assets/images/wave_bottom.png' : 'assets/images/wave_top.png',
      width: double.infinity,
      fit: BoxFit.fitWidth,
      alignment: atBottom ? Alignment.bottomCenter : Alignment.topCenter,
    );
  }
}

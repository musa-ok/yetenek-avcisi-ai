import 'package:flutter/material.dart';

/// AI / Topluluk / Birleşik OVR satırı (scout puanı varken).
class CombinedOvrStrip extends StatelessWidget {
  const CombinedOvrStrip({
    super.key,
    required this.aiOvr,
    required this.displayOvr,
    this.communityOvr,
    this.scoutCount = 0,
  });

  final int aiOvr;
  final int displayOvr;
  final int? communityOvr;
  final int scoutCount;

  @override
  Widget build(BuildContext context) {
    if (scoutCount <= 0 || communityOvr == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chip('AI', aiOvr, const Color(0xFF64B5F6)),
          _chip('Topluluk', communityOvr!, const Color(0xFFFFB74D)),
          _chip('Birleşik', displayOvr, const Color(0xFF00E676), bold: true),
          Text(
            '$scoutCount scout',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int value, Color color, {bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

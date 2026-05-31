import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Slot bazlı AI test puanları (skill_scores.slot_breakdown).
class SlotBreakdownCard extends StatelessWidget {
  const SlotBreakdownCard({
    super.key,
    required this.breakdown,
    this.analysisVersion,
  });

  final List<Map<String, dynamic>> breakdown;
  final String? analysisVersion;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Test Bazlı Puanlar',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (analysisVersion == 'slot_v1')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Slot v1',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Her video ayrı değerlendirildi. Koşuda yeşil etiket = video ile ölçülen süre.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ...breakdown.map(_buildRow),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> row) {
    final label = '${row['label'] ?? row['skill'] ?? 'Test'}';
    final score = row['score'] is int
        ? row['score'] as int
        : int.tryParse('${row['score']}') ?? 0;
    final attr = '${row['attribute'] ?? ''}';
    final timing = row['timing_sec'];
    final timingEst = row['timing_estimated'] == true;
    final obs = '${row['observation'] ?? ''}'.trim();

    Color scoreColor;
    if (score >= 80) {
      scoreColor = const Color(0xFF4CAF50);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFFF9800);
    } else {
      scoreColor = const Color(0xFFEF5350);
    }

    final timingSource = '${row['timing_source'] ?? ''}';
    String? sub;
    if (timing != null) {
      if (timingSource == 'opencv') {
        sub = 'Süre: $timing sn · video ölçümü';
      } else if (timingEst) {
        sub = 'Süre: $timing sn · AI tahmini';
      } else {
        sub = 'Süre: $timing sn';
      }
    } else if (attr.isNotEmpty) {
      sub = _attrLabel(attr);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$score',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(
                sub,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
            if (obs.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                obs,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _attrLabel(String attr) {
    switch (attr) {
      case 'pace':
        return '→ Hız';
      case 'finishing':
        return '→ Bitiricilik';
      case 'passing':
        return '→ Pas';
      case 'dribbling':
        return '→ Dripling';
      case 'defending':
        return '→ Savunma';
      case 'strength':
        return '→ Fizik';
      case 'physical_attributes':
        return '→ Fiziksel';
      case 'technical_ability':
        return '→ Teknik';
      case 'tactical_awareness':
        return '→ Taktik';
      default:
        return '→ $attr';
    }
  }
}

import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Slot bazlı AI test puanları (skill_scores.slot_breakdown).
class SlotBreakdownCard extends StatefulWidget {
  const SlotBreakdownCard({
    super.key,
    required this.breakdown,
  });

  final List<Map<String, dynamic>> breakdown;

  @override
  State<SlotBreakdownCard> createState() => _SlotBreakdownCardState();
}

class _SlotBreakdownCardState extends State<SlotBreakdownCard> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    if (widget.breakdown.isEmpty) return const SizedBox.shrink();

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
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Her video ayrı değerlendirildi. Detay için test adına dokunun.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.breakdown.asMap().entries.map(
                (e) => _buildRow(e.key, e.value),
              ),
        ],
      ),
    );
  }

  Widget _buildRow(int index, Map<String, dynamic> row) {
    final label = '${row['label'] ?? row['skill'] ?? 'Test'}';
    final score = row['score'] is int
        ? row['score'] as int
        : int.tryParse('${row['score']}') ?? 0;
    final attr = '${row['attribute'] ?? ''}';
    final timing = row['timing_sec'];
    final timingEst = row['timing_estimated'] == true;
    final obs = '${row['observation'] ?? ''}'.trim();
    final expanded = _expanded.contains(index);

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: obs.isEmpty
              ? null
              : () => setState(() {
                    if (expanded) {
                      _expanded.remove(index);
                    } else {
                      _expanded.add(index);
                    }
                  }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: expanded
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : Colors.white10,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (obs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6, top: 2),
                        child: Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                    maxLines: expanded ? null : 2,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (!expanded && obs.length > 80)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tamamını oku',
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
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

import 'package:flutter_test/flutter_test.dart';
import 'package:yetenek_avcisi/core/utils/fifa_six_stats.dart';
import 'package:yetenek_avcisi/services/multi_upload_service.dart';

MultiVideoPlayer _session({
  required int id,
  String? updatedAt,
  int overall = 0,
  int? pace,
  int? finishing,
  int? defending,
  List<Map<String, dynamic>>? slotBreakdown,
}) {
  return MultiVideoPlayer(
    id: id,
    userId: 1,
    name: 'Test',
    age: 18,
    position: 'Forvet',
    positionCode: 'ST',
    overallRating: overall,
    averageRating: 0,
    completionPercentage: 100,
    isComplete: true,
    videos: const [],
    skillScores: const {},
    aiStrengths: const [],
    aiImprovements: const [],
    pace: pace,
    finishing: finishing,
    defending: defending,
    updatedAt: updatedAt,
    slotBreakdown: slotBreakdown ?? const [],
  );
}

void main() {
  test('picks latest non-zero stat per attribute across sessions', () {
    final merged = buildMergedLatestSixStats([
      _session(
        id: 2,
        updatedAt: '2026-05-20T10:00:00Z',
        overall: 70,
        pace: 80,
        defending: 0,
      ),
      _session(
        id: 1,
        updatedAt: '2026-05-10T10:00:00Z',
        overall: 65,
        defending: 55,
        pace: 60,
      ),
    ]);

    expect(merged, isNotNull);
    expect(merged!.pace, 80);
    expect(merged.defending, 55);
    expect(merged.overallRating, greaterThan(0));
  });

  test('returns null display overall when nothing measured', () {
    final merged = buildMergedLatestSixStats([
      _session(id: 1, updatedAt: '2026-05-01T00:00:00Z'),
    ]);
    expect(merged, isNotNull);
    expect(merged!.hasMeasurableStats, isFalse);
    expect(merged.displayOverall, '—');
  });
}

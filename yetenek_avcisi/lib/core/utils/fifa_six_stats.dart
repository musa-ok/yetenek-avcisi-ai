import '../../services/multi_upload_service.dart';

/// FIFA kartı / istatistik ekranı için 6 ana metrik (ölçülmeyen = null).
class FifaSixStats {
  const FifaSixStats({
    this.pace,
    this.finishing,
    this.passing,
    this.dribbling,
    this.defending,
    this.strength,
  });

  final int? pace;
  final int? finishing;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? strength;

  int? get sho => finishing;
  int? get pas => passing;
  int? get dri => dribbling;
  int? get def => defending;
  int? get phy => strength;
  int? get pac => pace;
}

int? _readInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v > 0 ? v : null;
  if (v is num) return v > 0 ? v.toInt() : null;
  if (v is String) {
    final p = int.tryParse(v);
    return p != null && p > 0 ? p : null;
  }
  return null;
}

int? _clampStat(int? v) {
  if (v == null || v <= 0) return null;
  return v.clamp(1, 99);
}

/// Yalnızca ölçülen slotlar + skill_scores; eksikler doldurulmaz.
FifaSixStats resolveFifaSixStats({
  required int overallRating,
  int? pace,
  int? finishing,
  int? passing,
  int? dribbling,
  int? defending,
  int? strength,
  int? physicalAttributes,
  Map<String, dynamic>? skillScores,
  List<Map<String, dynamic>>? slotBreakdown,
}) {
  final ss = skillScores ?? {};
  final breakdown = slotBreakdown ?? _breakdownFrom(ss);
  final hasBreakdown = breakdown.isNotEmpty;

  // Önce doğrudan alanlar (API); breakdown varsa yalnızca slotlardan türet
  var pac = hasBreakdown ? null : (pace ?? _readInt(ss['pace']));
  var sho = hasBreakdown ? null : (finishing ?? _readInt(ss['finishing']));
  var pas = hasBreakdown ? null : (passing ?? _readInt(ss['passing']));
  var dri = hasBreakdown ? null : (dribbling ?? _readInt(ss['dribbling']));
  var def = hasBreakdown ? null : (defending ?? _readInt(ss['defending']));
  var phy = hasBreakdown
      ? null
      : (strength ??
          physicalAttributes ??
          _readInt(ss['strength']) ??
          _readInt(ss['physical_attributes']));
  final buckets = <String, List<int>>{
    'pace': [],
    'finishing': [],
    'passing': [],
    'dribbling': [],
    'defending': [],
    'strength': [],
  };
  final physicalExtra = <int>[];

  for (final row in breakdown) {
    final score = _readInt(row['score']);
    if (score == null) continue;
    final attr = '${row['attribute'] ?? ''}';
    if (buckets.containsKey(attr)) {
      buckets[attr]!.add(score);
    } else if (attr == 'physical_attributes') {
      physicalExtra.add(score);
    }
  }

  int? avg(List<int> xs) =>
      xs.isEmpty ? null : (xs.reduce((a, b) => a + b) / xs.length).round();

  pac ??= avg(buckets['pace']!);
  sho ??= avg(buckets['finishing']!);
  pas ??= avg(buckets['passing']!);
  dri ??= avg(buckets['dribbling']!);
  def ??= avg(buckets['defending']!);
  phy ??= avg(buckets['strength']!) ?? avg(physicalExtra);

  if (!hasBreakdown) {
    pac ??= pace ?? _readInt(ss['pace']);
    sho ??= finishing ?? _readInt(ss['finishing']);
    pas ??= passing ?? _readInt(ss['passing']);
    dri ??= dribbling ?? _readInt(ss['dribbling']);
    def ??= defending ?? _readInt(ss['defending']);
    phy ??= strength ??
        physicalAttributes ??
        _readInt(ss['strength']) ??
        _readInt(ss['physical_attributes']);
  }

  return FifaSixStats(
    pace: _clampStat(pac),
    finishing: _clampStat(sho),
    passing: _clampStat(pas),
    dribbling: _clampStat(dri),
    defending: _clampStat(def),
    strength: _clampStat(phy),
  );
}

List<Map<String, dynamic>> _breakdownFrom(Map<String, dynamic> ss) {
  final raw = ss['slot_breakdown'];
  if (raw is List) {
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
}

extension MultiVideoPlayerFifaSix on MultiVideoPlayer {
  FifaSixStats get fifaSix => resolveFifaSixStats(
        overallRating: overallRating,
        pace: pace,
        finishing: finishing,
        passing: passing,
        dribbling: dribbling,
        defending: defending,
        strength: strength,
        physicalAttributes: physicalAttributes,
        skillScores: skillScores,
        slotBreakdown: slotBreakdown,
      );
}

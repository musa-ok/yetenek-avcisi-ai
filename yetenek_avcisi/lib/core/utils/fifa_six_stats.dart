import 'package:flutter/foundation.dart';
import 'package:yetenek_avcisi/app_services.dart';

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
  bool fillMissing = true,
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

  final raw = FifaSixStats(
    pace: _clampStat(pac),
    finishing: _clampStat(sho),
    passing: _clampStat(pas),
    dribbling: _clampStat(dri),
    defending: _clampStat(def),
    strength: _clampStat(phy),
  );
  if (!fillMissing) return raw;
  return fillMissingFifaStatsWithAverage(raw, fallbackOvr: overallRating);
}

/// Yalnızca ölçülen slot/alanlar; eksikler doldurulmaz (ana sayfa birleştirme).
FifaSixStats resolveFifaSixStatsMeasuredOnly({
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
  return resolveFifaSixStats(
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
    fillMissing: false,
  );
}

/// Ölçülmemiş FIFA altı değerleri, ölçülenlerin ortalamasıyla doldurulur (UI).
FifaSixStats fillMissingFifaStatsWithAverage(
  FifaSixStats six, {
  required int fallbackOvr,
}) {
  final measured = [
    six.pace,
    six.finishing,
    six.passing,
    six.dribbling,
    six.defending,
    six.strength,
  ].whereType<int>().where((v) => v > 0).toList();

  final fill = measured.isEmpty
      ? fallbackOvr.clamp(1, 99)
      : (measured.reduce((a, b) => a + b) / measured.length).round().clamp(1, 99);

  int pick(int? v) => (v != null && v > 0) ? v : fill;

  return FifaSixStats(
    pace: pick(six.pace),
    finishing: pick(six.finishing),
    passing: pick(six.passing),
    dribbling: pick(six.dribbling),
    defending: pick(six.defending),
    strength: pick(six.strength),
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

/// Keşfet / oyuncu detay kartı (PlayerListItem).
extension PlayerListItemFifaSix on PlayerListItem {
  FifaSixStats get fifaSix => resolveFifaSixStats(
        overallRating: fifaCardOvr,
        pace: pac,
        finishing: sho,
        passing: pas,
        dribbling: dri,
        defending: def,
        strength: phy,
        skillScores: const {},
        slotBreakdown: slotBreakdown,
      );
}

/// Tüm tamamlanmış analizlerden tek FIFA kartı (ana sayfa + profil).
class UnifiedFifaCard {
  const UnifiedFifaCard({
    required this.six,
    required this.overallRating,
    required this.mergedBreakdown,
    this.latestReport,
    this.sessionCount = 0,
  });

  final FifaSixStats six;
  final int overallRating;
  final List<Map<String, dynamic>> mergedBreakdown;
  final String? latestReport;
  final int sessionCount;
}

bool _hasCompletedAnalysis(MultiVideoPlayer p) {
  final r = p.aiSummaryReport?.trim() ?? '';
  return p.overallRating > 0 &&
      r.isNotEmpty &&
      r != 'Rapor oluşturulamadı';
}

/// Ana sayfa: her özellik için en güncel (>0) ölçüm; OVR = ölçülenlerin ortalaması.
class MergedLatestSixStats {
  const MergedLatestSixStats({
    this.pace,
    this.finishing,
    this.passing,
    this.dribbling,
    this.defending,
    this.strength,
    required this.overallRating,
    this.latestReport,
    required this.sessionCount,
    this.latestPosition,
    this.latestAnalysisDateLabel,
    this.latestAnalysisPlayerId,
    this.ovrDelta7d,
    this.uploadedVideoCount = 0,
    this.requiredVideoCount = 3,
  });

  final int? pace;
  final int? finishing;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? strength;
  final int overallRating;
  final String? latestReport;
  final int sessionCount;
  final String? latestPosition;
  final String? latestAnalysisDateLabel;
  final int? latestAnalysisPlayerId;
  final int? ovrDelta7d;
  final int uploadedVideoCount;
  final int requiredVideoCount;

  bool get hasVideoProgress =>
      requiredVideoCount > 0 && uploadedVideoCount < requiredVideoCount;

  bool get hasMeasurableStats =>
      [pace, finishing, passing, dribbling, defending, strength]
          .any((v) => v != null && v > 0);

  String displayStat(int? v) =>
      (v == null || v <= 0) ? '—' : '$v';

  String get displayOverall =>
      overallRating > 0 ? '$overallRating' : '—';
}

int countUploadedVideos(MultiVideoPlayer p) {
  var n = 0;
  for (final v in p.videos) {
    if (v.isKosuSlot) {
      if (v.kosuFlatUploaded) n++;
      if (v.kosuUphillUploaded) n++;
    } else if (v.url != null && v.url!.trim().isNotEmpty) {
      n++;
    }
  }
  return n;
}

DateTime? sessionDateTime(MultiVideoPlayer p) {
  for (final raw in [p.updatedAt, p.createdAt]) {
    if (raw == null || raw.isEmpty) continue;
    final t = DateTime.tryParse(raw);
    if (t != null) return t;
  }
  return null;
}

String formatSessionDateLabel(MultiVideoPlayer p) {
  final t = sessionDateTime(p);
  if (t == null) return '';
  final d = t.day.toString().padLeft(2, '0');
  final m = t.month.toString().padLeft(2, '0');
  return '$d.$m.${t.year}';
}

int _sessionMeasuredOvr(MultiVideoPlayer p) {
  final six = _measuredSixForSession(p);
  final measured = [
    six.pace,
    six.finishing,
    six.passing,
    six.dribbling,
    six.defending,
    six.strength,
  ].whereType<int>().where((v) => v > 0).toList();
  if (measured.isEmpty) return p.overallRating > 0 ? p.overallRating : 0;
  return (measured.reduce((a, b) => a + b) / measured.length).round().clamp(1, 99);
}

int? computeOvrDelta7d(List<MultiVideoPlayer> newestFirst, int currentOvr) {
  if (currentOvr <= 0 || newestFirst.isEmpty) return null;
  final now = DateTime.now();
  for (final p in newestFirst) {
    final t = sessionDateTime(p);
    if (t == null) continue;
    if (now.difference(t).inDays >= 7) {
      final past = _sessionMeasuredOvr(p);
      if (past > 0 && currentOvr > past) return currentOvr - past;
      return null;
    }
  }
  return null;
}

int _sessionSortKey(MultiVideoPlayer p) {
  for (final raw in [p.updatedAt, p.createdAt]) {
    if (raw == null || raw.isEmpty) continue;
    final t = DateTime.tryParse(raw);
    if (t != null) return t.millisecondsSinceEpoch;
  }
  return p.id;
}

List<MultiVideoPlayer> sortAnalysesNewestFirst(List<MultiVideoPlayer> players) {
  final copy = List<MultiVideoPlayer>.from(players);
  copy.sort((a, b) {
    final byTime = _sessionSortKey(b).compareTo(_sessionSortKey(a));
    if (byTime != 0) return byTime;
    return b.id.compareTo(a.id);
  });
  return copy;
}

FifaSixStats _measuredSixForSession(MultiVideoPlayer p) {
  return resolveFifaSixStatsMeasuredOnly(
    overallRating: p.overallRating,
    pace: p.pace,
    finishing: p.finishing,
    passing: p.passing,
    dribbling: p.dribbling,
    defending: p.defending,
    strength: p.strength,
    physicalAttributes: p.physicalAttributes,
    skillScores: p.skillScores,
    slotBreakdown: p.slotBreakdown,
  );
}

int? _pickLatestStat(
  List<MultiVideoPlayer> newestFirst,
  int? Function(FifaSixStats) read,
) {
  for (final p in newestFirst) {
    final v = read(_measuredSixForSession(p));
    if (v != null && v > 0) return v;
  }
  return null;
}

/// Tüm analiz oturumlarından özellik bazlı en güncel ölçümler.
MergedLatestSixStats? buildMergedLatestSixStats(List<MultiVideoPlayer> players) {
  if (players.isEmpty) return null;

  try {
    return _buildMergedLatestSixStatsImpl(players);
  } catch (e, st) {
    assert(() {
      debugPrint('[buildMergedLatestSixStats] $e\n$st');
      return true;
    }());
    return null;
  }
}

MergedLatestSixStats? _buildMergedLatestSixStatsImpl(List<MultiVideoPlayer> players) {
  final newestFirst = sortAnalysesNewestFirst(players);
  final pace = _pickLatestStat(newestFirst, (s) => s.pace);
  final finishing = _pickLatestStat(newestFirst, (s) => s.finishing);
  final passing = _pickLatestStat(newestFirst, (s) => s.passing);
  final dribbling = _pickLatestStat(newestFirst, (s) => s.dribbling);
  final defending = _pickLatestStat(newestFirst, (s) => s.defending);
  final strength = _pickLatestStat(newestFirst, (s) => s.strength);

  final measured = [pace, finishing, passing, dribbling, defending, strength]
      .whereType<int>()
      .where((v) => v > 0)
      .toList();

  final ovr = measured.isEmpty
      ? 0
      : (measured.reduce((a, b) => a + b) / measured.length).round().clamp(1, 99);

  String? latestReport;
  for (final p in newestFirst) {
    final r = p.aiSummaryReport?.trim() ?? '';
    if (r.isNotEmpty && r != 'Rapor oluşturulamadı') {
      latestReport = r;
      break;
    }
  }

  final latest = newestFirst.first;
  MultiVideoPlayer? activeSession;
  for (final p in newestFirst) {
    if (!p.isComplete) {
      activeSession = p;
      break;
    }
  }
  activeSession ??= latest;
  final requiredVideos = activeSession.requiredVideoCount > 0
      ? activeSession.requiredVideoCount
      : 3;

  return MergedLatestSixStats(
    pace: pace,
    finishing: finishing,
    passing: passing,
    dribbling: dribbling,
    defending: defending,
    strength: strength,
    overallRating: ovr,
    latestReport: latestReport,
    sessionCount: players.length,
    latestPosition: latest.position.trim().isNotEmpty ? latest.position : null,
    latestAnalysisDateLabel: formatSessionDateLabel(latest),
    latestAnalysisPlayerId: latest.id > 0 ? latest.id : null,
    ovrDelta7d: computeOvrDelta7d(newestFirst, ovr),
    uploadedVideoCount: countUploadedVideos(activeSession),
    requiredVideoCount: requiredVideos,
  );
}

UnifiedFifaCard? buildUnifiedFifaFromPlayers(List<MultiVideoPlayer> players) {
  final completed =
      players.where(_hasCompletedAnalysis).toList()
        ..sort((a, b) => b.id.compareTo(a.id));
  if (completed.isEmpty) return null;

  final mergedBreakdown = <Map<String, dynamic>>[];
  for (final p in completed) {
    mergedBreakdown.addAll(p.slotBreakdown);
  }

  final six = resolveFifaSixStats(
    overallRating: 50,
    slotBreakdown: mergedBreakdown,
  );

  final measured = [
    six.pace,
    six.finishing,
    six.passing,
    six.dribbling,
    six.defending,
    six.strength,
  ].whereType<int>().toList();

  final ovr = measured.isEmpty
      ? completed.first.overallRating
      : (measured.reduce((a, b) => a + b) / measured.length).round().clamp(1, 99);

  return UnifiedFifaCard(
    six: six,
    overallRating: ovr,
    mergedBreakdown: mergedBreakdown,
    latestReport: completed.first.aiSummaryReport,
    sessionCount: completed.length,
  );
}

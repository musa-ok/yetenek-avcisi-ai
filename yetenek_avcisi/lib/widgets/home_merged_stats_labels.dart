/// Ana sayfa istatistik bölümü metinleri (main.dart import döngüsü olmadan).
class HomeMergedStatsLabels {
  const HomeMergedStatsLabels({
    required this.sectionTitle,
    required this.ratingOverall,
    required this.statPace,
    required this.statShooting,
    required this.statPassing,
    required this.statDribbling,
    required this.statDefending,
    required this.statPhysical,
    required this.myStatsEmptyHint,
    required this.shareStats,
    required this.shareFailed,
    required this.appName,
    required this.ovrRise7d,
  });

  final String sectionTitle;
  final String ratingOverall;
  final String statPace;
  final String statShooting;
  final String statPassing;
  final String statDribbling;
  final String statDefending;
  final String statPhysical;
  final String myStatsEmptyHint;
  final String shareStats;
  final String shareFailed;
  final String appName;
  final String Function(int delta) ovrRise7d;
}

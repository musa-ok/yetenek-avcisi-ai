import 'package:flutter/foundation.dart';

import 'utils/fifa_six_stats.dart';

/// Ana sayfa birleştirilmiş istatistikler.
final ValueNotifier<MergedLatestSixStats?> homeMergedStatsNotifier =
    ValueNotifier<MergedLatestSixStats?>(null);

/// Oyuncunun analiz oturumu sayısı (FAB metni).
final ValueNotifier<int> myAnalysisSessionCountNotifier = ValueNotifier<int>(0);

/// Keşfet / ana sayfa oyuncu listesi yenileme sinyali.
final ValueNotifier<int> playersRefreshNotifier = ValueNotifier<int>(0);

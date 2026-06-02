import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_theme.dart';
import '../core/utils/fifa_share_image.dart';
import '../core/utils/fifa_six_stats.dart';
import '../core/utils/share_helper.dart';
import 'home_merged_stats_labels.dart';

/// Ana sayfa — birleştirilmiş güncel 6 stat + hero OVR + paylaşım.
class HomeMergedStatsSection extends StatefulWidget {
  const HomeMergedStatsSection({
    super.key,
    required this.merged,
    required this.labels,
    required this.playerName,
  });

  final MergedLatestSixStats merged;
  final HomeMergedStatsLabels labels;
  final String playerName;

  @override
  State<HomeMergedStatsSection> createState() => _HomeMergedStatsSectionState();
}

class _HomeMergedStatsSectionState extends State<HomeMergedStatsSection> {
  final GlobalKey _shareKey = GlobalKey();
  final GlobalKey _shareAnchorKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareStats() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final ctx = _shareKey.currentContext;
      if (ctx == null) throw Exception('Kart hazır değil');
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      await WidgetsBinding.instance.endOfFrame;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Görsel oluşturulamadı');
      var png = byteData.buffer.asUint8List();
      png = await FifaShareImage.addWatermark(png);

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/home_stats_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(png);

      final m = widget.merged;
      final lab = widget.labels;
      final lines = <String>[
        '🎮 ${widget.playerName}',
        '${lab.ratingOverall}: ${m.displayOverall}',
        '${lab.statPace}: ${m.displayStat(m.pace)}',
        '${lab.statShooting}: ${m.displayStat(m.finishing)}',
        '${lab.statPassing}: ${m.displayStat(m.passing)}',
        '${lab.statDribbling}: ${m.displayStat(m.dribbling)}',
        '${lab.statDefending}: ${m.displayStat(m.defending)}',
        '${lab.statPhysical}: ${m.displayStat(m.strength)}',
        lab.appName,
      ];

      await ShareHelper.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: lines.join('\n'),
        context: context,
        anchorKey: _shareAnchorKey,
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('${widget.labels.shareFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.merged;
    final lab = widget.labels;
    const accent = AppColors.accentGreen;
    const cardBg = AppColors.cardBackground;

    final gridStats = <_GridStat>[
      _GridStat(lab.statPace, m.displayStat(m.pace), Icons.directions_run_rounded),
      _GridStat(lab.statShooting, m.displayStat(m.finishing), Icons.sports_soccer_rounded),
      _GridStat(lab.statPassing, m.displayStat(m.passing), Icons.swap_horiz_rounded),
      _GridStat(lab.statDribbling, m.displayStat(m.dribbling), Icons.control_camera_rounded),
      _GridStat(lab.statDefending, m.displayStat(m.defending), Icons.shield_outlined),
      _GridStat(lab.statPhysical, m.displayStat(m.strength), Icons.fitness_center_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lab.sectionTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              key: _shareAnchorKey,
              tooltip: lab.shareStats,
              onPressed: _sharing ? null : _shareStats,
              icon: _sharing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, color: accent),
            ),
          ],
        ),
        if (!m.hasMeasurableStats) ...[
          const SizedBox(height: 6),
          Text(
            lab.myStatsEmptyHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        RepaintBoundary(
          key: _shareKey,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Text(
                  lab.ratingOverall,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 12),
                _HeroOvrBadge(value: m.displayOverall),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    for (final s in gridStats) _StatGridCard(stat: s),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroOvrBadge extends StatelessWidget {
  const _HeroOvrBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accentGreen;
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: accent, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: TextStyle(
          color: value == '—' ? Colors.white38 : accent,
          fontSize: value.length >= 2 ? 48 : 52,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _GridStat {
  const _GridStat(this.title, this.value, this.icon);
  final String title;
  final String value;
  final IconData icon;
}

class _StatGridCard extends StatelessWidget {
  const _StatGridCard({required this.stat});

  final _GridStat stat;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accentGreen;
    final hasValue = stat.value != '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasValue
              ? accent.withValues(alpha: 0.35)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(stat.icon, color: accent, size: 22),
          Text(
            stat.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            stat.value,
            style: TextStyle(
              color: hasValue ? accent : Colors.white38,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

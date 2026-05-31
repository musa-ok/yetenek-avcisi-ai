import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:yetenek_avcisi/app_services.dart';

const _card = Color(0xFF151C2B);
const _green = Color(0xFF00FF87);

class PlayerCompareScreen extends StatefulWidget {
  const PlayerCompareScreen({
    super.key,
    required this.playerA,
    this.playerB,
    this.allPlayers = const [],
  });

  final PlayerListItem playerA;
  final PlayerListItem? playerB;
  final List<PlayerListItem> allPlayers;

  @override
  State<PlayerCompareScreen> createState() => _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends State<PlayerCompareScreen> {
  late PlayerListItem _a;
  PlayerListItem? _b;
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _a = widget.playerA;
    _b = widget.playerB;
    if (_b != null) _load();
  }

  Future<void> _load() async {
    if (_b == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await BackendApi.comparePlayers(_a.id, _b!.id);
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickB() async {
    final others = widget.allPlayers.where((p) => p.id != _a.id).toList();
    if (others.isEmpty) return;
    final picked = await showModalBottomSheet<PlayerListItem>(
      context: context,
      backgroundColor: const Color(0xFF101828),
      builder: (ctx) {
        return ListView(
          children: others
              .map(
                (p) => ListTile(
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${p.position} • OVR ${p.overallRating}',
                      style: const TextStyle(color: Colors.white54)),
                  onTap: () => Navigator.pop(ctx, p),
                ),
              )
              .toList(),
        );
      },
    );
    if (picked == null) return;
    setState(() => _b = picked);
    _load();
  }

  Map<String, int> _skills(Map<String, dynamic>? side) {
    if (side == null) return {};
    final skills = side['skills'];
    if (skills is! Map) return {};
    int v(String k) {
      final raw = skills[k];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return 0;
    }

    return {
      'PAC': v('pac'),
      'SHO': v('sho'),
      'PAS': v('pas'),
      'DRI': v('dri'),
      'DEF': v('def'),
      'PHY': v('phy'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sideA = _data?['player_a'] as Map<String, dynamic>?;
    final sideB = _data?['player_b'] as Map<String, dynamic>?;
    final skillsA = _skills(sideA);
    final skillsB = _skills(sideB);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: const Text('Karsilastir'),
        backgroundColor: const Color(0xFF0B0F19),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _playerChip(_a.name, _green)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('VS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: InkWell(
                  onTap: _pickB,
                  child: _playerChip(_b?.name ?? 'Oyuncu sec', Colors.orangeAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading) const Center(child: CircularProgressIndicator(color: _green)),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          if (!_loading && _b != null && skillsA.isNotEmpty && skillsB.isNotEmpty) ...[
            SizedBox(
              height: 280,
              child: RadarChart(
                RadarChartData(
                  radarBackgroundColor: Colors.transparent,
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                  radarBorderData: const BorderSide(color: Colors.white24),
                  gridBorderData: const BorderSide(color: Colors.white12),
                  titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                  getTitle: (index, angle) {
                    const labels = ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'];
                    return RadarChartTitle(text: labels[index]);
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: _green.withValues(alpha: 0.25),
                      borderColor: _green,
                      entryRadius: 2,
                      dataEntries: ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY']
                          .map((k) => RadarEntry(value: (skillsA[k] ?? 0).toDouble()))
                          .toList(),
                    ),
                    RadarDataSet(
                      fillColor: Colors.orangeAccent.withValues(alpha: 0.2),
                      borderColor: Colors.orangeAccent,
                      entryRadius: 2,
                      dataEntries: ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY']
                          .map((k) => RadarEntry(value: (skillsB[k] ?? 0).toDouble()))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _metricTable(skillsA, skillsB),
          ],
        ],
      ),
    );
  }

  Widget _playerChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _metricTable(Map<String, int> a, Map<String, int> b) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'].map((k) {
          final va = a[k] ?? 0;
          final vb = b[k] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('$va', style: const TextStyle(color: _green, fontWeight: FontWeight.bold))),
                Expanded(child: Text(k, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
                SizedBox(width: 36, child: Text('$vb', textAlign: TextAlign.end, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

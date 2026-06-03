import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:yetenek_avcisi/app_services.dart';
import 'package:yetenek_avcisi/core/utils/fifa_six_stats.dart';
import 'package:yetenek_avcisi/services/multi_upload_service.dart';

const _card = Color(0xFF151C2B);
const _green = Color(0xFF00FF87);

class PlayerCompareScreen extends StatefulWidget {
  const PlayerCompareScreen({
    super.key,
    this.playerA,
    this.playerB,
    this.allPlayers = const [],
  });

  final PlayerListItem? playerA;
  final PlayerListItem? playerB;
  final List<PlayerListItem> allPlayers;

  @override
  State<PlayerCompareScreen> createState() => _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends State<PlayerCompareScreen> {
  PlayerListItem? _a;
  PlayerListItem? _b;
  Map<String, dynamic>? _data;
  bool _loading = false;
  bool _loadingCandidates = false;
  String? _error;
  List<PlayerListItem> _candidatePool = const [];
  Set<String> _mineKeys = const {};
  bool _onlyMineA = false;
  bool _onlyMineB = false;

  @override
  void initState() {
    super.initState();
    _a = widget.playerA;
    _b = widget.playerB;
    _candidatePool = List<PlayerListItem>.from(widget.allPlayers);
    _loadOwnAnalysesForCompare();
    if (_a != null && _b != null) _load();
  }

  bool get _isScout =>
      (currentUserNotifier.value?.role ?? '').trim().toLowerCase() == 'scout';

  String _playerKey(PlayerListItem p) => '${p.source}:${p.id}';
  bool _isSameAnalysis(PlayerListItem x, PlayerListItem y) =>
      _playerKey(x) == _playerKey(y);

  Future<void> _showSameAnalysisAlert(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Aynı analiz',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Karşılaştırmak için farklı bir analiz veya oyuncu seçin.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Tamam',
              style: TextStyle(
                color: _green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  DateTime _sortDate(PlayerListItem p) {
    final raw = p.updatedAt;
    if (raw == null || raw.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _fmtDate(PlayerListItem p) {
    final dt = _sortDate(p);
    if (dt.millisecondsSinceEpoch == 0) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  String _metaLine(PlayerListItem p) =>
      '${p.position} • AI OVR ${p.fifaCardOvr} • ${_fmtDate(p)}';

  Future<void> _loadOwnAnalysesForCompare() async {
    setState(() => _loadingCandidates = true);
    try {
      final mine = await MultiUploadService.listMyAnalyses();
      if (!mounted) return;
      final mapped = mine
          .where((p) => p.isComplete)
          .map(
            (p) => PlayerListItem.fromJson({
              'id': p.id,
              'user_id': p.userId,
              'name': p.name,
              'age': p.age,
              'position': p.position,
              'overall_rating': p.overallRating,
              'ai_scout_report': p.aiSummaryReport,
              'source': 'multivideo',
              'skill_scores': p.skillScores,
              'slot_breakdown': p.slotBreakdown,
              'analysis_version': p.analysisVersion,
              'pace': p.pace,
              'finishing': p.finishing,
              'passing': p.passing,
              'dribbling': p.dribbling,
              'defending': p.defending,
              'strength': p.strength,
              'physical_attributes': p.physicalAttributes,
              'updated_at': p.updatedAt,
            }),
          )
          .toList();

      final merged = <String, PlayerListItem>{};
      for (final p in [..._candidatePool, ...mapped]) {
        merged[_playerKey(p)] = p;
      }
      setState(() {
        _candidatePool = merged.values.toList();
        _mineKeys = mapped.map(_playerKey).toSet();
      });
    } catch (_) {
      // Compare ekranı, "kendi analizlerini ekleyemedik" hatasıyla bloklanmasın.
    } finally {
      if (mounted) setState(() => _loadingCandidates = false);
    }
  }

  Future<void> _load() async {
    if (_a == null || _b == null) return;
    if (_isSameAnalysis(_a!, _b!)) {
      if (mounted) await _showSameAnalysisAlert(context);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = {
        'player_a': _toCompareSide(_a!),
        'player_b': _toCompareSide(_b!),
      };
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _toCompareSide(PlayerListItem p) {
    final six = p.fifaSix;
    return {
      'id': p.id,
      'name': p.name,
      'position': p.position,
      'ovr': p.fifaCardOvr,
      'skills': {
        'pac': six.pace,
        'sho': six.finishing,
        'pas': six.passing,
        'dri': six.dribbling,
        'def': six.defending,
        'phy': six.strength,
      },
    };
  }

  bool _hasComparableSkills(Map<String, int?> skills) =>
      skills.values.any((v) => v != null && v > 0);

  Future<void> _pickFor({required bool sideA}) async {
    final anchor = sideA ? _b : _a;
    bool modalOnlyMine = sideA ? _onlyMineA : _onlyMineB;
    final positions = [
      'Tümü',
      ...{
        for (final p in _candidatePool)
          if (p.position.trim().isNotEmpty) p.position.trim(),
      },
    ];
    final picked = await showModalBottomSheet<PlayerListItem>(
      context: context,
      backgroundColor: const Color(0xFF101828),
      builder: (ctx) {
        String query = '';
        String selectedPosition = 'Tümü';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _candidatePool.where((p) {
              if (!_isScout &&
                  modalOnlyMine &&
                  !_mineKeys.contains(_playerKey(p))) {
                return false;
              }
              final byPosition = selectedPosition == 'Tümü' ||
                  p.position.trim() == selectedPosition;
              if (!byPosition) return false;
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  p.position.toLowerCase().contains(q);
            }).toList()
              ..sort((a, b) {
                final byDate = _sortDate(b).compareTo(_sortDate(a));
                if (byDate != 0) return byDate;
                return b.id.compareTo(a.id);
              });

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Oyuncu ara...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPosition,
                      dropdownColor: const Color(0xFF101828),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mevki',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: positions
                          .map(
                            (pos) => DropdownMenuItem<String>(
                              value: pos,
                              child: Text(pos),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(
                        () => selectedPosition = v ?? 'Tümü',
                      ),
                    ),
                    if (!_isScout) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilterChip(
                          selected: modalOnlyMine,
                          label: const Text('Sadece benim analizlerim'),
                          onSelected: (v) => setModalState(() {
                            modalOnlyMine = v;
                            if (sideA) {
                              _onlyMineA = v;
                            } else {
                              _onlyMineB = v;
                            }
                          }),
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          selectedColor: _green.withValues(alpha: 0.2),
                          checkmarkColor: _green,
                          labelStyle: TextStyle(
                            color: modalOnlyMine ? _green : Colors.white70,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: modalOnlyMine
                                ? _green.withValues(alpha: 0.45)
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Sonuç bulunamadı',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final p = filtered[i];
                                return ListTile(
                                  title: Text(
                                    p.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    _metaLine(p),
                                    style: const TextStyle(color: Colors.white54),
                                  ),
                                  trailing: !_isScout &&
                                          _mineKeys.contains(_playerKey(p))
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _green.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'Benim',
                                            style: TextStyle(
                                              color: _green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Genel',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                  onTap: () async {
                                    if (anchor != null &&
                                        _isSameAnalysis(p, anchor)) {
                                      await _showSameAnalysisAlert(ctx);
                                      return;
                                    }
                                    Navigator.pop(ctx, p);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (sideA) {
        _a = picked;
      } else {
        _b = picked;
      }
    });
    _load();
  }

  Map<String, int?> _skills(Map<String, dynamic>? side) {
    if (side == null) return {};
    final skills = side['skills'];
    if (skills is! Map) return {};
    int? v(String k) {
      final raw = skills[k];
      if (raw == null) return null;
      if (raw is int) return raw > 0 ? raw : null;
      if (raw is num) {
        final n = raw.toInt();
        return n > 0 ? n : null;
      }
      return null;
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
        title: const Text('Karşılaştır'),
        backgroundColor: const Color(0xFF0B0F19),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickFor(sideA: true),
                  child: _playerChip(
                    _a?.name ?? 'Oyuncu seç',
                    _a == null ? 'Mevki • AI OVR • Tarih' : _metaLine(_a!),
                    _green,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('VS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _pickFor(sideA: false),
                  child: _playerChip(
                    _b?.name ?? 'Oyuncu seç',
                    _b == null ? 'Mevki • AI OVR • Tarih' : _metaLine(_b!),
                    Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
          if (_loadingCandidates)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(color: _green, minHeight: 2),
            ),
          const SizedBox(height: 20),
          if (_loading) const Center(child: CircularProgressIndicator(color: _green)),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          if ((_a == null || _b == null) && !_loading)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                _a == null && _b == null
                    ? 'Karşılaştırmak için sol veya sağ taraftan bir analiz seçin.'
                    : 'Karşılaştırmak için ${_a == null ? 'sol' : 'sağ'} taraftan bir analiz seçin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                ),
              ),
            ),
          if (!_loading &&
              _a != null &&
              _b != null &&
              _hasComparableSkills(skillsA) &&
              _hasComparableSkills(skillsB)) ...[
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
          ] else if (!_loading && _a != null && _b != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _ovrOnlyCompareCard(sideA, sideB),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ovrOnlyCompareCard(
    Map<String, dynamic>? sideA,
    Map<String, dynamic>? sideB,
  ) {
    final ovrA = sideA?['ovr'];
    final ovrB = sideB?['ovr'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Text(
            'AI OVR',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '$ovrA',
                style: const TextStyle(
                  color: _green,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'vs',
                style: TextStyle(color: Colors.white38),
              ),
              Text(
                '$ovrB',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Alt beceri verisi bu kayıtlar için henüz yok; yalnızca OVR karşılaştırıldı.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _playerChip(String label, String meta, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _metricTable(Map<String, int?> a, Map<String, int?> b) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'].map((k) {
          final va = a[k];
          final vb = b[k];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    va != null ? '$va' : '–',
                    style: TextStyle(
                      color: va != null ? _green : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Text(k, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
                SizedBox(
                  width: 36,
                  child: Text(
                    vb != null ? '$vb' : '–',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: vb != null ? Colors.orangeAccent : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

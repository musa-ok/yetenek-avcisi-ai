import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/multi_upload_service.dart';

/// AI raporu + topluluk puanı + scout notlarından birleşik özet.
class SmartSummaryCard extends StatefulWidget {
  const SmartSummaryCard({super.key, required this.playerId});

  final int playerId;

  @override
  State<SmartSummaryCard> createState() => _SmartSummaryCardState();
}

class _SmartSummaryCardState extends State<SmartSummaryCard> {
  SmartSummaryData? _data;
  bool _loading = true;
  String? _error;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await MultiUploadService.fetchSmartSummary(widget.playerId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String? _aiReportBody() {
    final sections = _data?.sections ?? [];
    for (final s in sections) {
      if (s.title == 'AI Analiz' && s.body.trim().isNotEmpty && s.body != '—') {
        return s.body.trim();
      }
    }
    return null;
  }

  List<({String title, String body})> _visibleSections() {
    return (_data?.sections ?? []).where((s) {
      return s.body.trim().isNotEmpty && s.body != '—';
    }).toList();
  }

  List<Widget> _buildExpandedSections() {
    return [
      for (final s in _visibleSections()) ...[
        const SizedBox(height: 12),
        Text(
          s.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.body,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Akıllı Özet',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (!_loading && _error == null && (_data?.sections.isNotEmpty ?? false))
                IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null)
            Text(
              'Özet yüklenemedi',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          else if (_data != null) ...[
            if (_data!.headline.isNotEmpty)
              Text(
                _data!.headline,
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (!_expanded) ...[
              const SizedBox(height: 8),
              Text(
                _data!.summary.length > 220
                    ? '${_data!.summary.substring(0, 220)}…'
                    : _data!.summary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              if (_aiReportBody() != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tam AI raporu için genişlet',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            if (_expanded) ..._buildExpandedSections(),
          ],
        ],
      ),
    );
  }
}

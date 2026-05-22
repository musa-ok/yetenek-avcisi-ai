import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../app_theme.dart';
import '../services/multi_upload_service.dart';
import 'fullscreen_multi_video_player.dart'; 

class PlayerStatsScreen extends StatefulWidget {
  final MultiVideoPlayer player;
  final VoidCallback? onAnalysisComplete;

  const PlayerStatsScreen({
    super.key,
    required this.player,
    this.onAnalysisComplete,
  });

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final GlobalKey _fifaCardKey = GlobalKey();
  bool _isSharing = false;
  bool _isAnalyzing = false;

  Future<void> _startAnalysis() async {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    try {
      // Backend'e analiz isteği gönder
      final result = await MultiUploadService.finalizePlayer(
        widget.player.id,
        forceAnalysis: true, // Kullanıcı manuel olarak istediği için
      );

      if (mounted) {
        // Analiz sonuçlarına git
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerStatsScreen(
              player: result,
              onAnalysisComplete: widget.onAnalysisComplete,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz başlatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStartAnalysisButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'AI Analizi',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Yüklediğiniz 3 video için AI scout analizi başlatmak için tıklayın.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _startAnalysis,
              icon: _isAnalyzing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.play_arrow),
              label: Text(_isAnalyzing ? 'Analiz Ediliyor...' : 'Analizi Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFifaCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    
    final Size screen = MediaQuery.of(this.context).size;
    final Rect origin = Rect.fromLTWH(screen.width - 60, 60, 44, 44);
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(this.context);

    try {
      final ctx = _fifaCardKey.currentContext;
      if (ctx == null) throw Exception('FIFA kartı hazır değil');
      final renderObject = ctx.findRenderObject() as RenderRepaintBoundary;
      await WidgetsBinding.instance.endOfFrame;

      final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/fifa_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '🎮 ${widget.player.name} - Puan: ${widget.player.overallRating}/100\nYetenek Avcısı ile analiz edildi!',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text('Paylaşım hatası: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[PlayerStats] ==========================================');
    debugPrint('[PlayerStats] BUILD START: player.id=${widget.player.id} name=${widget.player.name}');
    debugPrint('[PlayerStats] ALL FIELDS: pace=${widget.player.pace} finishing=${widget.player.finishing} passing=${widget.player.passing}');
    debugPrint('[PlayerStats] ALL FIELDS: dribbling=${widget.player.dribbling} defending=${widget.player.defending} strength=${widget.player.strength}');
    debugPrint('[PlayerStats] skillScores=${widget.player.skillScores}');
    debugPrint('[PlayerStats] ==========================================');
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            widget.onAnalysisComplete?.call();
            Navigator.of(context).pop();
          },
        ),
        title: Text('Yetenek Analizi', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSharing 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: _isSharing ? null : _shareFifaCard,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              RepaintBoundary(
                key: _fifaCardKey,
                child: _buildFifaCard(context),
              ),
              
              SizedBox(height: 24),
              _buildPlayVideosButton(context),
              
              SizedBox(height: 24),
              _buildVideoAnalysis(context),
              
              SizedBox(height: 32),
              if (widget.player.aiSummaryReport != null)
                _buildAIReport(context)
              else
                _buildStartAnalysisButton(context),
              
              SizedBox(height: 32),
              _buildStrengthsAndImprovements(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayVideosButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final List<String> videoUrls = widget.player.videos
            .where((v) => v.url != null && v.url!.isNotEmpty)
            .map((v) => v.url!)
            .toList();

        if (videoUrls.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullscreenMultiVideoPlayer(
                videoUrls: videoUrls,
                playerName: widget.player.name,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Oynatılacak video bulunamadı.')),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [AppColors.accentGreen, AppColors.accentBlue],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
            SizedBox(width: 12),
            Text(
              "3 YETENEK VİDEOSUNU İZLE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().shimmer(delay: 1.seconds, duration: 2.seconds);
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Color(0xFF4CAF50);
    if (score >= 60) return Color(0xFFFF9800);
    return Color(0xFFEF5350);
  }

  Widget _buildFifaCard(BuildContext context) {
    final overallScore = widget.player.overallRating;
    final bool hasAnalysis = widget.player.aiSummaryReport != null && 
                             widget.player.aiSummaryReport!.isNotEmpty;
    final cardColor = hasAnalysis ? _getScoreColor(overallScore) : Colors.grey;
    
    debugPrint('[PlayerStats] RAW: pace=${widget.player.pace}(${widget.player.pace?.runtimeType}) finishing=${widget.player.finishing}(${widget.player.finishing?.runtimeType})');
    debugPrint('[PlayerStats] skill_scores=${widget.player.skillScores}');
    
    final skills = [
      {'name': 'HIZ', 'value': widget.player.pace, 'icon': Icons.speed},
      {'name': 'ŞUT', 'value': widget.player.finishing, 'icon': Icons.sports_soccer},
      {'name': 'PAS', 'value': widget.player.passing, 'icon': Icons.swap_horiz},
      {'name': 'DRİBLİNG', 'value': widget.player.dribbling, 'icon': Icons.control_camera},
      {'name': 'DEFANS', 'value': widget.player.defending, 'icon': Icons.shield},
      {'name': 'FİZİK', 'value': widget.player.strength, 'icon': Icons.fitness_center},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardBadge(widget.player.position.substring(0,1).toUpperCase(), widget.player.position),
                _buildOverallCircle(overallScore, cardColor),
                _buildCardBadge('${widget.player.age}', 'YAŞ'),
              ],
            ),
            SizedBox(height: 20),
            Text(widget.player.name.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
            SizedBox(height: 24),
            SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.3, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: 6,
              itemBuilder: (context, index) {
                final s = skills[index];
                final val = s['value'] as int?;
                final color = val != null ? _getScoreColor(val) : Colors.grey;
                return Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(s['icon'] as IconData, color: color, size: 20),
                      Text(val != null ? '$val' : '-', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(s['name'] as String, style: TextStyle(color: Colors.white60, fontSize: 9)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBadge(String label, String subLabel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        Text(subLabel, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ]),
    );
  }

  Widget _buildOverallCircle(int score, Color color) {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 36)),
        Text('GENEL', style: TextStyle(color: Colors.white70, fontSize: 9)),
      ])),
    );
  }

  Widget _buildVideoAnalysis(BuildContext context) {
    final uploadedVideos = widget.player.videos.where((v) => v.isUploaded).toList();
    final allUrls = uploadedVideos
        .where((v) => v.url != null && v.url!.isNotEmpty)
        .map((v) => v.url!)
        .toList();

    void openFullscreen() {
      if (allUrls.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullscreenMultiVideoPlayer(
            videoUrls: allUrls,
            playerName: widget.player.name,
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Detaylı Yetenek Skorları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      SizedBox(height: 12),
      ...uploadedVideos.map((video) {
        final score = _scoreForVideo(video);
        return GestureDetector(
          onTap: openFullscreen,
          child: _buildVideoProgressCard(video.skill ?? 'Yetenek', score, _getScoreColor(score)),
        );
      }).toList(),
    ]);
  }

  int _scoreForVideo(VideoInfo video) {
    final skill = (video.skill ?? '').toLowerCase();
    if (skill.contains('şut') || skill.contains('bitir')) return widget.player.finishing ?? 0;
    if (skill.contains('dripl') || skill.contains('top')) return widget.player.dribbling ?? 0;
    if (skill.contains('hız') || skill.contains('sürat')) return widget.player.pace ?? 0;
    if (skill.contains('pas')) return widget.player.passing ?? 0;
    if (skill.contains('defans')) return widget.player.defending ?? 0;
    if (skill.contains('fizik') || skill.contains('güç')) return widget.player.strength ?? 0;
    return widget.player.overallRating;
  }

  Widget _buildVideoProgressCard(String title, int score, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      // 🚨 BURASI DÜZELTİLDİ: Colors.black24 yerine Colors.black.withOpacity(0.24)
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.24), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 8),
          LinearProgressIndicator(value: score/100, color: color, backgroundColor: Colors.white10),
        ])),
        SizedBox(width: 12),
        Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(width: 8),
        Icon(Icons.play_circle_outline, color: Color(0xFF00E676), size: 18),
      ]),
    );
  }

  Widget _buildAIReport(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      // 🚨 BURASI DÜZELTİLDİ: Colors.black24 yerine Colors.black.withOpacity(0.24)
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.24), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppColors.accentPurple.withOpacity(0.3))
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.psychology, color: AppColors.accentPurple), SizedBox(width: 8), Text('AI Scout Analizi', style: TextStyle(color: AppColors.accentPurple, fontWeight: FontWeight.bold))]),
        SizedBox(height: 12),
        Text(widget.player.aiSummaryReport!, style: TextStyle(height: 1.5, fontSize: 13, color: Colors.white)),
      ]),
    );
  }

  Widget _buildStrengthsAndImprovements(BuildContext context) {
    return Row(children: [
      _buildTagCard('Güçlü Yönler', widget.player.aiStrengths, AppColors.success, Icons.trending_up),
      SizedBox(width: 10),
      _buildTagCard('Gelişim', widget.player.aiImprovements, AppColors.accentOrange, Icons.trending_flat),
    ]);
  }

  Widget _buildTagCard(String title, List<String> items, Color color, IconData icon) {
    return Expanded(child: GestureDetector(
      onTap: () => _showDetailDialog(title, items, color, icon),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: color, size: 16), SizedBox(width: 4), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))]),
          SizedBox(height: 8),
          ...items.take(2).map((e) => Text('• $e', style: TextStyle(fontSize: 11, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)).toList(),
          if (items.length > 2) ...[
            SizedBox(height: 4),
            Text('Tümünü gör →', style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
          ],
        ]),
      ),
    ));
  }

  void _showDetailDialog(String title, List<String> items, Color color, IconData icon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: items.isEmpty
            ? Text('Veri bulunamadı.', style: TextStyle(color: Colors.white70))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: items.map((e) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $e', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                  )).toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Kapat', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../app_services.dart';
import '../core/settings/app_settings.dart';
import '../services/multi_upload_service.dart';
import '../widgets/analysis_finalize_dialog.dart';
import '../main.dart' show latestAnalysisNotifier, AnalysisResult, playersRefreshNotifier, kPitchGreen;
import 'player_stats_screen.dart';
import 'privacy_policy_screen.dart';

/// ==========================================
/// MULTI-UPLOAD SCREEN
/// Glassmorphism + Dark Mode
/// ==========================================

class MultiUploadScreen extends StatefulWidget {
  final bool forceNew;
  const MultiUploadScreen({super.key, this.forceNew = false});

  @override
  State<MultiUploadScreen> createState() => _MultiUploadScreenState();
}

class _MultiUploadScreenState extends State<MultiUploadScreen> {
  // Mevki seçimi
  String selectedPosition = 'Forvet';
  final List<String> positions = [
    'Kaleci',
    'Defans',
    'Orta Saha',
    'Kanat',
    'Forvet',
  ];
  
  // Slot yetenek seçimleri (slot -> skill)
  Map<int, String> slotSkills = {};

  // Kullanıcı bilgileri auth'dan otomatik çekilecek
  // Artık manuel isim/doğum tarihi girişi yok
  
  // State
  List<PositionSkill> skills = [];
  MultiVideoPlayer? player;
  bool isLoading = false;
  bool isCreatingPlayer = false;
  bool isAnalyzing = false; // AI analizi süreci kilitliyor
  int currentUploadingSlot = 0;

  void _showAppSnack(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    final bg = backgroundColor ?? AppColors.surface;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (bg == AppColors.success || bg == AppColors.accentGreen) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBars.success(message, duration: duration),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBars.custom(
        message,
        backgroundColor: bg,
        duration: duration,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Yeni analiz istendiyse slotları hemen sıfırla (setState olmadan)
    if (widget.forceNew) {
      player = null;
      selectedPosition = 'Forvet';
      currentUploadingSlot = 0;
      isAnalyzing = false;
      isCreatingPlayer = false;
      isLoading = false;
      slotSkills = {};
      skills = [];
    }
    // Sadece skills boşsa yükle
    if (skills.isEmpty) {
      _loadPositionSkills();
    }
  }

  Future<void> _loadPositionSkills() async {
    setState(() => isLoading = true);
    try {
      final loadedSkills = await MultiUploadService.getPositionSkills(selectedPosition);
      setState(() => skills = loadedSkills);
    } catch (e) {
      _showAppSnack('Yetenekler yüklenemedi: $e', backgroundColor: AppColors.error);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _showKosuFilmingGuide({required String phase}) async {
    final isFlat = phase == 'flat';
    final title = isFlat ? '20 metre düz koşu' : '10 metre yokuş koşu';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sürenin ölçülebilmesi için:',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _kosuTip('📱 Telefon sabit (tripod / yere dayalı)'),
              _kosuTip('↔️ Yan çekim — oyuncu yatay geçsin'),
              _kosuTip('🟠 Başlangıç ve bitişte koni veya çizgi görünsün'),
              _kosuTip('🏃 Koşu öncesi/sonrası 1 sn boşluk bırakın'),
              if (isFlat)
                _kosuTip('📏 Mümkünse 20 m mesafe tek kadrajda'),
              const SizedBox(height: 8),
              Text(
                'Çizgi yoksa ölçüm zayıflar veya reddedilir.',
                style: TextStyle(color: AppColors.warning.withValues(alpha: 0.9), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: AppColors.onAccentGreen,
            ),
            child: const Text('Anladım, devam', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _kosuTip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.textSecondary, height: 1.35)),
      );

  void _showKosuQualityFeedback(BuildContext context, Map<String, dynamic> q) {
    final quality = '${q['quality'] ?? ''}';
    final tips = (q['tips'] as List?)?.map((e) => '$e').toList() ?? [];
    final color = quality == 'good'
        ? AppColors.success
        : quality == 'warn'
            ? AppColors.warning
            : AppColors.accentBlue;

    final String msg;
    if (quality == 'good') {
      msg = 'Video kabul edildi. Çekim koşulları uygun görünüyor.';
    } else if (quality == 'warn') {
      msg = tips.isNotEmpty
          ? 'Video kabul edildi. ${tips.first}'
          : 'Video kabul edildi. Daha net çizgi/koni ile tekrar çekmeniz ölçümü iyileştirir.';
    } else {
      msg = tips.isNotEmpty
          ? tips.first
          : 'Video kabul edilmedi. Lütfen çekimi iyileştirip tekrar deneyin.';
    }

    _showAppSnack(
      msg,
      backgroundColor: color,
      duration: Duration(seconds: quality == 'good' ? 3 : 5),
    );
  }

  String _kosuUploadErrorMessage(Object e) {
    var raw = '$e'.replaceFirst('Exception: ', '').trim();
    final detailIdx = raw.indexOf('detail:');
    if (detailIdx >= 0) {
      raw = raw.substring(detailIdx + 7).trim();
    }
    if (raw.contains('Video kabul edilmedi')) {
      return raw;
    }
    if (raw.toLowerCase().contains('uyumsuz video')) {
      return raw;
    }
    if (raw.toLowerCase().contains('ölçülen süre') ||
        raw.contains('beklenen aralık') ||
        RegExp(r'\d+[,.]?\d*\s*s').hasMatch(raw)) {
      return 'Video kabul edilmedi. Başlangıç ve bitiş çizgileri kadrajda görünsün, '
          'telefon sabit olsun ve koşunun tamamı tek videoda kalsın.';
    }
    return raw.isEmpty
        ? 'Video yüklenemedi. Lütfen tekrar deneyin.'
        : 'Video yüklenemedi: $raw';
  }

  /// Video kaynağı seçimi (Kamera veya Galeri)
  Future<ImageSource?> _showVideoSourceSelector() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(
                'Video Seç',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Video çekmek veya galeriden seçmek için',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Kamera ile Çek
              _buildSourceButton(
                icon: Icons.videocam,
                title: 'Kamera ile Çek',
                subtitle: 'Yeni video kaydet',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              
              const SizedBox(height: 12),
              
              // Galeriden Seç
              _buildSourceButton(
                icon: Icons.photo_library,
                title: 'Galeriden Seç',
                subtitle: 'Mevcut video seç',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              
              const SizedBox(height: 16),
              
              // İptal
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'İptal',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAiConsentAndCreate() async {
    final consent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Yapay Zeka Analiz Onayı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yüklediğiniz videolar ve profil verileriniz, yetenek analizi yapılabilmesi için güvenli bir şekilde yapay zeka iş ortaklarımızla paylaşılacaktır. Bu işleme izin veriyor musunuz?',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
              child: const Text(
                'Gizlilik Politikasını görüntüle →',
                style: TextStyle(
                  color: kPitchGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPitchGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Kabul Et', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (consent == true) {
      _createPlayer();
    }
  }

  Future<void> _createPlayer() async {
    final user = currentUserNotifier.value;
    final token = currentAccessTokenNotifier.value;
    
    if (user == null || token == null) {
      _showAppSnack('Lütfen önce giriş yapın', backgroundColor: AppColors.error);
      return;
    }

    // 🚨 STATE SIFIRLAMA - Yeni başlangıç için tüm verileri temizle
    setState(() {
      isCreatingPlayer = true;
      player = null;
      slotSkills = {};
      currentUploadingSlot = 0;
      isAnalyzing = false;
    });
    
    try {
      // Kullanıcı bilgileri Bearer token'dan otomatik çekiliyor
      // Sadece mevki gönderiliyor, isim/yaş token'dan alınıyor
      final newPlayer = await MultiUploadService.createPlayerFromAuth(
        position: selectedPosition,
        accessToken: token,
      );

      // 🚨 GELEN VERİ KONTROLÜ - Eğer backend eski dolu player döndürürse temizle
      if (newPlayer.videos.any((v) => v.isUploaded)) {
        debugPrint('[WARNING] Backend dolu player döndürdü, temizleniyor...');
        // Yeni boş player oluştur
        final cleanPlayer = MultiVideoPlayer(
          id: newPlayer.id,
          userId: newPlayer.userId,
          name: newPlayer.name,
          birthDate: newPlayer.birthDate,
          age: newPlayer.age,
          position: newPlayer.position,
          positionCode: newPlayer.positionCode,
          overallRating: 0,
          averageRating: 0.0,
          completionPercentage: 0.0,
          isComplete: false,
          videos: [], // BOŞ video listesi
          skillScores: {},
          aiStrengths: [],
          aiImprovements: [],
        );
        setState(() => player = cleanPlayer);
      } else {
        setState(() => player = newPlayer);
      }

      _showAppSnack(
        '${newPlayer.name} için ${newPlayer.requiredVideoCount} video yüklemeye başlayın',
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _showAppSnack('Hata: $e', backgroundColor: AppColors.error);
    } finally {
      setState(() => isCreatingPlayer = false);
    }
  }

  VideoInfo? _videoForSlot(int slot) {
    if (player == null) return null;
    for (final v in player!.videos) {
      if (v.slot == slot) return v;
    }
    return VideoInfo(slot: slot);
  }

  bool _slotFullyUploaded(PositionSkill skill) {
    final v = _videoForSlot(skill.slot);
    return v?.isUploaded ?? false;
  }

  int get _completedUploads {
    if (player == null) return 0;
    var n = 0;
    for (final s in skills) {
      final v = _videoForSlot(s.slot);
      if (s.isKosuSlot) {
        if (v?.kosuFlatUploaded == true) n++;
        if (v?.kosuUphillUploaded == true) n++;
      } else if (v?.isUploaded == true) {
        n++;
      }
    }
    return n;
  }

  int get _requiredVideoCount {
    if (player != null && player!.requiredVideoCount > 0) {
      return player!.requiredVideoCount;
    }
    var n = 0;
    for (final s in skills) {
      n += s.isKosuSlot ? 2 : 1;
    }
    return n > 0 ? n : 3;
  }

  bool _isSlotActive(int slot) {
    if (skills.isEmpty) return slot == 1;
    final ordered = [...skills]..sort((a, b) => a.slot.compareTo(b.slot));
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].slot == slot) {
        if (i == 0) return true;
        for (var j = 0; j < i; j++) {
          if (!_slotFullyUploaded(ordered[j])) return false;
        }
        return !_slotFullyUploaded(ordered[i]);
      }
    }
    return false;
  }

  /// Tüm slot durumlarını sıfırla - yeni analiz için
  void _resetAllSlots() {
    setState(() {
      // Player'ı null yap - yeni başlangıç
      player = null;
      selectedPosition = 'Forvet'; // Varsayılan pozisyon
      currentUploadingSlot = 0;
      isAnalyzing = false;
      slotSkills = {};
    });
    debugPrint('[MultiUpload] All slots reset - ready for new analysis');
  }

  /// Ayarlar → mobil veri izni + gerçek bağlantı tipi (connectivity_plus).
  Future<bool> _ensureUploadAllowedOnNetwork() async {
    final allowed = await AppSettings.canUploadVideoOnCurrentNetwork();
    if (allowed || !mounted) return allowed;

    _showAppSnack(
      'Mobil veride yüklemek için Ayarlar\'dan izin ver veya Wi-Fi\'ye bağlan.',
      backgroundColor: AppColors.warning,
      duration: const Duration(seconds: 4),
    );
    return false;
  }

  Future<void> _uploadKosuVideos(int slot, PositionSkill skill) async {
    if (!_isSlotActive(slot)) {
      _showAppSnack(
        'Önce önceki videoyu tamamlayın',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    final v = _videoForSlot(slot);
    final needFlat = v?.kosuFlatUploaded != true;
    final phase = needFlat ? 'flat' : 'uphill';
    final stepLabel = needFlat
        ? '20 metre düz koşu'
        : '10 metre yokuş yukarı koşu';

    final proceed = await _showKosuFilmingGuide(phase: phase);
    if (!proceed) return;

    final source = await _showVideoSourceSelector();
    if (source == null) return;

    final picker = ImagePicker();
    final pickedVideo = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );
    if (pickedVideo == null) return;

    if (!await _ensureUploadAllowedOnNetwork()) return;

    if (!mounted) return;
    setState(() => currentUploadingSlot = slot);

    try {
      final body = await MultiUploadService.uploadKosuToSlotRaw(
        playerId: player!.id,
        slot: slot,
        phase: phase,
        skillName: skill.name,
        videoFile: File(pickedVideo.path),
      );
      if (!mounted) return;
      final updated = MultiVideoPlayer.fromJson(body['player'] as Map<String, dynamic>);
      setState(() => player = updated);

      final q = MultiUploadService.parseKosuQualityFromUploadResponse(body);
      if (q != null) _showKosuQualityFeedback(context, q);

      final after = _videoForSlot(slot);
      if (after?.kosuFlatUploaded == true && after?.kosuUphillUploaded != true) {
        _showAppSnack(
          '20m düz koşu tamam. Şimdi 10 metre yokuş yukarı koşuyu yükleyin.',
          backgroundColor: AppColors.accentBlue,
          duration: const Duration(seconds: 4),
        );
      }

      if (updated.isComplete) {
        await _finalizePlayer();
      }
    } catch (e) {
      if (!mounted) return;
      final err = _kosuUploadErrorMessage(e);
      _showAppSnack(
        err,
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) setState(() => currentUploadingSlot = 0);
    }
  }

  Future<void> _uploadVideo(int slot, PositionSkill skill) async {
    if (skill.isKosuSlot) {
      await _uploadKosuVideos(slot, skill);
      return;
    }

    if (!_isSlotActive(slot)) {
      _showAppSnack(
        'Önce önceki videoyu tamamlayın',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    // Video kaynağı seçimi: Kamera veya Galeri
    final ImageSource? source = await _showVideoSourceSelector();
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? pickedVideo = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30), // Max 30 saniye
    );

    if (pickedVideo == null) return;

    if (!await _ensureUploadAllowedOnNetwork()) return;

    if (!mounted) return;  // 🛡️ Güvenlik: Sayfa kapandıysa dur
    setState(() => currentUploadingSlot = slot);

    try {
      final updatedPlayer = await MultiUploadService.uploadVideoToSlot(
        playerId: player!.id,
        slot: slot,
        skillName: skill.name,
        videoFile: File(pickedVideo.path),
      );

      if (!mounted) return;  // 🛡️ Güvenlik: Upload sırasında sayfa kapandıysa dur
      setState(() => player = updatedPlayer);

      // Bir sonraki slot açıldı bildirimi
      if (!mounted) return;  // 🛡️ Güvenlik kontrolü
      if (slot < _requiredVideoCount && !updatedPlayer.isComplete) {
        final nextSkill = skills[slot]; // slot 1 → index 0
        _showAppSnack(
          'Sıradaki: ${nextSkill.name} videosunu yükleyin',
          backgroundColor: AppColors.accentBlue,
        );
      }

      // Tamamlandı mı kontrol et
      if (!mounted) return;  // 🛡️ Güvenlik kontrolü
      if (updatedPlayer.isComplete) {
        await _finalizePlayer();
      }
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().replaceFirst('Exception: ', '');
      final isMismatch = err.toLowerCase().contains('uyumsuz video');
      _showAppSnack(
        isMismatch ? err : 'Video yüklenemedi: $err',
        backgroundColor: AppColors.error,
        duration: Duration(seconds: isMismatch ? 6 : 4),
      );
    } finally {
      if (!mounted) return;  // 🛡️ Güvenlik: Finally'da da kontrol
      setState(() => currentUploadingSlot = 0);
    }
  }

  Future<void> _finalizePlayer() async {
    // Otomatik analiz ayarını kontrol et
    final prefs = await SharedPreferences.getInstance();
    final autoAnalyzeEnabled = prefs.getBool('settings_auto_analyze_enabled') ?? true;
    
    if (!autoAnalyzeEnabled) {
      // Otomatik analiz kapalı - kullanıcıya sor
      if (!mounted) return;
      final shouldAnalyze = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Video Analizi', style: TextStyle(color: Colors.white)),
          content: Text(
            '$_requiredVideoCount video tamamlandı. AI analizi başlatılsın mı?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Sonra', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPitchGreen,
                foregroundColor: Colors.black,
              ),
              child: const Text('Analiz Başlat'),
            ),
          ],
        ),
      );
      
      if (shouldAnalyze != true) {
        // Kullanıcı istemiyor - videoları kaydet, slotları sıfırla, yeni başlangıç hazırla
        if (!mounted) return;
        
        // Slot durumlarını sıfırla - yeni analiz için hazır
        _resetAllSlots();
        
        setState(() => isAnalyzing = false);
        _showAppSnack(
          'Videolar kaydedildi. Analiz istatistiklerden başlatılabilir.',
          backgroundColor: AppColors.accentBlue,
        );
        return;
      }
    }
    
    // Tüm butonları kilitle
    if (!mounted) return;  // 🛡️ Güvenlik kontrolü
    setState(() => isAnalyzing = true);

    try {
      // AI analizi yap (Gemini 1-3 dk sürebilir)
      final result = await MultiUploadService.finalizePlayer(player!.id);
      final finalizedPlayer = result.player;

      if (!mounted) return;
      if (!result.success) {
        setState(() => isAnalyzing = false);
        await showAnalysisFinalizeDialog(
          context: context,
          result: result,
          onRetry: _finalizePlayer,
          onAnalysisComplete: _refreshDashboardData,
        );
        return;
      }

      setState(() {
        player = finalizedPlayer;
        isAnalyzing = false;
      });

      // Ana sayfadaki "Benim İstatistiklerim" listesinin güncel skorları
      // göstermesi için global notifier'ı set et.
      latestAnalysisNotifier.value = AnalysisResult(
        overall: finalizedPlayer.overallRating,
        pace: finalizedPlayer.pace,
        finishing: finalizedPlayer.finishing,
        passing: finalizedPlayer.passing,
        dribbling: finalizedPlayer.dribbling,
        defending: finalizedPlayer.defending,
        physical: finalizedPlayer.strength,
        report: finalizedPlayer.aiSummaryReport ?? '',
      );

      // 'Keşfet' ekranı ve Ana Sayfa oyuncu listesine yeni analizin
      // yansıması için global yenileme sinyali at.
      playersRefreshNotifier.value = playersRefreshNotifier.value + 1;

      if (!mounted) return;

      // Analiz sonuçlarına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerStatsScreen(
            player: finalizedPlayer,
            onAnalysisComplete: _refreshDashboardData,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;  // 🛡️ Güvenlik kontrolü
      setState(() => isAnalyzing = false);

      if (!mounted) return;  // 🛡️ Ekstra güvenlik
      _showAppSnack(
        'Analiz tamamlanamadı: $e',
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Widget _buildAnalyzingOverlay() {
    // Material wrapper zorunlu — yoksa Text widget'ları sarı altı çizili render eder
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            // Parlama yok — premium dark
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dönen AI ikonı
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                        backgroundColor: AppColors.accentGreen.withValues(alpha: 0.1),
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology, color: AppColors.accentGreen, size: 28),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1800.ms, color: AppColors.accentGreen.withValues(alpha: 0.3)),

              SizedBox(height: 28),

              Text(
                'Yapay Zeka Tüm Videolarınızı\nAnaliz Ediyor...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 12),

              Text(
                'Bu işlem 1-2 dakika sürebilir.\nLütfen uygulamayı kapatmayın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 24),

              LinearProgressIndicator(
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),

              SizedBox(height: 16),

              // Adım göstergeleri
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStep('Video 1', true),
                  _buildStepLine(),
                  _buildStep('Video 2', true),
                  _buildStepLine(),
                  _buildStep('Video 3', true),
                  _buildStepLine(),
                  _buildStep('AI Rapor', false),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStep(String label, bool done) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: done ? AppColors.accentGreen : Colors.white12,
            shape: BoxShape.circle,
          ),
          child: done
              ? Icon(Icons.check, color: Colors.black, size: 13)
              : SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.accentGreen)),
                ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 16,
      height: 2,
      margin: EdgeInsets.only(bottom: 14, left: 2, right: 2),
      color: AppColors.accentGreen.withValues(alpha: 0.3),
    );
  }

  void _refreshDashboardData() {
    // Ana sayfa verilerini yenile
    // Bu fonksiyon PlayerStatsScreen'den çağrılacak
    print('[REFRESH] Dashboard verileri yenileniyor...');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'Yetenek Videoları',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Text(
                    '3 Yetenek Videosu',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideX(),

                  SizedBox(height: 8),

                  Text(
                    'Her mevki için 3 farklı yeteneğinizi gösteren kısa videolar yükleyin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                  SizedBox(height: 32),

                  // Mevki Seçimi
                  if (player == null) ...[
                    _buildPositionSelector().animate().fadeIn(delay: 300.ms),

                    SizedBox(height: 32),

                    // Kullanıcı bilgisi (okunabilir)
                    _buildUserInfoCard().animate().fadeIn(delay: 400.ms),

                    SizedBox(height: 32),

                    // Başlat Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isCreatingPlayer ? null : _showAiConsentAndCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: const Color(0xFF0B0F19),
                          disabledBackgroundColor: AppColors.textMuted,
                          disabledForegroundColor: Colors.white54,
                        ),
                        child: isCreatingPlayer
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.scaffoldBackground,
                                ),
                              )
                            : Text(
                                skills.isEmpty
                                    ? 'Başla ve Video Yükle'
                                    : 'Başla ve ${skills.length} Video Yükle',
                              ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ] else ...[
                    // İlerleme
                    _buildProgressHeader(),

                    SizedBox(height: 24),

                    if (skills.isNotEmpty) ...[
                      for (var i = 0; i < skills.length; i++) ...[
                        if (i > 0) SizedBox(height: 16),
                        _buildVideoSlot(skills[i].slot, skills[i]),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        // AI analizi sırasında tüm ekranı kapla - dokunuşları engelle
        if (isAnalyzing) _buildAnalyzingOverlay(),
      ],
    ),
    );
  }

  Widget _buildPositionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mevki Seçin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: positions.map((position) {
            final isSelected = position == selectedPosition;
            return GestureDetector(
              onTap: () {
                setState(() => selectedPosition = position);
                _loadPositionSkills();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.accentGreen.withValues(alpha: 0.3),
                            AppColors.accentGreen.withValues(alpha: 0.1),
                          ],
                        )
                      : null,
                  color: isSelected ? null : AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentGreen
                        : AppColors.glassBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  position,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Kullanıcı bilgisi kartı - Auth'dan otomatik çekilir
  Widget _buildUserInfoCard() {
    final user = currentUserNotifier.value;
    
    return GlassmorphismContainer(
      padding: EdgeInsets.all(20),
      backgroundColor: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Yüklenecek Profil',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentGreen.withValues(alpha: 0.3),
                      AppColors.accentGreen.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (user?.fullName ?? '?').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Misafir',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Bilgileriniz profilinizden otomatik çekilecek',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = player?.completionPercentage ?? 0;
    
    return GlassmorphismContainer(
      padding: EdgeInsets.all(20),
      backgroundColor: AppColors.cardBackground,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  player?.position ?? selectedPosition,
                  style: TextStyle(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              Text(
                '${player?.name ?? ''}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          LinearPercentIndicator(
            lineHeight: 12,
            percent: progress / 100,
            backgroundColor: AppColors.glassWhite,
            progressColor: AppColors.accentGreen,
            barRadius: Radius.circular(6),
            animation: true,
            animationDuration: 1000,
          ),
          SizedBox(height: 12),
          Text(
            '$_completedUploads/$_requiredVideoCount Video Yüklendi',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSlot(int slot, PositionSkill skill) {
    final videoInfo = _videoForSlot(slot);
    final isUploaded = videoInfo?.isUploaded ?? false;
    final kosuFlat = videoInfo?.kosuFlatUploaded ?? false;
    final kosuUphill = videoInfo?.kosuUphillUploaded ?? false;
    final isUploading = currentUploadingSlot == slot;
    final isActive = _isSlotActive(slot);
    final isLocked = !isActive && !isUploaded;

    final kosuBusy = skill.isKosuSlot && isUploading;
    final kosuDone = skill.isKosuSlot && isUploaded;

    return GestureDetector(
      onTap: (isUploaded && !skill.isKosuSlot) || kosuBusy || (isLocked && !skill.isKosuSlot) || isAnalyzing
          ? null
          : () => _uploadVideo(slot, skill),
      child: GlassmorphismContainer(
        padding: EdgeInsets.all(20),
        backgroundColor: AppColors.cardBackground,
        borderColor: isUploaded
            ? AppColors.success.withValues(alpha: 0.5)
            : isLocked
                ? AppColors.textMuted.withValues(alpha: 0.3)
                : AppColors.glassBorder,
        child: Row(
          children: [
            // Slot Numarası
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isUploaded
                    ? LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.3),
                          AppColors.success.withValues(alpha: 0.1),
                        ],
                      )
                    : isLocked
                        ? LinearGradient(
                            colors: [
                              AppColors.textMuted.withValues(alpha: 0.1),
                              AppColors.textMuted.withValues(alpha: 0.05),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Color(int.parse(skill.color.replaceAll('#', '0xFF')))
                                  .withValues(alpha: 0.3),
                              Color(int.parse(skill.color.replaceAll('#', '0xFF')))
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: isUploaded
                    ? Icon(Icons.check, color: AppColors.success, size: 24)
                    : isUploading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accentGreen,
                              ),
                            ),
                          )
                        : isLocked
                            ? Icon(Icons.lock, color: AppColors.textMuted, size: 20)
                            : Text(
                                skill.icon,
                                style: TextStyle(fontSize: 24),
                              ),
              ),
            ),
            
            SizedBox(width: 16),
            
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slot $slot: ${skill.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? const Color(0xFFB8C4D4)
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isLocked
                        ? 'Önce önceki slot tamamlanmalı'
                        : skill.isKosuSlot
                            ? kosuDone
                                ? 'Koşu testi tamamlandı'
                                : kosuFlat
                                    ? 'Adım 2: 10 metre yokuş yukarı koşu'
                                    : 'Adım 1: 20 metre düz koşu'
                            : skill.displayDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isLocked
                          ? const Color(0xFF9AA8BC)
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (skill.isKosuSlot && !isLocked && !kosuDone) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'Koşu çekimi: telefon sabit, yan görünüm, başlangıç ve bitiş '
                        'çizgisi/konisi görünsün. 20m düzde tüm mesafe kadrajda olsun.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppColors.textMuted.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                  if (skill.isKosuSlot && (kosuFlat || kosuUphill)) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          kosuFlat ? Icons.check_circle : Icons.circle_outlined,
                          size: 14,
                          color: kosuFlat ? AppColors.success : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '20m düz',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          kosuUphill ? Icons.check_circle : Icons.circle_outlined,
                          size: 14,
                          color: kosuUphill ? AppColors.success : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '10m yokuş',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isUploaded) ...[
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Yüklendi',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Durum ikonu
            Icon(
              isUploaded
                  ? Icons.check_circle
                  : isLocked
                      ? Icons.lock_outline
                      : isUploading
                          ? Icons.hourglass_top
                          : Icons.add_circle,
              color: isUploaded
                  ? AppColors.success
                  : isLocked
                      ? AppColors.textMuted
                      : isUploading
                          ? AppColors.accentOrange
                          : AppColors.accentGreen,
              size: 28,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (slot * 100).ms);
  }
}

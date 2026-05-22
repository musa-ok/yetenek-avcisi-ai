import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../app_theme.dart';
import '../app_services.dart';
import '../services/multi_upload_service.dart';
import '../main.dart' show latestAnalysisNotifier, AnalysisResult, playersRefreshNotifier, kPitchGreen;
import 'player_stats_screen.dart';

/// ==========================================
/// MULTI-UPLOAD SCREEN
/// Glassmorphism + Dark Mode
/// ==========================================

class MultiUploadScreen extends StatefulWidget {
  const MultiUploadScreen({super.key});

  @override
  State<MultiUploadScreen> createState() => _MultiUploadScreenState();
}

class _MultiUploadScreenState extends State<MultiUploadScreen> {
  // Mevki seçimi
  String selectedPosition = 'Forvet';
  final List<String> positions = [
    'Kaleci',
    'Stoper', 
    'Bek',
    'On Numara',
    'Kanat',
    'Forvet'
  ];

  // Kullanıcı bilgileri auth'dan otomatik çekilecek
  // Artık manuel isim/doğum tarihi girişi yok
  
  // State
  List<PositionSkill> skills = [];
  MultiVideoPlayer? player;
  bool isLoading = false;
  bool isCreatingPlayer = false;
  bool isAnalyzing = false; // AI analizi süreci kilitliyor
  int currentUploadingSlot = 0;

  @override
  void initState() {
    super.initState();
    _loadPositionSkills();
  }

  Future<void> _loadPositionSkills() async {
    setState(() => isLoading = true);
    try {
      final loadedSkills = await MultiUploadService.getPositionSkills(selectedPosition);
      setState(() => skills = loadedSkills);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yetenekler yüklenemedi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
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

  Future<void> _createPlayer() async {
    final user = currentUserNotifier.value;
    final token = currentAccessTokenNotifier.value;
    
    if (user == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce giriş yapın'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => isCreatingPlayer = true);
    
    try {
      // Kullanıcı bilgileri Bearer token'dan otomatik çekiliyor
      // Sadece mevki gönderiliyor, isim/yaş token'dan alınıyor
      final newPlayer = await MultiUploadService.createPlayerFromAuth(
        position: selectedPosition,
        accessToken: token,
      );

      setState(() => player = newPlayer);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${newPlayer.name} için 3 video yüklemeye başlayın'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => isCreatingPlayer = false);
    }
  }

  // Aşamalı yükleme: Kaçıncı slota kadar yüklendi?
  int get _completedSlots {
    if (player == null) return 0;
    return player!.videos.where((v) => v.isUploaded).length;
  }

  // Slot aktif mi? (Aşamalı yükleme)
  bool _isSlotActive(int slot) {
    // Sadece sıradaki slot aktif
    // Slot 1 her zaman aktif
    // Slot 2, slot 1 tamamlandıktan sonra aktif
    // Slot 3, slot 2 tamamlandıktan sonra aktif
    final completed = _completedSlots;
    return slot <= completed + 1;
  }

  /// Tüm slot durumlarını sıfırla - yeni analiz için
  void _resetAllSlots() {
    setState(() {
      // Player'ı null yap - yeni başlangıç
      player = null;
      selectedPosition = null;
      currentUploadingSlot = 0;
      isAnalyzing = false;
      slotSkills = {};
    });
    debugPrint('[MultiUpload] All slots reset - ready for new analysis');
  }

  /// Wi-Fi bağlantısı kontrolü - mobil veri mi yoksa Wi-Fi mı?
  /// Android'de Wi-Fi kontrolü için connectivity_plus gerekli
  /// iOS'ta hücresel veri kontrolü için Reachability kullanılır
  Future<bool> _checkIsWiFiConnection() async {
    try {
      // Platform spesifik kontrol yerine basit bir bant genişliği testi
      final stopwatch = Stopwatch()..start();
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 2));
      stopwatch.stop();
      
      // 150ms'den hızlıysa muhtemelen Wi-Fi (mobil veri genelde daha yavaş)
      // Bu tam olarak doğru değil ama bir tahmin
      final isFast = stopwatch.elapsedMilliseconds < 150;
      debugPrint('[WiFi Check] Response time: ${stopwatch.elapsedMilliseconds}ms, isFast: $isFast');
      return isFast;
    } on TimeoutException {
      debugPrint('[WiFi Check] Timeout - slow connection, likely mobile data');
      return false;
    } catch (e) {
      debugPrint('[WiFi Check] Error: $e');
      return false;
    }
  }

  Future<void> _uploadVideo(int slot, PositionSkill skill) async {
    // Aşamalı kontrol: Sadece aktif slot yüklenebilir
    if (!_isSlotActive(slot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Önce önceki videoyu tamamlayın'),
          backgroundColor: AppColors.warning,
        ),
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

    // Mobil veri kontrolü - basit HTTP ping ile Wi-Fi hızını tahmin et
    final isWiFi = await _checkIsWiFiConnection();
    
    if (!isWiFi) {
      // Wi-Fi değilse, mobil veri ayarını kontrol et
      final prefs = await SharedPreferences.getInstance();
      final mobileUploadAllowed = prefs.getBool('settings_mobile_upload_allowed') ?? false;
      
      if (!mobileUploadAllowed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mobil veride video yüklemek için ayarlardan izin vermelisiniz'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

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
      if (slot < 3 && !updatedPlayer.isComplete) {
        final nextSkill = skills[slot]; // slot 1 index 0, slot 2 index 1
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Sıradaki: ${nextSkill.name} videosunu yükleyin'),
            backgroundColor: AppColors.accentBlue,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Tamamlandı mı kontrol et
      if (!mounted) return;  // 🛡️ Güvenlik kontrolü
      if (updatedPlayer.isComplete) {
        await _finalizePlayer();
      }
    } catch (e) {
      if (!mounted) return;  // 🛡️ Güvenlik: Hata durumunda sayfa kapandıysa dur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video yüklenemedi: $e'),
          backgroundColor: AppColors.error,
        ),
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
          content: const Text(
            '3 video tamamlandı. AI analizi başlatılsın mı?',
            style: TextStyle(color: Colors.white70),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Videolar kaydedildi. Analiz istatistiklerden başlatılabilir.'),
            backgroundColor: AppColors.accentBlue,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }
    
    // Tüm butonları kilitle
    if (!mounted) return;  // 🛡️ Güvenlik kontrolü
    setState(() => isAnalyzing = true);

    try {
      // AI analizi yap (Gemini 1-3 dk sürebilir)
      final finalizedPlayer = await MultiUploadService.finalizePlayer(player!.id);

      if (!mounted) return;  // 🛡️ Güvenlik: AI analizi sırasında sayfa kapandıysa
      setState(() {
        player = finalizedPlayer;
        isAnalyzing = false;
      });

      // Ana sayfadaki "Benim İstatistiklerim" listesinin güncel skorları
      // göstermesi için global notifier'ı set et.
      latestAnalysisNotifier.value = AnalysisResult(
        overall: finalizedPlayer.overallRating,
        pace: finalizedPlayer.pace ?? 0,
        finishing: finalizedPlayer.finishing ?? 0,
        passing: finalizedPlayer.passing ?? 0,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analiz tamamlanamadı: $e'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 6),
        ),
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
    return Stack(
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
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideX(),

                  SizedBox(height: 8),

                  Text(
                    'Her mevki için 3 farklı yeteneğinizi gösteren kısa videolar yükleyin',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                        onPressed: isCreatingPlayer ? null : _createPlayer,
                        child: isCreatingPlayer
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.scaffoldBackground,
                                ),
                              )
                            : Text('Başla ve 3 Video Yükle'),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ] else ...[
                    // İlerleme
                    _buildProgressHeader(),

                    SizedBox(height: 24),

                    // 3 Video Slotu
                    if (skills.isNotEmpty) ...[
                      _buildVideoSlot(1, skills[0]),
                      SizedBox(height: 16),
                      _buildVideoSlot(2, skills[1]),
                      SizedBox(height: 16),
                      _buildVideoSlot(3, skills[2]),
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
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
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
                style: Theme.of(context).textTheme.titleMedium,
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
            '${((progress / 100) * 3).round()}/3 Video Yüklendi',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSlot(int slot, PositionSkill skill) {
    final videoInfo = player?.videos.firstWhere(
      (v) => v.slot == slot,
      orElse: () => VideoInfo(slot: slot),
    );
    final isUploaded = videoInfo?.isUploaded ?? false;
    final isUploading = currentUploadingSlot == slot;
    final isActive = _isSlotActive(slot);
    final isLocked = !isActive && !isUploaded;

    return GestureDetector(
      onTap: isUploaded || isUploading || isLocked || isAnalyzing ? null : () => _uploadVideo(slot, skill),
      child: GlassmorphismContainer(
        padding: EdgeInsets.all(20),
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
                      color: isLocked ? AppColors.textMuted : Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isLocked 
                        ? 'Önce ${slot == 2 ? "Slot 1" : "Slot 2"} tamamlanmalı'
                        : skill.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isLocked ? AppColors.textMuted : null,
                    ),
                  ),
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

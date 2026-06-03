import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'share_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:yetenek_avcisi/app_services.dart';
import 'package:yetenek_avcisi/app_services_enhanced.dart';
import 'package:yetenek_avcisi/app_theme.dart';
import 'package:yetenek_avcisi/screens/multi_upload_screen.dart';
import 'package:yetenek_avcisi/screens/player_stats_screen.dart';
import 'package:yetenek_avcisi/screens/fullscreen_multi_video_player.dart';
import 'package:yetenek_avcisi/screens/video_player_screen.dart';
import 'package:yetenek_avcisi/screens/complete_profile_screen.dart';
import 'package:yetenek_avcisi/screens/otp_verification_screen.dart';
import 'package:yetenek_avcisi/services/multi_upload_service.dart';
import 'package:yetenek_avcisi/widgets/analysis_finalize_dialog.dart';
import 'package:yetenek_avcisi/widgets/smart_summary_card.dart';
import 'package:yetenek_avcisi/widgets/slot_breakdown_card.dart';
import 'package:yetenek_avcisi/widgets/combined_ovr_strip.dart';
import 'package:yetenek_avcisi/widgets/scoutiq_logo_mark.dart';
import 'package:yetenek_avcisi/core/app_notifiers.dart';
import 'package:yetenek_avcisi/widgets/home_merged_stats_section.dart';
import 'package:yetenek_avcisi/widgets/home_merged_stats_labels.dart';
import 'package:yetenek_avcisi/widgets/home_loading_skeleton.dart';
import 'package:yetenek_avcisi/core/auth/session_auth.dart';
import 'package:yetenek_avcisi/core/deep_link/deep_link_service.dart';
import 'package:yetenek_avcisi/core/utils/fifa_six_stats.dart';
import 'package:yetenek_avcisi/core/settings/app_settings.dart';
import 'package:yetenek_avcisi/core/utils/share_helper.dart';
import 'package:yetenek_avcisi/core/utils/fifa_share_image.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yetenek_avcisi/features/profile/presentation/pages/my_info_screen.dart';
import 'package:yetenek_avcisi/screens/privacy_policy_screen.dart';
import 'package:yetenek_avcisi/screens/forgot_password_screen.dart';
import 'package:yetenek_avcisi/screens/pending_approval_screen.dart';
import 'package:yetenek_avcisi/screens/admin_panel_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yetenek_avcisi/core/constants/app_constants.dart';
import 'package:yetenek_avcisi/core/api/api_client.dart';
import 'package:yetenek_avcisi/core/constants/turkish_cities.dart';
import 'package:yetenek_avcisi/core/utils/social_auth_helper.dart';
import 'package:yetenek_avcisi/features/product/player_compare_screen.dart';
import 'package:yetenek_avcisi/features/product/player_profile_edit_sheet.dart';
import 'package:yetenek_avcisi/features/product/product_screens.dart';
import 'package:yetenek_avcisi/core/navigation/app_navigator.dart';
import 'package:yetenek_avcisi/services/push_notification_service.dart';

const Color kScaffoldDark = Color(0xFF0B0F19);
const Color kElevatedCard = Color(0xFF151C2B);
const Color kPitchGreen = Color(0xFF00FF87);

enum AppLanguage { tr, en }

final ValueNotifier<AppLanguage> appLanguageNotifier = ValueNotifier(
  AppLanguage.tr,
);
Future<void> _loadSavedLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('settings_language');
    if (v == 'English') {
      appLanguageNotifier.value = AppLanguage.en;
    } else {
      appLanguageNotifier.value = AppLanguage.tr;
    }
  } catch (_) {
    appLanguageNotifier.value = AppLanguage.tr;
  }
}

class L10n {
  const L10n(this.lang);
  final AppLanguage lang;
  bool get en => lang == AppLanguage.en;

  String get appTitle => AppConstants.appName;

  String get loginSubtitle => en
      ? 'Sign in as a player or scout — manage your profile and discover talent.'
      : 'Futbolcu veya scout hesabınla giriş yap; profilini yönet, yetenekleri keşfet.';

  String get password => en ? 'Password' : 'Şifre';

  String get forgotPassword => en ? 'Forgot password?' : 'Şifremi Unuttum?';

  String get login => en ? 'Sign In' : 'Giriş Yap';

  String get noAccount => en ? 'No account? ' : 'Hesabın yok mu? ';

  String get register => en ? 'Sign Up' : 'Kayıt Ol';

  String registerTitle2(String role) => en
      ? (role == 'Scout' ? 'Create Scout Account' : 'Create Player Account')
      : (role == 'Scout' ? 'Yeni Scout Hesabı' : 'Yeni Futbolcu Hesabı');
  String get registerTitle => en ? 'Create account' : 'Yeni Scout Hesabı';

  String get registerSubtitle => en
      ? 'Choose scout or player and start with the right experience.'
      : 'Scout veya futbolcu profili oluştur, doğru deneyimle başla.';

  String get fullName => en ? 'Full name' : 'Tam Adınız';

  String get scout => 'Scout';
  String get player => en ? 'Player' : 'Futbolcu';

  String get confirmPassword => en ? 'Confirm password' : 'Şifre Tekrar';

  String get signUp => en ? 'Sign Up' : 'Kayıt Ol';

  String get haveAccount =>
      en ? 'Already have an account? ' : 'Zaten hesabın var mı? ';

  String get fallbackName => en ? 'User' : 'Kullanıcı';

  String get tabHome => en ? 'Home' : 'Ana Sayfa';

  String get tabDiscover => en ? 'Explore' : 'Keşfet';

  String get tabProfile => en ? 'Profile' : 'Profil';

  String get fabRecord => en ? 'Record player' : 'Oyuncu Çek';

  String welcomeBack(String name) =>
      en ? 'Welcome back, $name' : 'Hoş Geldin, $name';

  String accountType(String roleRaw) {
    final label = roleRaw == 'Futbolcu'
        ? (en ? 'Player' : 'Futbolcu')
        : (en ? 'Scout' : 'Scout');
    return en ? 'Account: $label' : 'Hesap Türü: $label';
  }

  String get prospectsTitle => en ? 'Young talent' : 'Genç Yetenekler';

  String get topProspects => en ? 'Top prospects' : 'Top Prospects';

  String get sectionMyStats => en ? 'My stats' : 'Benim İstatistiklerim';

  String get sectionScoutReports =>
      en ? 'Recent scout reports' : 'Recent Scout Reports';

  String get ratingOverall => en ? 'Overall rating' : 'Genel Reyting';

  String get statPace => en ? 'Pace' : 'Hız';

  String get statFinishing => en ? 'Finishing' : 'Bitiricilik';

  String get statShooting => en ? 'Shooting' : 'Şut';

  String get statPassing => en ? 'Passing' : 'Pas';

  String get statDribbling => en ? 'Dribbling' : 'Dripling';

  String get statDefending => en ? 'Defending' : 'Savunma';

  String get statPhysical => en ? 'Physical' : 'Fizik';

  String get fabStartAnalysis => en ? 'Start analysis' : 'Analize Başla';

  String get fabImproveScore =>
      en ? 'Boost your score (upload new video)' : 'Puanını Yükselt (Yeni Video Yükle)';

  String get shareStats => en ? 'Share stats' : 'İstatistikleri paylaş';

  String get shareFailed => en ? 'Share failed' : 'Paylaşım başarısız';

  String get myStatsEmptyHint => en
      ? 'Complete a video analysis to see your stats here.'
      : 'İstatistiklerin analiz tamamlanınca burada görünür.';

  String yearsOld(int age) => en ? '$age yrs' : '$age yaş';

  String positionLine(String position) =>
      en ? 'Position: $position' : 'Pozisyon: $position';

  String get searchHint => en ? 'Search players...' : 'Oyuncu ara...';

  String posChip(String raw) {
    switch (raw) {
      case 'Tum':
        return en ? 'All' : 'Tüm';
      case 'Forvet':
        return en ? 'FW' : 'Forvet';
      case 'Orta Saha':
        return en ? 'MID' : 'Orta Saha';
      case 'Defans':
        return en ? 'DEF' : 'Defans';
      case 'Kaleci':
        return en ? 'GK' : 'Kaleci';
      default:
        return raw;
    }
  }

  String get emptyTalentSearch =>
      en ? 'Search for talents…' : 'Arama yapmak için yazın...';

  String searchActive(String query, String position) => en
      ? 'Search: "$query"\nPosition: $position'
      : 'Arama: "$query"\nPozisyon: $position';

  String get logoutTitle => en ? 'Sign out' : 'Çıkış Yap';

  String get logoutMessage => en
      ? 'Are you sure you want to sign out?'
      : 'Çıkış yapmak istediğinize emin misiniz?';

  String get cancel => en ? 'Cancel' : 'İptal';

  String get confirm => en ? 'Yes' : 'Evet';

  String get profileBadge =>
      en ? 'Young talent / Player' : 'Genç Yetenek / Futbolcu';

  String profileSubtitleForRole(String role) => role == 'Futbolcu'
      ? (en ? 'Player account' : 'Futbolcu hesabı')
      : (en ? 'Scout account' : 'Scout hesabı');

  String get myStatistics => en ? 'Statistics' : 'İstatistiklerim';

  String get analysisHistory => en ? 'Analysis history' : 'Analiz Geçmişi';

  String get settings => en ? 'Settings' : 'Ayarlar';

  String get logout => en ? 'Sign out' : 'Çıkış Yap';

  String openingSoon(String section) =>
      en ? '$section opening soon…' : '$section açılıyor…';

  String get settingsLoadFailed =>
      en ? 'Could not load settings.' : 'Ayarlar şu anda yüklenemedi.';

  String get tryAgain => en ? 'Retry' : 'Tekrar Dene';

  String get favorites => en ? 'Favorites' : 'Favoriler';

  String get myFavorites => en ? 'My favorites' : 'Favorilerim';

  String get addedToFavorites =>
      en ? 'Added to favorites' : 'Favorilere eklendi';

  String get removedFromFavorites =>
      en ? 'Removed from favorites' : 'Favorilerden çıkarıldı';

  String get addToFavorites => en ? 'Add to favorites' : 'Favorilere ekle';

  String get removeFromFavorites =>
      en ? 'Remove from favorites' : 'Favorilerden çıkar';

  String get favoritesEmpty =>
      en ? 'No players in favorites yet' : 'Favorilerinde henüz oyuncu yok';

  String favoritesShareLink(String link) => en
      ? '${AppConstants.appName} favorites: $link'
      : '${AppConstants.appName} favorilerim: $link';

  String get notifications => en ? 'Notifications' : 'Bildirimler';

  String get notificationsSub => en
      ? 'Phone push for analysis, scout ratings and notes. In-app inbox: Profile → Notifications.'
      : 'Telefon bildirimi: analiz, scout puanı, not. Uygulama içi liste: Profil → Bildirimler.';

  String get mobileDataUpload =>
      en ? 'Mobile data uploads' : 'Mobil Veri ile Yükleme';

  String get mobileDataUploadSub => en
      ? 'Allow video upload without Wi‑Fi'
      : 'Wi-Fi dışında video yüklemeye izin ver';

  String get notificationsEnabledSnack => en
      ? 'Phone notifications on. Push will be sent for analysis and scout activity.'
      : 'Telefon bildirimleri açıldı. Analiz ve scout işlemlerinde push gidecek.';

  String get notificationsDisabledSnack => en
      ? 'Phone notifications off. No push on this device; in-app list still available.'
      : 'Telefon bildirimleri kapalı. Push gitmez; Profil → Bildirimler listesi durur.';

  String get testNotification => en ? 'Send test notification' : 'Test bildirimi gönder';

  String get testNotificationSub => en
      ? 'Preview the in-app banner (requires notifications on).'
      : 'In-app banner önizlemesi (bildirimler açık olmalı).';

  String get mobileUploadEnabledSnack => en
      ? 'You can upload videos on mobile data.'
      : 'Mobil veri ile video yükleyebilirsin.';

  String get mobileUploadDisabledSnack => en
      ? 'Video upload on mobile data is off (Wi-Fi only).'
      : 'Mobil veri yüklemesi kapalı — sadece Wi-Fi.';

  String get mobileUploadBlockedSnack => en
      ? 'Enable mobile data upload in Settings, or connect to Wi-Fi.'
      : 'Mobil veride yüklemek için Ayarlar\'dan izin ver veya Wi-Fi\'ye bağlan.';

  String get autoAnalyze => en ? 'Automatic analysis' : 'Otomatik Analiz';

  String get autoAnalyzeSub => en
      ? 'Start analysis automatically after upload'
      : 'Video yüklenince analiz otomatik başlasın';

  String get uiLanguage => en ? 'Language' : 'Uygulama Dili';

  String get uiLanguageSub => en ? 'Display language' : 'Arayüz dil tercihi';

  String get cameraSimulatorSnack => en
      ? 'Simulator has no camera. Please use the gallery.'
      : 'Simülatörde kamera desteklenmiyor, lütfen Galeriyi kullanın.';

  String get uploadReady => en ? 'Ready' : 'Hazır';

  String get uploadSending =>
      en ? 'Uploading video…' : 'Video sunucuya gönderiliyor...';

  String get uploadAi =>
      en ? 'AI is analyzing…' : 'Yapay Zeka analiz ediyor...';

  String errorServer(int code) =>
      en ? 'Server error: $code' : 'Sunucu hatası: $code';

  String errorGeneric(Object e) =>
      en ? 'Something went wrong: $e' : 'Hata oluştu: $e';

  String get aiAnalysisTitle => en ? 'AI analysis' : 'Yapay Zeka Analizi';

  String get scoutNote => en ? 'Scout note' : 'Scout Notu';

  String get close => en ? 'Close' : 'Kapat';

  String get pickPosition => en ? 'Pick position' : 'Mevki Seçimi';

  String get camera => en ? 'Camera' : 'Kamera';

  String get gallery => en ? 'Gallery' : 'Galeri';

  String get reportNotReady =>
      en ? 'Report not available.' : 'Rapor hazır değil.';

  String instructionForPosition(String key) {
    if (en) {
      switch (key) {
        case 'Forvet':
          return 'Capture shooting, finishing, and tight-space dribbling.';
        case 'Orta Saha':
          return 'Focus on vision, long passing, and ball control.';
        case 'Defans':
          return 'Record 1v1 defending, tackling timing, and aerial duels.';
        case 'Kaleci':
          return 'Record reflex saves, distribution, and footwork.';
        default:
          return '';
      }
    }
    switch (key) {
      case 'Forvet':
        return 'Şut, bitiricilik ve dar alanda dripling yeteneklerini gösteren anları çekin.';
      case 'Orta Saha':
        return 'Oyun görüşü, uzun pas isabeti ve top kontrolü aksiyonlarına odaklanın.';
      case 'Defans':
        return 'Bire bir savunma, top çalma zamanlaması ve hava topu mücadelelerini kaydedin.';
      case 'Kaleci':
        return 'Refleks kurtarışları, yan top hakimiyeti ve ayakla oyun kurma anlarını çekin.';
      default:
        return '';
    }
  }

  String get phoneHint => en ? 'Phone number' : 'Telefon numarası';

  String get playerAgeLabel => en ? 'Age' : 'Yaş';

  String get contactPlayer => en ? 'Contact' : 'İletişime Geç';

  String get whatsAppOpenFailed =>
      en ? 'Could not open WhatsApp for this number.' : 'WhatsApp açılamadı.';

  String get noPhoneOnProfile => en
      ? 'This player has no phone number on record.'
      : 'Bu oyuncu için telefon kaydı yok.';

  String get scoutsMayContactPlayers => en
      ? 'Only scouts can message players.'
      : 'Oyuncuya mesaj sadece scout hesapları için.';

  String whatsAppDraft(String playerName) => en
      ? 'Hello $playerName, reaching out from ${AppConstants.appName}.'
      : 'Merhaba $playerName, ${AppConstants.appName} üzerinden ulaşıyorum.';

  String get playersLoadHint =>
      en ? 'Could not refresh player list.' : 'Oyuncu listesi yüklenemedi.';

  String get tryRefresh => en ? 'Swipe to refresh' : 'Yenilemek için çekin';

  String get rosterEmptyHint => en
      ? 'No players registered in the system yet.'
      : 'Henüz sisteme kayıtlı bir futbolcu bulunmuyor.';

  String get exploreFilterTitle => en ? 'Filter' : 'Filtrele';

  String get exploreFilterEmptyHint => en
      ? 'No players match your filters.'
      : 'Seçtiğiniz filtrelere uygun oyuncu bulunamadı.';

  String get clearFilters => en ? 'Clear filters' : 'Filtreleri temizle';

  String get homeComparePlayersTitle =>
      en ? 'Compare players' : 'Oyuncuları Karşılaştır';

  String get homeComparePlayersSubtitle => en
      ? 'Side-by-side OVR and skills — your sessions or players on Discover.'
      : 'OVR ve becerileri yan yana: kendi oturumların veya Keşfet\'teki oyuncular.';

  String get homeMyAnalyses =>
      en ? 'On Discover' : 'Keşfet\'teki analizlerim';

  String get homeMyAnalysesEmpty => en
      ? 'No active analysis on Discover yet. Complete a session to appear here.'
      : 'Keşfet\'te görünen analizin henüz yok. Oturumu tamamlayınca burada görünür.';

  String get homeQuickUpload => en ? 'Upload' : 'Video yükle';

  String homeOvrRise7d(int delta) =>
      en ? '+$delta OVR in the last 7 days' : 'Son 7 günde +$delta OVR';

  String get homeCompareScoutTitle =>
      en ? 'Compare players' : 'Oyuncu Karşılaştır';

  String get homeCompareScoutSubtitle => en
      ? 'Pick two players; see OVR and skills side by side.'
      : 'İki oyuncu seç; OVR ve becerileri yan yana gör.';

  String get homeCompareScoutEmpty => en
      ? 'No players on Discover to compare yet.'
      : 'Karşılaştırılacak oyuncu henüz yok. Keşfet\'i kontrol edin.';

  String get homeQuickCompare => en ? 'Compare' : 'Karşılaştır';

  String get homeQuickExplore => en ? 'Discover' : 'Keşfet';

  String get homeSeeAllInExplore => en
      ? 'See all in Discover'
      : 'Tümünü Keşfet\'te gör';

  String get pleaseFillFields => en
      ? 'Please fill in all required fields.'
      : 'Lütfen tüm gerekli alanları doldurun.';

  String get passwordMismatch =>
      en ? 'Passwords do not match.' : 'Şifreler eşleşmiyor.';

  String get dashboardPoolPreview =>
      en ? 'Featured Talents' : 'Öne Çıkan Yetenekler';

  String get registeredPlayersSection =>
      en ? 'Registered players' : 'Kayıtlı oyuncular';

  String get tapRetryPlayers => en ? 'Tap to retry' : 'Tekrar dene';
}

class L10nScope extends InheritedWidget {
  const L10nScope({super.key, required this.l10n, required super.child});

  final L10n l10n;

  static L10n of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<L10nScope>();
    assert(scope != null, 'L10nScope not found');
    return scope!.l10n;
  }

  @override
  bool updateShouldNotify(L10nScope oldWidget) =>
      oldWidget.l10n.lang != l10n.lang;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFF0B0F19),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              details.exceptionAsString(),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  runApp(const ScoutiqApp());
  unawaited(_bootstrapAppServices());
}

Future<void> _bootstrapAppServices() async {
  await _loadSavedLanguage();
  try {
    await PushNotificationService.initialize();
  } catch (e, st) {
    debugPrint('[FCM] main init hatasi: $e\n$st');
  }
  await SessionStore.restoreIntoNotifier();
  try {
    await SessionAuth.warmSessionAfterRestore();
  } catch (e, st) {
    debugPrint('[Auth] session warm: $e\n$st');
  }
  try {
    await PushNotificationService.applyNotificationPreference();
  } catch (e, st) {
    debugPrint('[FCM] preference sync: $e\n$st');
  }
  try {
    await DeepLinkService.init();
  } catch (e, st) {
    debugPrint('[DeepLink] init: $e\n$st');
  }
  currentAccessTokenNotifier.addListener(() {
    PushNotificationService.applyNotificationPreference();
  });
}

class ScoutiqApp extends StatefulWidget {
  const ScoutiqApp({super.key});

  @override
  State<ScoutiqApp> createState() => _ScoutiqAppState();
}

class _ScoutiqAppState extends State<ScoutiqApp> with WidgetsBindingObserver {
  StreamSubscription<DeepLinkTarget>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deepLinkSub = DeepLinkService.stream.listen(_onDeepLink);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SessionAuth.warmSessionAfterRestore());
    }
  }

  void _onDeepLink(DeepLinkTarget target) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    switch (target) {
      case DeepLinkPlayer(:final playerId):
        BackendApi.fetchPlayerDetail(playerId).then((detail) {
          if (!nav.mounted) return;
          nav.push(
            MaterialPageRoute(
              builder: (_) => PlayerDetailScreen(player: detail.player),
            ),
          );
        }).catchError((e) => debugPrint('[DeepLink] player: $e'));
      case DeepLinkInvite():
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appLanguageNotifier,
      builder: (context, _) {
        final l10n = L10n(appLanguageNotifier.value);
        final base = ThemeData.dark(useMaterial3: true);
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: base.copyWith(
            scaffoldBackgroundColor: kScaffoldDark,
            colorScheme: base.colorScheme.copyWith(
              primary: kPitchGreen,
              surface: kElevatedCard,
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            cardColor: kElevatedCard,
            dividerColor: Colors.white12,
            appBarTheme: const AppBarTheme(
              backgroundColor: kScaffoldDark,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              scrolledUnderElevation: 0,
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF2A3448),
              contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
              behavior: SnackBarBehavior.floating,
            ),
          ),
          builder: (context, child) => L10nScope(
            l10n: l10n,
            child: child ?? const SplashScreen(),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SessionRouter(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      await PushNotificationService.handlePendingLaunchNotification();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ScoutiqLogoMark(size: 120),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appTagline,
                      style: TextStyle(
                        color: kPitchGreen,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SessionRouter extends StatelessWidget {
  const SessionRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: currentUserNotifier,
      builder: (context, _) {
        final user = currentUserNotifier.value;
        if (user == null) return const LoginScreen();
        
        // Doğrulanmamış kullanıcı → OTP ekranına yönlendir
        if (!user.isVerified) {
          return OtpVerificationScreen(
            email: user.email ?? '',
            isSocialLogin: false,
            autoResendOnLoad: false,
          );
        }

        final role = (user.role ?? '').toLowerCase().trim();
        
        // Admin -> Admin Panel
        if (role == 'admin') {
          return const AdminPanelScreen();
        }
        
        // Pending Scout -> Pending Approval Screen
        if (role == 'pending_scout') {
          return const PendingApprovalScreen();
        }
        
        // Approved Scout or any other role -> Main Screen
        return const MainScreen();
      },
    );
  }
  
  void _refreshUserData() async {
    // Refresh session from storage to get updated user data
    try {
      await SessionStore.restoreIntoNotifier();
    } catch (e) {
      debugPrint('Session refresh error: $e');
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_submitting) return;
    final l = L10nScope.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final messenger = ScaffoldMessenger.of(context);

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir e-posta adresi giriniz.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.pleaseFillFields),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final session = await BackendApi.login(email: email, password: password);
      await SessionStore.save(session);
      currentUserNotifier.value = session.user;
      currentAccessTokenNotifier.value = session.accessToken;
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 403) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Lütfen önce e-posta adresinizi doğrulayın.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: email,
                password: password,
                isSocialLogin: false,
                autoResendOnLoad: true,
                onVerificationComplete: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
          );
          return;
        }
        
        String errorMsg = e.message;
        if (e.statusCode == 401) errorMsg = 'E-posta veya şifre hatalı.';
        if (e.statusCode == 404) errorMsg = 'Kullanıcı bulunamadı.';

        messenger.showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_friendlyLoginError(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);

    try {
      if (provider == 'google') {
        final googleSignIn = GoogleSignIn(
          clientId: '205838843244-fvd7tqaq952gj7nmi7ffga5243chlilf.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => _submitting = false);
          return;
        }

        final email = googleUser.email;
        final fullName = googleUser.displayName ?? email.split('@').first;
        final providerId = googleUser.id;

        if (!mounted) return;

        final result = await BackendApi.socialLogin(
          provider: 'google',
          email: email,
          fullName: fullName,
          providerId: providerId,
        );

        debugPrint('[SOCIAL LOGIN] status=${result.status}, hasSession=${result.session != null}');

        if (!mounted) return;

        if (result.isComplete && result.session != null) {
          await SessionStore.save(result.session!);
          debugPrint('[LOGIN SOCIAL] Setting currentUserNotifier, isVerified=${result.session!.user.isVerified}');
          currentAccessTokenNotifier.value = result.session!.accessToken;
          currentUserNotifier.value = result.session!.user;
          // SessionRouter otomatik MainScreen'e geçirecek
        } else if (result.isIncomplete) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                email: email,
                fullName: fullName,
                provider: 'google',
                providerId: providerId,
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Sunucudan beklenmeyen bir yanıt geldi.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else if (provider == 'apple') {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final appleProviderId = credential.userIdentifier?.trim() ?? '';
        if (appleProviderId.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Apple kimliği alınamadı. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        final appleEmail = SocialAuthHelper.resolveAppleEmailForApi(credential);
        final appleFullName = SocialAuthHelper.resolveAppleFullName(credential);

        if (!mounted) return;

        final result = await BackendApi.socialLogin(
          provider: 'apple',
          email: appleEmail,
          fullName: appleFullName,
          providerId: appleProviderId,
        );

        if (!mounted) return;

        if (result.isComplete && result.session != null) {
          await SessionStore.save(result.session!);
          currentAccessTokenNotifier.value = result.session!.accessToken;
          currentUserNotifier.value = result.session!.user;
        } else if (result.isIncomplete) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                email: result.email ?? appleEmail,
                fullName: result.fullName ?? appleFullName,
                provider: 'apple',
                providerId: appleProviderId,
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Sunucudan beklenmeyen bir yanıt geldi.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[LOGIN SOCIAL] ERROR: $e');
      if (mounted) {
        final msg = _friendlyLoginError(e);
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyLoginError(Object e) {
    final raw = e.toString();
    if (raw.contains('Connection refused') || raw.contains('127.0.0.1:8000')) {
      return 'Sunucuya bağlanılamadı. Uygulamayı prod API ile çalıştırın veya yerel backend\'i (port 8000) başlatın.';
    }
    if (e is ApiException) return e.message;
    return 'Giriş yapılamadı. Lütfen tekrar deneyin.';
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: Colors.white30, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = (width * 0.07).clamp(20.0, 30.0);
    final l = L10nScope.of(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 24),
          children: [
            const Icon(Icons.sports_soccer, color: kPitchGreen, size: 40),
            const SizedBox(height: 16),
            Text(
              l.appTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.loginSubtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),
            AuthTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              hintText: l.password,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white70,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  l.forgotPassword,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GlowPrimaryButton(
              label: l.login,
              isLoading: _submitting,
              onTap: _submitLogin,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'veya şununla devam et',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: FontAwesomeIcons.apple,
                  color: Colors.black,
                  bgColor: Colors.white,
                  onTap: () => _handleSocialLogin('apple'),
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: FontAwesomeIcons.google,
                  color: Colors.black87,
                  bgColor: Colors.white,
                  isOutlined: true,
                  onTap: () => _handleSocialLogin('google'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.noAccount,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    l.register,
                    style: const TextStyle(
                      color: kPitchGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;
  bool _acceptedPrivacyPolicy = false;
  String _selectedRole = 'Scout';
  DateTime? _birthDate;
  String? _emailError;
  int _passwordStrength = 0;

  static int _getPasswordStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    int score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.contains(RegExp(r'[A-Z]'))) score++;
    if (pwd.contains(RegExp(r'[0-9]'))) score++;
    if (pwd.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    if (score <= 1) return 1;
    if (score <= 2) return 2;
    return 3;
  }

  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  Future<void> _loadPendingReferralCode() async {
    final code = await DeepLinkService.peekPendingInvite();
    if (code != null && code.trim().isNotEmpty && mounted) {
      _referralCodeController.text = code.trim().toUpperCase();
    }
  }

  Widget _buildPasswordStrengthBar() {
    const labels = ['', 'Zayıf', 'Orta', 'Güçlü'];
    const colors = [
      Colors.transparent,
      Colors.redAccent,
      Colors.orangeAccent,
      Color(0xFF00E676),
    ];
    final c = colors[_passwordStrength];
    return Row(
      children: [
        ...List.generate(
          3,
          (i) => Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: i < _passwordStrength ? c : Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          labels[_passwordStrength],
          style: TextStyle(
            color: c,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  int _calculateAge(DateTime birth) {
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) age--;
    return age;
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kPitchGreen,
            onPrimary: Colors.black,
            surface: kElevatedCard,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  void initState() {
    super.initState();
    _loadPendingReferralCode();
    _emailController.addListener(() {
      final email = _emailController.text.trim();
      setState(() {
        if (email.isEmpty || _emailRegex.hasMatch(email)) {
          _emailError = null;
        } else {
          _emailError = 'Geçerli bir e-posta adresi girin';
        }
      });
    });
    _passwordController.addListener(() {
      setState(() {
        _passwordStrength = _getPasswordStrength(_passwordController.text);
      });
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_submitting) return;
    final l = L10nScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // 🛡️ GİZLİLİK POLİTİKASI KONTROLÜ
    if (!_acceptedPrivacyPolicy) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lütfen devam etmek için Gizlilik Politikasını kabul edin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pwd = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^[0-9]+$');

    if (fullName.isEmpty || email.isEmpty || phone.isEmpty || pwd.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.pleaseFillFields),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir e-posta adresi giriniz.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (!phoneRegex.hasMatch(phone) || phone.length != 10 || !phone.startsWith('5')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Telefon numarası 5 ile başlamalı ve 10 haneli olmalıdır. Örn: 5454117205'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_birthDate == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lütfen doğum tarihinizi seçin.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (pwd != confirm) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.passwordMismatch),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final manualReferral = _referralCodeController.text.trim();
      final pendingReferral = await DeepLinkService.consumePendingInvite();
      final referralCode = manualReferral.isNotEmpty
          ? manualReferral
          : pendingReferral;
      await BackendApi.register(
        fullName: fullName,
        email: email,
        password: pwd,
        role: _selectedRole,
        phoneNumber: phone,
        birthDate: _birthDate!.toIso8601String(),
        age: _calculateAge(_birthDate!),
        referralCode:
            _selectedRole == 'Scout' ? referralCode : null,
      );
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: email,
            password: pwd,
            isSocialLogin: false,
            autoResendOnLoad: false,
            onVerificationComplete: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.errorGeneric(e)), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Sosyal medya ile giriş/kayıt işleyici - Gizlilik Politikası Korumalı
  Future<void> _handleSocialLogin(String provider) async {
    final messenger = ScaffoldMessenger.of(context);
    
    // 🛡️ GİZLİLİK POLİTİKASI KONTROLÜ
    if (!_acceptedPrivacyPolicy) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lütfen devam etmek için Gizlilik Politikasını kabul edin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    setState(() => _submitting = true);

    try {
      if (provider == 'google') {
        final googleSignIn = GoogleSignIn(
          clientId: '205838843244-fvd7tqaq952gj7nmi7ffga5243chlilf.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => _submitting = false);
          return;
        }

        final email = googleUser.email;
        final fullName = googleUser.displayName ?? email.split('@').first;
        final providerId = googleUser.id;

        if (!mounted) return;

        final result = await BackendApi.socialLogin(
          provider: 'google',
          email: email,
          fullName: fullName,
          providerId: providerId,
        );

        debugPrint('[SOCIAL LOGIN] status=${result.status}, hasSession=${result.session != null}');

        if (!mounted) return;

        if (result.isComplete && result.session != null) {
          await SessionStore.save(result.session!);
          debugPrint('[REGISTER SOCIAL] Setting currentUserNotifier, isVerified=${result.session!.user.isVerified}');
          currentAccessTokenNotifier.value = result.session!.accessToken;
          currentUserNotifier.value = result.session!.user;
          // Stack'i tamamen temizle → SessionRouter → MainScreen
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SessionRouter()),
              (route) => false,
            );
          }
        } else if (result.isIncomplete) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                email: email,
                fullName: fullName,
                provider: 'google',
                providerId: providerId,
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Sunucudan beklenmeyen bir yanıt geldi.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else if (provider == 'apple') {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final appleProviderId = credential.userIdentifier?.trim() ?? '';
        if (appleProviderId.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Apple kimliği alınamadı. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        final appleEmail = SocialAuthHelper.resolveAppleEmailForApi(credential);
        final appleFullName = SocialAuthHelper.resolveAppleFullName(credential);

        if (!mounted) return;

        final result = await BackendApi.socialLogin(
          provider: 'apple',
          email: appleEmail,
          fullName: appleFullName,
          providerId: appleProviderId,
        );

        if (!mounted) return;

        if (result.isComplete && result.session != null) {
          await SessionStore.save(result.session!);
          currentAccessTokenNotifier.value = result.session!.accessToken;
          currentUserNotifier.value = result.session!.user;
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SessionRouter()),
              (route) => false,
            );
          }
        } else if (result.isIncomplete) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                email: result.email ?? appleEmail,
                fullName: result.fullName ?? appleFullName,
                provider: 'apple',
                providerId: appleProviderId,
              ),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Sunucudan beklenmeyen bir yanıt geldi.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[REGISTER SOCIAL] ERROR: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: Colors.white30, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = (width * 0.07).clamp(20.0, 30.0);
    final l = L10nScope.of(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 24),
          children: [
            const Icon(Icons.sports_soccer, color: kPitchGreen, size: 40),
            const SizedBox(height: 16),
            Text(
              l.registerTitle2(_selectedRole),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.registerSubtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),
            AuthTextField(
              controller: _fullNameController,
              hintText: l.fullName,
              keyboardType: TextInputType.name,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kElevatedCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: kPitchGreen.withValues(alpha: 0.16),
                    blurRadius: 18,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: _selectedRole,
                backgroundColor: Colors.transparent,
                thumbColor: kPitchGreen,
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedRole = value);
                },
                children: {
                  'Scout': Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      l.scout,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _selectedRole == 'Scout'
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                  'Futbolcu': Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      l.player,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _selectedRole == 'Futbolcu'
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                },
              ),
            ),
            if (_selectedRole == 'Scout') ...[
              const SizedBox(height: 14),
              AuthTextField(
                controller: _referralCodeController,
                hintText: 'Davet kodu (isteğe bağlı)',
                textCapitalization: TextCapitalization.characters,
                prefixIcon: Icons.card_giftcard_outlined,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Text(
                  'Sizi davet eden scout\'un kodunu girin veya davet linkiyle geldiyseniz otomatik dolar.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            AuthTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
            ),
            if (_emailError != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _emailError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 14),
            AuthTextField(
              controller: _phoneController,
              hintText: l.phoneHint,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_android_rounded,
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: kElevatedCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _birthDate != null ? kPitchGreen.withValues(alpha: 0.6) : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cake_rounded,
                      color: _birthDate != null ? kPitchGreen : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _birthDate != null
                            ? '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}  (${_calculateAge(_birthDate!)} yaş)'
                            : 'Doğum Tarihi *',
                        style: TextStyle(
                          color: _birthDate != null ? Colors.white : Colors.white38,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_month_rounded, color: Colors.white38, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              hintText: l.password,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white70,
                ),
              ),
            ),
            if (_passwordStrength > 0) ...[  
              const SizedBox(height: 8),
              _buildPasswordStrengthBar(),
            ],
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmPasswordController,
              hintText: l.confirmPassword,
              obscureText: _obscureConfirmPassword,
              prefixIcon: Icons.verified_user_outlined,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Gizlilik Politikası Onay Kutusu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedPrivacyPolicy,
                  onChanged: (value) {
                    setState(() => _acceptedPrivacyPolicy = value ?? false);
                  },
                  activeColor: kPitchGreen,
                  checkColor: Colors.black,
                  side: BorderSide(color: Colors.white.withOpacity(0.5)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'Gizlilik Politikasını '),
                            TextSpan(
                              text: 'okudum ve kabul ediyorum',
                              style: TextStyle(
                                color: kPitchGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'veya şununla kaydol',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: FontAwesomeIcons.apple,
                  color: Colors.black,
                  bgColor: Colors.white,
                  onTap: () => _handleSocialLogin('apple'),
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: FontAwesomeIcons.google,
                  color: Colors.black87,
                  bgColor: Colors.white,
                  isOutlined: true,
                  onTap: () => _handleSocialLogin('google'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GlowPrimaryButton(
              label: l.signUp,
              isLoading: _submitting,
              onTap: _acceptedPrivacyPolicy ? () => _submitRegistration() : null,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.haveAccount,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    l.login,
                    style: const TextStyle(
                      color: kPitchGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: kPitchGreen),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kElevatedCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPitchGreen),
        ),
      ),
    );
  }
}

class GlowPrimaryButton extends StatelessWidget {
  const GlowPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style:
            ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: kPitchGreen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledForegroundColor: Colors.black54,
              disabledBackgroundColor: kPitchGreen.withValues(alpha: 0.72),
            ).copyWith(
              shadowColor: WidgetStatePropertyAll(
                kPitchGreen.withValues(alpha: 0.6),
              ),
            ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.black87,
                      strokeWidth: 2.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentUserNotifier.addListener(_onUserChanged);
    _refreshPlayerSessionCount();
  }

  @override
  void dispose() {
    currentUserNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    _refreshPlayerSessionCount();
  }

  Future<void> _refreshPlayerSessionCount() async {
    final user = currentUserNotifier.value;
    if (user?.role != 'Futbolcu') {
      myAnalysisSessionCountNotifier.value = 0;
      return;
    }
    try {
      final mine = await MultiUploadService.listMyAnalyses();
      myAnalysisSessionCountNotifier.value = mine.length;
      homeMergedStatsNotifier.value = buildMergedLatestSixStats(mine);
    } catch (_) {
      myAnalysisSessionCountNotifier.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10nScope.of(context);
    final titles = [l.tabHome, l.tabDiscover, l.tabProfile];

    return ListenableBuilder(
      listenable: currentUserNotifier,
      builder: (context, _) {
        final user = currentUserNotifier.value;
        if (user == null) return const SessionRouter();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 28),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: [
                ScoutDashboardScreen(
                  user: user,
                  onOpenExplore: () => setState(() => _currentIndex = 1),
                ),
                const ExploreScreen(),
                const ClubProfileScreen(),
              ][_currentIndex],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: kScaffoldDark,
            selectedItemColor: kPitchGreen,
            unselectedItemColor: Colors.white60,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.space_dashboard_outlined),
                activeIcon: const Icon(Icons.space_dashboard),
                label: l.tabHome,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.manage_search_outlined),
                activeIcon: const Icon(Icons.manage_search),
                label: l.tabDiscover,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.emoji_events_outlined),
                activeIcon: const Icon(Icons.emoji_events),
                label: l.tabProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScoutDashboardScreen extends StatefulWidget {
  const ScoutDashboardScreen({
    super.key,
    required this.user,
    this.onOpenExplore,
  });

  final AuthenticatedUser user;
  final VoidCallback? onOpenExplore;

  @override
  State<ScoutDashboardScreen> createState() => _ScoutDashboardScreenState();
}

class _HomePlayerQuickActionsRow extends StatelessWidget {
  const _HomePlayerQuickActionsRow({
    required this.horizontal,
    required this.uploadLabel,
    required this.compareLabel,
    required this.exploreLabel,
    required this.onUpload,
    required this.onCompare,
    required this.onExplore,
  });

  final double horizontal;
  final String uploadLabel;
  final String compareLabel;
  final String exploreLabel;
  final VoidCallback onUpload;
  final VoidCallback onCompare;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 12),
      child: Row(
        children: [
          Expanded(
            child: _HomeQuickActionTile(
              icon: Icons.video_library_rounded,
              label: uploadLabel,
              onPressed: onUpload,
              compact: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HomeQuickActionTile(
              icon: Icons.compare_arrows_rounded,
              label: compareLabel,
              onPressed: onCompare,
              compact: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HomeQuickActionTile(
              icon: Icons.manage_search_rounded,
              label: exploreLabel,
              onPressed: onExplore,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeQuickActionsRow extends StatelessWidget {
  const _HomeQuickActionsRow({
    required this.horizontal,
    required this.compareLabel,
    required this.exploreLabel,
    required this.onCompare,
    required this.onExplore,
  });

  final double horizontal;
  final String compareLabel;
  final String exploreLabel;
  final VoidCallback onCompare;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 12),
      child: Row(
        children: [
          Expanded(
            child: _HomeQuickActionTile(
              icon: Icons.compare_arrows_rounded,
              label: compareLabel,
              onPressed: onCompare,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _HomeQuickActionTile(
              icon: Icons.manage_search_rounded,
              label: exploreLabel,
              onPressed: onExplore,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeQuickActionTile extends StatelessWidget {
  const _HomeQuickActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kElevatedCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPitchGreen.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: kPitchGreen, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 12 : 15,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCompareEntryButton extends StatelessWidget {
  const _HomeCompareEntryButton({
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.horizontal,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double horizontal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 8),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: kPitchGreen.withValues(alpha: 0.55)),
          backgroundColor: kElevatedCard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPitchGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                color: kPitchGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

PlayerListItem _playerListItemFromMultiVideo(MultiVideoPlayer p) {
  return PlayerListItem.fromJson({
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
  });
}

class _ScoutDashboardScreenState extends State<ScoutDashboardScreen> {
  Future<List<PlayerListItem>>? _playersFuture;
  PlayerListItem? _compareAnchorPlayer;
  List<PlayerListItem> _myAnalysesForCompare = const [];
  bool _myAnalysesLoading = true;

  @override
  void initState() {
    super.initState();
    _playersFuture = BackendApi.fetchPlayers();
    _loadLatestAnalysis();
    playersRefreshNotifier.addListener(_onPlayersRefreshSignal);
  }

  @override
  void dispose() {
    playersRefreshNotifier.removeListener(_onPlayersRefreshSignal);
    super.dispose();
  }

  void _onPlayersRefreshSignal() {
    if (!mounted) return;
    _reloadPlayers();
  }

  void _reloadPlayers() {
    setState(() {
      _playersFuture = BackendApi.fetchPlayers();
    });
    _loadLatestAnalysis();
  }

  static bool _hasPublicScoutReport(PlayerListItem p) {
    final r = p.aiScoutReport;
    return r != null &&
        r.trim().isNotEmpty &&
        r != 'Rapor oluşturulamadı';
  }

  /// Futbolcu ana sayfa — yalnızca kendi tamamlanmış analiz oturumları.
  List<PlayerListItem> _playerFeaturedCarousel(
    List<PlayerListItem> players,
    int userId,
  ) {
    return players
        .where((p) => p.userId == userId && _hasPublicScoutReport(p))
        .toList()
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
  }

  /// Scout ana sayfa öne çıkanlar.
  List<PlayerListItem> _scoutFeaturedCarousel(
    List<PlayerListItem> players,
    int userId,
  ) {
    return players
        .where((p) => p.userId != userId && _hasPublicScoutReport(p))
        .toList()
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
  }

  Future<void> _openVideoUpload(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiUploadScreen(key: UniqueKey(), forceNew: true),
      ),
    );
    _reloadPlayers();
  }

  HomeMergedStatsLabels _playerStatsLabels(L10n l) {
    return HomeMergedStatsLabels(
      sectionTitle: l.sectionMyStats,
      ratingOverall: l.ratingOverall,
      statPace: l.statPace,
      statShooting: l.statShooting,
      statPassing: l.statPassing,
      statDribbling: l.statDribbling,
      statDefending: l.statDefending,
      statPhysical: l.statPhysical,
      myStatsEmptyHint: l.myStatsEmptyHint,
      shareStats: l.shareStats,
      shareFailed: l.shareFailed,
      appName: AppConstants.appName,
      ovrRise7d: l.homeOvrRise7d,
    );
  }

  /// Tüm analizlerden özellik bazlı en güncel ölçümler → ana sayfa notifier.
  Future<void> _loadLatestAnalysis() async {
    if (mounted) setState(() => _myAnalysesLoading = true);
    try {
      final mine = await MultiUploadService.listMyAnalyses();
      myAnalysisSessionCountNotifier.value = mine.length;
      homeMergedStatsNotifier.value = buildMergedLatestSixStats(mine);

      final completed = mine.where((p) => p.isComplete).toList()
        ..sort((a, b) {
          final da = a.updatedAt ?? a.createdAt ?? '';
          final db = b.updatedAt ?? b.createdAt ?? '';
          return db.compareTo(da);
        });
      final mapped =
          completed.map(_playerListItemFromMultiVideo).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _myAnalysesForCompare = mapped;
        _compareAnchorPlayer = mapped.isNotEmpty ? mapped.first : null;
      });
    } catch (_) {
      homeMergedStatsNotifier.value = null;
      if (!mounted) return;
      setState(() {
        _myAnalysesForCompare = const [];
        _compareAnchorPlayer = null;
      });
    } finally {
      if (mounted) setState(() => _myAnalysesLoading = false);
    }
  }

  void _openPlayerCompareHub(
    BuildContext context,
    List<PlayerListItem> discoverPool,
  ) {
    final pool = <String, PlayerListItem>{};
    for (final p in discoverPool.where(_hasPublicScoutReport)) {
      pool['${p.source}:${p.id}'] = p;
    }
    for (final p in _myAnalysesForCompare) {
      pool['${p.source}:${p.id}'] = p;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerCompareScreen(
          allPlayers: pool.values.toList(),
        ),
      ),
    );
  }

  void _openScoutCompareHub(
    BuildContext context,
    List<PlayerListItem> discoverPool,
  ) {
    final pool = discoverPool.where(_hasPublicScoutReport).toList()
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerCompareScreen(
          allPlayers: pool,
        ),
      ),
    );
  }

  Widget _buildFeaturedCarouselSection({
    required double horizontal,
    required bool playersLoading,
    required bool loadFailed,
    required List<PlayerListItem> carousel,
    required VoidCallback onRetry,
    required String loadHint,
    required String retryLabel,
    required String emptyHint,
  }) {
    if (playersLoading) {
      return ScoutHomeCarouselSkeleton(horizontal: horizontal);
    }
    return SizedBox(
      height: 190,
      child: loadFailed
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loadHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(
                        retryLabel,
                        style: const TextStyle(
                          color: kPitchGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : carousel.isEmpty
          ? Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 22),
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: carousel.length,
              itemBuilder: (context, index) =>
                  CarouselPlayerCard(player: carousel[index]),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = (width * 0.05).clamp(16.0, 24.0);
    final l = L10nScope.of(context);
    final role = widget.user.role;

    return FutureBuilder<List<PlayerListItem>>(
      future: _playersFuture,
      builder: (context, playerSnap) {
        final players =
            playerSnap.connectionState == ConnectionState.done &&
                playerSnap.hasData
            ? playerSnap.data!
            : <PlayerListItem>[];
        final playersLoading =
            playerSnap.connectionState == ConnectionState.waiting;
        final loadFailed = playerSnap.hasError;
        return ValueListenableBuilder<MergedLatestSixStats?>(
          valueListenable: homeMergedStatsNotifier,
          builder: (context, merged, _) {
            final isPlayer = role.toLowerCase() == 'futbolcu';
            final isScout = !isPlayer;
            final carousel = (isPlayer
                    ? _playerFeaturedCarousel(players, widget.user.id)
                    : _scoutFeaturedCarousel(players, widget.user.id))
                .take(12)
                .toList();
            final carouselTitle =
                isPlayer ? l.homeMyAnalyses : l.dashboardPoolPreview;
            final carouselEmptyHint =
                isPlayer ? l.homeMyAnalysesEmpty : l.rosterEmptyHint;
            final mergedForUi = merged ??
                (isPlayer
                    ? const MergedLatestSixStats(sessionCount: 0, overallRating: 0)
                    : null);
            final scoutPool = players.where(_hasPublicScoutReport).toList()
              ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
            const scoutHomePreviewLimit = 5;
            final scoutPreviewPlayers =
                scoutPool.take(scoutHomePreviewLimit).toList();
            final scoutHasMorePlayers =
                scoutPool.length > scoutHomePreviewLimit;

            return SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        8,
                        horizontal,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.welcomeBack(widget.user.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            children: [
                              if (role.toLowerCase() == 'scout')
                                ActionChip(
                                  avatar: const Icon(Icons.favorite_border, size: 18, color: kPitchGreen),
                                  label: Text(l.favorites),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ShortlistScreen(
                                        onOpenPlayer: (player) => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayerDetailScreen(player: player),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ActionChip(
                                avatar: const Icon(Icons.notifications_outlined, size: 18, color: kPitchGreen),
                                label: Text(l.notifications),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isScout)
                    SliverToBoxAdapter(
                      child: _HomeQuickActionsRow(
                        horizontal: horizontal,
                        compareLabel: l.homeQuickCompare,
                        exploreLabel: l.homeQuickExplore,
                        onCompare: () => _openScoutCompareHub(context, players),
                        onExplore: widget.onOpenExplore ?? () {},
                      ),
                    ),
                  if (isPlayer)
                    SliverToBoxAdapter(
                      child: _HomePlayerQuickActionsRow(
                        horizontal: horizontal,
                        uploadLabel: l.homeQuickUpload,
                        compareLabel: l.homeQuickCompare,
                        exploreLabel: l.homeQuickExplore,
                        onUpload: () => _openVideoUpload(context),
                        onCompare: () => _openPlayerCompareHub(context, players),
                        onExplore: widget.onOpenExplore ?? () {},
                      ),
                    ),
                  if (isPlayer)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          4,
                          horizontal,
                          8,
                        ),
                        child: _myAnalysesLoading
                            ? const PlayerHomeMergedStatsSkeleton()
                            : HomeMergedStatsSection(
                                merged: mergedForUi!,
                                labels: _playerStatsLabels(l),
                                playerName: widget.user.displayName,
                              ),
                      ),
                    ),
                  if (!isPlayer) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontal),
                        child: _SectionTitle(
                          title: carouselTitle,
                          trailing: playersLoading
                              ? const SkeletonBone(width: 28, height: 14)
                              : Text(
                                  loadFailed ? '!' : '${carousel.length}',
                                  style: TextStyle(
                                    color: loadFailed
                                        ? Colors.redAccent
                                        : Colors.white.withValues(
                                            alpha: 0.65,
                                          ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildFeaturedCarouselSection(
                        horizontal: horizontal,
                        playersLoading: playersLoading,
                        loadFailed: loadFailed,
                        carousel: carousel,
                        onRetry: _reloadPlayers,
                        loadHint: l.playersLoadHint,
                        retryLabel: l.tapRetryPlayers,
                        emptyHint: carouselEmptyHint,
                      ),
                    ),
                  ],
                  if (isScout &&
                      (playersLoading ||
                          scoutPreviewPlayers.isNotEmpty ||
                          loadFailed))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontal),
                        child: _SectionTitle(
                          title: l.registeredPlayersSection,
                          trailing: playersLoading || !scoutHasMorePlayers
                              ? null
                              : TextButton(
                                  onPressed: widget.onOpenExplore,
                                  child: Text(
                                    l.homeSeeAllInExplore,
                                    style: const TextStyle(
                                      color: kPitchGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  if (isScout && playersLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          10,
                          horizontal,
                          20,
                        ),
                        child: const ScoutHomeListSkeleton(),
                      ),
                    ),
                  if (isPlayer) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          8,
                          horizontal,
                          0,
                        ),
                        child: _SectionTitle(
                          title: carouselTitle,
                          trailing: playersLoading
                              ? const SkeletonBone(width: 28, height: 14)
                              : Text(
                                  '${carousel.length}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: 0.65,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildFeaturedCarouselSection(
                        horizontal: horizontal,
                        playersLoading: playersLoading,
                        loadFailed: loadFailed,
                        carousel: carousel,
                        onRetry: _reloadPlayers,
                        loadHint: l.playersLoadHint,
                        retryLabel: l.tapRetryPlayers,
                        emptyHint: carouselEmptyHint,
                      ),
                    ),
                  ],
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      10,
                      horizontal,
                      28,
                    ),
                    sliver: !isScout
                        ? const SliverToBoxAdapter(child: SizedBox.shrink())
                        : (playersLoading
                            ? const SliverToBoxAdapter(child: SizedBox.shrink())
                            : loadFailed
                            ? SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    l.playersLoadHint,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : scoutPreviewPlayers.isEmpty
                            ? const SliverToBoxAdapter(child: SizedBox.shrink())
                            : SliverList.separated(
                                itemBuilder: (context, index) =>
                                    DashboardPlayerRow(
                                  player: scoutPreviewPlayers[index],
                                ),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemCount: scoutPreviewPlayers.length,
                              )),
                  ),
                  if (isScout &&
                      scoutHasMorePlayers &&
                      scoutPreviewPlayers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          4,
                          horizontal,
                          20,
                        ),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: widget.onOpenExplore,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: kPitchGreen,
                            ),
                            label: Text(
                              l.homeSeeAllInExplore,
                              style: const TextStyle(
                                color: kPitchGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> launchWhatsAppForPlayer(
  BuildContext context,
  PlayerListItem player,
) async {
  final l = L10nScope.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final me = currentUserNotifier.value;
  if (me?.role != 'Scout') {
    messenger?.showSnackBar(SnackBar(content: Text(l.scoutsMayContactPlayers)));
    return;
  }
  final phone = player.phoneNumber?.trim();
  if (phone == null || phone.isEmpty) {
    messenger?.showSnackBar(SnackBar(content: Text(l.noPhoneOnProfile)));
    return;
  }
  try {
    await openWhatsAppConversation(
      phoneRaw: phone,
      prefilledMessage: l.whatsAppDraft(player.name),
    );
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(l.whatsAppOpenFailed)));
  }
}

Future<void> showExplorePlayerSheet(
  BuildContext context,
  PlayerListItem player,
) async {
  final l = L10nScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: kElevatedCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      side: BorderSide(color: kPitchGreen, width: 0.7),
    ),
    builder: (ctx) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          24 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              player.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${l.playerAgeLabel}: ${player.age}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
            Text(
              l.positionLine(player.position),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${l.ratingOverall}: ',
                  style: const TextStyle(
                    color: kPitchGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${player.overallRating}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PlayerProfileV2Card(player: player, showTitle: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerDetailScreen(player: player),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPitchGreen,
                  side: BorderSide(color: kPitchGreen.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'Tam profili gör',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (player.aiScoutReport != null &&
                player.aiScoutReport!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l.scoutNote,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                player.aiScoutReport!,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.black,
                ),
                label: Text(
                  l.contactPlayer,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPitchGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await launchWhatsAppForPlayer(context, player);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Keşfet — kompakt yaş / OVR aralığı (tek satır + ince slider).
class _ExploreCompactRangeRow extends StatelessWidget {
  const _ExploreCompactRangeRow({
    required this.title,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String title;
  final RangeValues values;
  final double min;
  final double max;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final start = values.start.round();
    final end = values.end.round();
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 32,
              child: RangeSlider(
                values: values,
                min: min,
                max: max,
                divisions: (max - min).round(),
                activeColor: kPitchGreen,
                inactiveColor: Colors.white24,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$start–$end',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  String _query = '';
  String _selectedPosition = 'Tum';
  static const double _ageSliderMin = 14;
  static const double _ageSliderMax = 40;
  static const double _ovrSliderMin = 36;
  static const double _ovrSliderMax = 99;

  RangeValues _ageRange = const RangeValues(_ageSliderMin, _ageSliderMax);
  RangeValues _ovrRange = const RangeValues(_ovrSliderMin, _ovrSliderMax);
  bool _rising7d = false;
  bool _filtersExpanded = false;
  int? _catalogPlayerCount;

  static const List<String> _positions = [
    'Tum',
    'Forvet',
    'Orta Saha',
    'Defans',
    'Kaleci',
  ];

  late Future<List<PlayerListItem>> _playersFuture;

  @override
  void initState() {
    super.initState();
    _playersFuture = _fetchAllPlayers();
    _syncCatalogCount();
    playersRefreshNotifier.addListener(_onPlayersRefreshSignal);
  }

  @override
  void dispose() {
    playersRefreshNotifier.removeListener(_onPlayersRefreshSignal);
    _searchController.dispose();
    super.dispose();
  }

  List<PlayerListItem> _discoverReady(List<PlayerListItem> players) {
    return players
        .where(
          (p) =>
              p.aiScoutReport != null &&
              p.aiScoutReport!.trim().isNotEmpty &&
              p.aiScoutReport != 'Rapor oluşturulamadı',
        )
        .toList();
  }

  Future<List<PlayerListItem>> _fetchAllPlayers() async {
    try {
      final ageActive =
          _ageRange.start > _ageSliderMin || _ageRange.end < _ageSliderMax;
      final ovrActive =
          _ovrRange.start > _ovrSliderMin || _ovrRange.end < _ovrSliderMax;

      final players = await BackendApi.fetchPlayersWithFilters(
        position: _selectedPosition == 'Tum' ? null : _selectedPosition,
        minAge: ageActive ? _ageRange.start.round() : null,
        maxAge: ageActive ? _ageRange.end.round() : null,
        minOvr: ovrActive ? _ovrRange.start.round() : null,
        maxOvr: ovrActive ? _ovrRange.end.round() : null,
        city: _selectedCity,
        rising7d: _rising7d,
      );

      return _discoverReady(players);
    } catch (e) {
      debugPrint('Gerçek oyuncular çekilemedi: $e');
      return [];
    }
  }

  Future<void> _syncCatalogCount() async {
    try {
      final players = await BackendApi.fetchPlayersWithFilters();
      if (!mounted) return;
      setState(() => _catalogPlayerCount = _discoverReady(players).length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _catalogPlayerCount = 0);
    }
  }

  bool _hasActiveFilters() {
    return _query.isNotEmpty ||
        _selectedCity != null ||
        _selectedPosition != 'Tum' ||
        _ageRange.start > _ageSliderMin ||
        _ageRange.end < _ageSliderMax ||
        _ovrRange.start > _ovrSliderMin ||
        _ovrRange.end < _ovrSliderMax ||
        _rising7d;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCity = null;
      _selectedPosition = 'Tum';
      _ageRange = const RangeValues(_ageSliderMin, _ageSliderMax);
      _ovrRange = const RangeValues(_ovrSliderMin, _ovrSliderMax);
      _rising7d = false;
    });
    _refresh();
  }

  void _onPlayersRefreshSignal() {
    if (!mounted) return;
    final next = _fetchAllPlayers();
    setState(() {
      _playersFuture = next;
    });
    unawaited(_syncCatalogCount());
  }

  Future<void> _refresh() async {
    final next = _fetchAllPlayers();
    if (!mounted) return;
    setState(() {
      _playersFuture = next;
    });
    await Future.wait([next, _syncCatalogCount()]);
  }

  List<PlayerListItem> _applyFilter(List<PlayerListItem> raw) {
    return raw.where((p) {
      if (_selectedPosition != 'Tum' &&
          p.position.trim() != _selectedPosition) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.position.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = (width * 0.05).clamp(16.0, 24.0);
    final l = L10nScope.of(context);

    return SafeArea(
      child: FutureBuilder<List<PlayerListItem>>(
        future: _playersFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: kPitchGreen),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.playersLoadHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlowPrimaryButton(label: l.tryAgain, onTap: _refresh),
                  ],
                ),
              ),
            );
          }

          final filtered = _applyFilter(snap.data ?? []);
          final filterNoResults =
              _hasActiveFilters() || (_catalogPlayerCount ?? 0) > 0;

          Widget searchBar() => TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              hintText: l.searchHint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
              ),
              prefixIcon: const Icon(Icons.search, color: kPitchGreen),
              filled: true,
              fillColor: kElevatedCard,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kPitchGreen),
              ),
            ),
          );

          Widget expandedFilters() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String?>(
                value: _selectedCity,
                isExpanded: true,
                dropdownColor: kElevatedCard,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.75)),
                decoration: InputDecoration(
                  hintText: 'Şehir seç',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                  prefixIcon: const Icon(Icons.location_city_outlined, color: kPitchGreen),
                  filled: true,
                  fillColor: kElevatedCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kPitchGreen),
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Tüm şehirler',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ),
                  ...TurkishCities.all.map(
                    (city) => DropdownMenuItem<String?>(
                      value: city,
                      child: Text(city),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedCity = value);
                  _refresh();
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _positions
                    .map(
                      (position) => FilterChip(
                        selected: _selectedPosition == position,
                        onSelected: (_) {
                          setState(() => _selectedPosition = position);
                          _refresh();
                        },
                        label: Text(l.posChip(position)),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: _selectedPosition == position
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: kElevatedCard,
                        selectedColor: kPitchGreen,
                        side: const BorderSide(color: Colors.white12),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                decoration: BoxDecoration(
                  color: kElevatedCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    _ExploreCompactRangeRow(
                      title: 'Yaş',
                      values: _ageRange,
                      min: _ageSliderMin,
                      max: _ageSliderMax,
                      onChanged: (v) => setState(() => _ageRange = v),
                      onChangeEnd: (_) => _refresh(),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    _ExploreCompactRangeRow(
                      title: 'OVR',
                      values: _ovrRange,
                      min: _ovrSliderMin,
                      max: _ovrSliderMax,
                      onChanged: (v) => setState(() => _ovrRange = v),
                      onChangeEnd: (_) => _refresh(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilterChip(
                label: const Text('Son 7 gün yükselen'),
                selected: _rising7d,
                onSelected: (v) {
                  setState(() => _rising7d = v);
                  _refresh();
                },
                labelStyle: TextStyle(
                  color: _rising7d ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: kElevatedCard,
                selectedColor: kPitchGreen,
                checkmarkColor: Colors.black,
                side: const BorderSide(color: Colors.white12),
              ),
            ],
          );

          return RefreshIndicator(
            color: kPitchGreen,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 28),
              children: [
                searchBar(),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _filtersExpanded = !_filtersExpanded),
                  icon: Icon(
                    _filtersExpanded
                        ? Icons.expand_less_rounded
                        : Icons.tune_rounded,
                    size: 20,
                    color: _hasActiveFilters() ? kPitchGreen : Colors.white70,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.exploreFilterTitle,
                        style: TextStyle(
                          color: _hasActiveFilters()
                              ? kPitchGreen
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_hasActiveFilters()) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kPitchGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '•',
                            style: TextStyle(
                              color: kPitchGreen,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: _hasActiveFilters()
                          ? kPitchGreen.withValues(alpha: 0.6)
                          : Colors.white24,
                    ),
                    backgroundColor: kElevatedCard,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                if (_filtersExpanded) ...[
                  const SizedBox(height: 10),
                  expandedFilters(),
                ],
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(
                          filterNoResults
                              ? Icons.filter_alt_off_outlined
                              : Icons.search_off_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          filterNoResults
                              ? l.exploreFilterEmptyHint
                              : l.rosterEmptyHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        if (filterNoResults) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(
                              Icons.clear_all_rounded,
                              color: kPitchGreen,
                              size: 20,
                            ),
                            label: Text(
                              l.clearFilters,
                              style: const TextStyle(
                                color: kPitchGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ...filtered.map(
                    (player) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ExplorePlayerCard(
                        player: player,
                        onOpenSheet: () =>
                            showExplorePlayerSheet(context, player),
                        onQuickContact: () =>
                            launchWhatsAppForPlayer(context, player),
                        risingBadge: player.rising7d,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ExplorePlayerCard extends StatelessWidget {
  const ExplorePlayerCard({
    super.key,
    required this.player,
    required this.onOpenSheet,
    required this.onQuickContact,
    this.risingBadge = false,
  });

  final PlayerListItem player;
  final VoidCallback onOpenSheet;
  final VoidCallback onQuickContact;
  final bool risingBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(player: player),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: kElevatedCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: kPitchGreen.withValues(alpha: 0.05),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'player_name_${player.id}_explore',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              player.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          L10nScope.of(context).yearsOld(player.age),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          L10nScope.of(context).positionLine(player.position),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        if (risingBadge)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kPitchGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Son 7 gün yükselen',
                                style: TextStyle(color: kPitchGreen, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  OvrBadge(ovr: player.scoutInfluencedOvr),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onQuickContact,
                  style:
                      ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: kPitchGreen,
                        elevation: 0,
                        shadowColor: kPitchGreen.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                            color: kPitchGreen,
                            width: 1.2,
                          ),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStatePropertyAll(
                          kPitchGreen.withValues(alpha: 0.12),
                        ),
                      ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        L10nScope.of(context).contactPlayer,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _kvkkExportErrorMessage(Object e) {
  if (e is ApiException) return e.message;
  final raw = e.toString();
  if (raw.contains('sharePositionOrigin')) {
    return 'Paylaşım penceresi açılamadı. Lütfen tekrar deneyin.';
  }
  if (raw.contains('Not Found') || raw.contains('404')) {
    return 'Veri export bu sunucuda henüz yok. Yerel backend veya güncel API kullanın.';
  }
  return 'Veri indirilemedi. Lütfen tekrar deneyin.';
}

Future<void> _profileHandleLogout(BuildContext context) async {
  final l = L10nScope.of(context);
  final bool? shouldLogout = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return CupertinoAlertDialog(
        title: Text(l.logoutTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l.logoutMessage),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.confirm),
          ),
        ],
      );
    },
  );

  if (shouldLogout == true && context.mounted) {
    await SessionStore.clear();
    appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}

void _profileShowDeleteAccountDialog(BuildContext context) {
  final l = L10nScope.of(context);
  showCupertinoDialog(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(l.en ? 'Delete Account?' : 'Hesabı Sil?'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l.en
              ? 'Your account and all data will be permanently deleted. This cannot be undone.'
              : 'Hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l.cancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(dialogContext);

            bool deleted = false;
            String errorMsg = '';

            try {
              await BackendApi.deleteMyAccount();
              deleted = true;
            } catch (e) {
              errorMsg = '$e';
            }

            if (context.mounted) {
              if (deleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Hesabınız ve tüm verileriniz silindi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Hesap silinemedi: $errorMsg'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }

              appNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          child: Text(l.en ? 'Delete Account' : 'Hesabı Sil'),
        ),
      ],
    ),
  );
}

Future<void> _profileExportKvkkData(BuildContext context) async {
  final shareOrigin = ShareHelper.originFor(context);
  try {
    final data = await BackendApi.exportMyData();
    final dir = await getTemporaryDirectory();
    final f = File(
      '${dir.path}/scoutiq_export_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    if (!context.mounted) return;
    await ShareHelper.shareXFiles(
      [XFile(f.path, mimeType: 'application/json')],
      context: context,
      text: 'Scoutiq veri export',
      sharePositionOrigin: shareOrigin,
    );
  } catch (e) {
    if (context.mounted) {
      final msg = _kvkkExportErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2A3448),
        ),
      );
    }
  }
}

class ClubProfileScreen extends StatelessWidget {
  const ClubProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = (width * 0.05).clamp(16.0, 24.0);
    final l = L10nScope.of(context);

    return ListenableBuilder(
      listenable: currentUserNotifier,
      builder: (context, _) {
        final user = currentUserNotifier.value;
        if (user == null) return const SessionRouter();

        return SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 24),
            children: [
              InkWell(
                onTap: () => _openEditProfile(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kElevatedCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      user.profileImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: user.profileImageUrl!.startsWith('http')
                                  ? Image.network(
                                      user.profileImageUrl!,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: kPitchGreen.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.person, color: kPitchGreen),
                                      ),
                                    )
                                  : Image.file(
                                      File(user.profileImageUrl!),
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: kPitchGreen.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.person, color: kPitchGreen),
                                      ),
                                    ),
                            )
                          : Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: kPitchGreen.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.person, color: kPitchGreen),
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                            ),
                            if (user.phoneNumber != null &&
                                user.phoneNumber!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  user.phoneNumber!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: kPitchGreen.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: kPitchGreen.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Text(
                                l.profileSubtitleForRole(user.role),
                                style: const TextStyle(
                                  color: kPitchGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ProfileMenuGroup(
                items: [
                  if (user.role == 'Scout') ...[
                    _ProfileMenuItem(
                      icon: Icons.history_rounded,
                      title: l.analysisHistory,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalysisHistoryScreen(),
                        ),
                      ),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.visibility_rounded,
                      title: l.en ? 'My Watchlist' : 'İzleme Listem',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WatchlistScreen(),
                        ),
                      ),
                    ),
                  ] else ...[
                    _ProfileMenuItem(
                      icon: Icons.bar_chart_rounded,
                      title: l.myStatistics,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyStatisticsScreen(),
                        ),
                      ),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.video_library_rounded,
                      title: l.en ? 'My Videos' : 'Yüklediğim Videolar',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyVideosScreen(),
                        ),
                      ),
                    ),
                  ],
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    title: l.notifications,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.settings_rounded,
                    title: l.settings,
                    onTap: () => _openSettings(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBars.success(message));
  }

  Future<void> _openMyInfo(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyInfoScreen()),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocalSettingsScreen()),
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

}

class LocalSettingsScreen extends StatefulWidget {
  const LocalSettingsScreen({super.key});

  @override
  State<LocalSettingsScreen> createState() => _LocalSettingsScreenState();
}

class _LocalSettingsScreenState extends State<LocalSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _mobileUploadAllowed = false;
  bool _loading = true;
  bool _saving = false;
  bool _testSending = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pushOn = await PushNotificationService.refreshPushPreferenceForSettings();
      if (!mounted) return;

      setState(() {
        _notificationsEnabled = pushOn;
        _mobileUploadAllowed =
            prefs.getBool(AppSettings.mobileUploadKey) ?? false;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = L10n(appLanguageNotifier.value).settingsLoadFailed;
      });
    }
  }

  void _showSettingsSnack(String message, {bool isError = false}) {
    if (!mounted || message.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2A3448),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onNotificationsChanged(bool value) async {
    final l = L10n(appLanguageNotifier.value);
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await PushNotificationService.setNotificationsEnabled(value);
      final actual = await PushNotificationService.loadEffectivePushEnabled();
      if (!mounted) return;
      setState(() => _notificationsEnabled = actual);
      _showSettingsSnack(
        actual ? l.notificationsEnabledSnack : l.notificationsDisabledSnack,
      );
    } catch (e) {
      if (!mounted) return;
      final actual = await PushNotificationService.loadEffectivePushEnabled();
      setState(() => _notificationsEnabled = actual);
      _showSettingsSnack(
        e is StateError
            ? e.message
            : '${l.settingsLoadFailed} ${e is StateError ? e.message : ''}'.trim(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTestNotification() async {
    final l = L10n(appLanguageNotifier.value);
    if (_testSending) return;
    setState(() => _testSending = true);
    try {
      final msg = await PushNotificationService.sendTestNotification();
      if (!mounted) return;
      _showSettingsSnack(msg, isError: msg.contains('kapalı'));
    } catch (e) {
      if (!mounted) return;
      _showSettingsSnack('${l.settingsLoadFailed} $e', isError: true);
    } finally {
      if (mounted) setState(() => _testSending = false);
    }
  }

  Future<void> _onMobileUploadChanged(bool value) async {
    final l = L10n(appLanguageNotifier.value);
    setState(() => _mobileUploadAllowed = value);
    try {
      await AppSettings.setMobileUploadAllowed(value);
      if (!mounted) return;
      _showSettingsSnack(
        value ? l.mobileUploadEnabledSnack : l.mobileUploadDisabledSnack,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _mobileUploadAllowed = !value);
      _showSettingsSnack(l.settingsLoadFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10nScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.settings,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPitchGreen))
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(height: 10),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _loadError = null;
                        });
                        _loadSettings();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPitchGreen,
                        side: const BorderSide(color: kPitchGreen),
                      ),
                      child: Text(l.tryAgain),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _SettingsCard(
                  title: l.notifications,
                  subtitle: l.notificationsSub,
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    activeThumbColor: kPitchGreen,
                    activeTrackColor: kPitchGreen.withValues(alpha: 0.45),
                    onChanged: _saving ? null : _onNotificationsChanged,
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  title: l.testNotification,
                  subtitle: l.testNotificationSub,
                  trailing: _testSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kPitchGreen,
                          ),
                        )
                      : IconButton(
                          onPressed: _sendTestNotification,
                          icon: const Icon(Icons.send_rounded, color: kPitchGreen),
                          tooltip: l.testNotification,
                        ),
                  onTap: _testSending ? null : _sendTestNotification,
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  title: l.mobileDataUpload,
                  subtitle: l.mobileDataUploadSub,
                  trailing: Switch.adaptive(
                    value: _mobileUploadAllowed,
                    activeThumbColor: kPitchGreen,
                    activeTrackColor: kPitchGreen.withValues(alpha: 0.45),
                    onChanged: _onMobileUploadChanged,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l.en ? 'Account' : 'Hesap',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _ProfileMenuGroup(
                  items: [
                    _ProfileMenuItem(
                      icon: Icons.download_rounded,
                      title: l.en
                          ? 'Export My Data (KVKK)'
                          : 'Verilerimi İndir (KVKK)',
                      onTap: () => _profileExportKvkkData(context),
                    ),
                    if ((currentUserNotifier.value?.role ?? '')
                        .toLowerCase() ==
                        'scout')
                      _ProfileMenuItem(
                        icon: Icons.link_rounded,
                        title: l.en ? 'Invite Scouts' : 'Scout Davet Linki',
                        onTap: () async {
                          try {
                            final ref = await BackendApi.fetchReferralLink();
                            final code =
                                '${ref['referral_code'] ?? ''}'.trim();
                            final text =
                                '${ref['share_text'] ?? ref['https_link']}';
                            if (!context.mounted) return;
                            if (code.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                AppSnackBars.success(
                                  'Davet kodunuz: $code',
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                            await ShareHelper.shareText(
                              text,
                              context: context,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Davet linki alınamadı: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    _ProfileMenuItem(
                      icon: Icons.logout_rounded,
                      title: l.logout,
                      isDanger: true,
                      onTap: () => _profileHandleLogout(context),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.delete_forever_rounded,
                      title: l.en ? 'Delete Account' : 'Hesabımı Sil',
                      isDanger: true,
                      onTap: () => _profileShowDeleteAccountDialog(context),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDanger;
}

/// Profil / ayarlar: tek kart içinde bölünmüş menü satırları.
class _ProfileMenuGroup extends StatelessWidget {
  const _ProfileMenuGroup({required this.items});

  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            _ProfileMenuRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.item});

  final _ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isDanger ? Colors.redAccent : kPitchGreen;
    final textColor = item.isDanger ? Colors.redAccent : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(item.icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.45),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarouselPlayerCard extends StatelessWidget {
  const CarouselPlayerCard({super.key, required this.player});

  final PlayerListItem player;

  @override
  Widget build(BuildContext context) {
    final l = L10nScope.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(player: player),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 174,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kElevatedCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Hero(
                    tag: 'player_icon_${player.id}_carousel',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kPitchGreen.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: kPitchGreen,
                        size: 16,
                      ),
                    ),
                  ),
                  OvrBadge(ovr: player.scoutInfluencedOvr),
                ],
              ),
              const SizedBox(height: 14),
              Hero(
                tag: 'player_name_${player.id}_carousel',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${player.position} | ${l.yearsOld(player.age)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                l.ratingOverall,
                style: TextStyle(
                  color: kPitchGreen.withValues(alpha: 0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPlayerRow extends StatelessWidget {
  const DashboardPlayerRow({super.key, required this.player});

  final PlayerListItem player;

  @override
  Widget build(BuildContext context) {
    final l = L10nScope.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(player: player),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kElevatedCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'player_icon_${player.id}_row',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kPitchGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: kPitchGreen,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'player_name_${player.id}_row',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player.position} • ${l.yearsOld(player.age)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              OvrBadge(ovr: player.overallRating),
            ],
          ),
        ),
      ),
    );
  }
}

class OvrBadge extends StatelessWidget {
  const OvrBadge({super.key, required this.ovr});

  final int ovr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kPitchGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$ovr',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class PlayerStat {
  const PlayerStat({
    required this.title,
    required this.value,
    this.icon = Icons.bar_chart_rounded,
  });

  final String title;
  final String value;
  final IconData icon;
}

class PlayerStatTile extends StatelessWidget {
  const PlayerStatTile({super.key, required this.stat});

  final PlayerStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPitchGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              stat.icon,
              color: kPitchGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stat.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPitchGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              stat.value,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisResult {
  const AnalysisResult({
    required this.overall,
    this.pace,
    this.finishing,
    this.passing,
    this.dribbling,
    this.defending,
    this.physical,
    required this.report,
  });

  final int overall;
  final int? pace;
  final int? finishing;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? physical;
  final String report;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    int readInt(List<String> keys, int fallback) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return fallback;
    }

    int? readOptionalInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value > 0 ? value : null;
        if (value is num) {
          final v = value.toInt();
          return v > 0 ? v : null;
        }
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
      return null;
    }

    String readString(List<String> keys, String fallback) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return fallback;
    }

    final reportFallback = L10n(appLanguageNotifier.value).reportNotReady;

    return AnalysisResult(
      overall: readInt(['overall_rating', 'genel_reyting', 'overall', 'ovr'], 0),
      pace: readOptionalInt(['pace', 'hiz', 'speed', 'pac']),
      finishing: readOptionalInt(['finishing', 'bitiricilik', 'sho']),
      passing: readOptionalInt(['passing', 'pas']),
      dribbling: readOptionalInt(['dribbling', 'dri']),
      defending: readOptionalInt(['defending', 'def']),
      physical: readOptionalInt(['strength', 'physical', 'phy']),
      report: readString(['ai_summary_report', 'scout_raporu', 'report'], reportFallback),
    );
  }
}

class VideoUploadBottomSheet extends StatefulWidget {
  const VideoUploadBottomSheet({super.key});

  @override
  State<VideoUploadBottomSheet> createState() => _VideoUploadBottomSheetState();
}

class _VideoUploadBottomSheetState extends State<VideoUploadBottomSheet> {
  static const List<String> _positionKeysTr = [
    'Forvet',
    'Orta Saha',
    'Defans',
    'Kaleci',
  ];

  String selectedPosition = 'Forvet';
  bool isUploading = false;
  late String uploadStatus;

  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    uploadStatus = L10n(appLanguageNotifier.value).uploadReady;
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> pickAndUploadVideo(ImageSource source) async {
    final l = L10n(appLanguageNotifier.value);

    if (source == ImageSource.camera && Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.cameraSimulatorSnack),
          backgroundColor: const Color(0xFF2A3448),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? pickedVideo = await picker.pickVideo(source: source);

    if (pickedVideo != null) {
      // YENI ADIM ADIM ANALIZ AKISI
      final uploader = currentUserNotifier.value;
      final displayName = uploader?.fullName.trim().isNotEmpty == true
          ? uploader!.fullName.trim()
          : 'Futbolcu';
      final parsedAge = int.tryParse(_ageController.text.trim()) ?? 18;

      // Bottom sheet'i kapat ve yeni multi-upload ekranına git
      Navigator.pop(context);
      
      if (!mounted) return;
      
      // YENI GLASSMORPHISM MULTI-UPLOAD EKRANINA YÖNLENDIR
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MultiUploadScreen(forceNew: true),
        ),
      );
      
      return;
      
      // Eski kod (referans için saklandı):
      /*
      setState(() {
        isUploading = true;
        uploadStatus = l.uploadSending;
      });

      try {
        final uri = Uri.parse('$kApiBaseUrl/upload-video/');
        final request = http.MultipartRequest('POST', uri);

        request.fields['name'] = displayName;
        request.fields['age'] = '$parsedAge';
        request.fields['position'] = selectedPosition;
        request.fields['user_id'] = '${uploader?.id ?? 0}';

        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          pickedVideo.path,
        );
        request.files.add(multipartFile);

      */
    }
  }

  void showScoutReport(Map<String, dynamic> data) {
    final parsed = AnalysisResult.fromJson(data);
    final dl = L10n(appLanguageNotifier.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151C2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00FF87), width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.analytics, color: Color(0xFF00FF87)),
            const SizedBox(width: 8),
            Text(
              dl.aiAnalysisTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dl.ratingOverall}: ${parsed.overall}',
              style: const TextStyle(
                color: Color(0xFF00FF87),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dl.scoutNote,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              parsed.report,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              dl.close,
              style: const TextStyle(color: Color(0xFF00FF87), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appLanguageNotifier,
      builder: (context, _) {
        final l = L10nScope.of(context);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.pickPosition,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _positionKeysTr.map((pos) {
                  final isSelected = selectedPosition == pos;
                  return ChoiceChip(
                    label: Text(l.posChip(pos)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00FF87),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: const Color(0xFF0B0F19),
                    onSelected: isUploading
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(() => selectedPosition = pos);
                            }
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _ageController,
                hintText: l.playerAgeLabel,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19),
                  border: Border.all(
                    color: const Color(0xFF00FF87).withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF00FF87)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.instructionForPosition(selectedPosition),
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isUploading)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF00FF87)),
                      const SizedBox(height: 16),
                      Text(
                        uploadStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              pickAndUploadVideo(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF87),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            l.camera,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              pickAndUploadVideo(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFF00FF87),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            l.gallery,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class MyStatisticsScreen extends StatefulWidget {
  const MyStatisticsScreen({super.key});

  @override
  State<MyStatisticsScreen> createState() => _MyStatisticsScreenState();
}

class _MyStatisticsScreenState extends State<MyStatisticsScreen> with WidgetsBindingObserver {
  List<MultiVideoPlayer> players = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMyPlayers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama foreground'a döndüğünde verileri yenile
    if (state == AppLifecycleState.resumed) {
      _loadMyPlayers();
    }
  }

  Future<void> _loadMyPlayers() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final myPlayers = (await MultiUploadService.listMyAnalyses())
          .where((p) => p.videos.any((v) => v.isUploaded))
          .toList();

      if (mounted) {
        setState(() {
          players = myPlayers;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(appLanguageNotifier.value);
    
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'İstatistiklerim',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.accentGreen),
            onPressed: () {
              setState(() => isLoading = true);
              _loadMyPlayers();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentGreen,
        backgroundColor: AppColors.surface,
        onRefresh: _loadMyPlayers,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
            : players.isEmpty
                ? ListView(children: [SizedBox(height: 200), _buildEmptyState(l)])
                : _buildStatsList(),
      ),
    );
  }

  Widget _buildEmptyState(L10n l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 80, color: AppColors.accentGreen),
          SizedBox(height: 16),
          Text(
            'Henüz video yüklemesi yapmadınız',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MultiUploadScreen()),
              );
            },
            child: Text('Video Yükle'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsList() {
    final completedPlayers = players
        .where((p) =>
            p.isComplete &&
            (p.aiSummaryReport?.isNotEmpty ?? false) &&
            p.aiSummaryReport != 'Rapor oluşturulamadı')
        .toList()
      ..sort((a, b) {
        final da = a.updatedAt ?? a.createdAt ?? '';
        final db = b.updatedAt ?? b.createdAt ?? '';
        final byDate = db.compareTo(da);
        if (byDate != 0) return byDate;
        return b.id.compareTo(a.id);
      });
    final incompletePlayers = players.where((p) => !p.isComplete).toList();

    if (completedPlayers.isEmpty && incompletePlayers.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(16),
        children: [_buildEmptyUploadPrompt()],
      );
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (completedPlayers.isNotEmpty) ...[
          Text(
            'Analiz oturumları',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...completedPlayers.map(_buildSessionChip),
        ],
        ...incompletePlayers.map(_buildPremiumPlayerCard),
      ],
    );
  }

  Widget _buildSessionChip(MultiVideoPlayer player) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Text(
        '${player.position} · OVR ${player.overallRating}',
        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${player.slotBreakdown.length} test',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerStatsScreen(
            player: player,
            onAnalysisComplete: _loadMyPlayers,
          ),
        ),
      ).then((_) => _loadMyPlayers()),
    );
  }

  Widget _buildEmptyUploadPrompt() {
    return Container(
      margin: EdgeInsets.only(top: 60),
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGreen.withOpacity(0.08),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.sports_soccer, size: 64, color: AppColors.accentGreen.withOpacity(0.7)),
          SizedBox(height: 20),
          Text(
            'Henüz analiz yok',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Videolarınızı yükleyip analiz tamamlayın',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MultiUploadScreen()),
            ).then((_) => _loadMyPlayers()),
            icon: Icon(Icons.add),
            label: Text('Video Yükle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // SKOR RENK HESAPLAMA: 80+ Yeşil, 50-79 Turuncu, <50 Kırmızı
  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 50) return AppColors.accentOrange;
    return AppColors.error;
  }

  Widget _buildPremiumPlayerCard(MultiVideoPlayer player) {
    final bool hasAnalysis = player.aiSummaryReport != null &&
        player.aiSummaryReport!.isNotEmpty &&
        player.aiSummaryReport != 'Rapor oluşturulamadı';
    final int overall = player.overallRating;
    final Color scoreColor = hasAnalysis ? _getScoreColor(overall) : Colors.grey;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerStatsScreen(player: player, onAnalysisComplete: _loadMyPlayers),
        ),
      ).then((_) => _loadMyPlayers()),
      child: Container(
        margin: EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scoreColor.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(color: scoreColor.withOpacity(0.12), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── BAŞLIK SATIRI ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  // Pozisyon rozeti
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      player.position,
                      style: TextStyle(color: scoreColor, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          '${player.videos.where((v) => v.isUploaded).length}/3 video · ${player.age} yaş',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Overall dairesel gösterge
                  _buildCircularScore(overall, scoreColor),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ─── 6 METRİK GRID ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _buildSixMetricGrid(player, hasAnalysis),
            ),

            SizedBox(height: 16),

            // ─── AI SCOUT RAPOR KARTI ──────────────────────────────
            _buildScoutReportCard(player, hasAnalysis),

            // ─── ANALİZ BAŞLAT BUTONU (Analiz yoksa) ─────────────────
            if (!hasAnalysis && player.videos.length >= 3)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startAnalysisForPlayer(player),
                    icon: Icon(Icons.auto_awesome, color: Colors.black),
                    label: Text(
                      'AI Analizi Başlat',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Future<void> _startAnalysisForPlayer(MultiVideoPlayer player) async {
    try {
      // Analiz başlat
      final result = await MultiUploadService.finalizePlayer(player.id);

      if (!mounted) return;
      if (!result.success) {
        await showAnalysisFinalizeDialog(
          context: context,
          result: result,
          onRetry: () => _startAnalysisForPlayer(player),
          onAnalysisComplete: _loadMyPlayers,
        );
        return;
      }

      _showNotification('✅ Analiz tamamlandı!', Colors.green);
      _loadMyPlayers();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerStatsScreen(
            player: result.player,
            onAnalysisComplete: _loadMyPlayers,
          ),
        ),
      );
    } catch (e) {
      _showNotification('❌ Analiz başlatılamadı: $e', Colors.red);
    }
  }

  void _showNotification(String message, Color color) {
    // Bildirim ayarı kontrolü
    _shouldShowNotification().then((enabled) {
      if (enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color),
        );
      }
    });
  }

  Future<bool> _shouldShowNotification() async {
    return AppSettings.areNotificationsEnabled();
  }

  Widget _buildCircularScore(int score, Color color) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text('GENEL', style: TextStyle(color: Colors.white38, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSixMetricGrid(MultiVideoPlayer player, bool hasAnalysis) {
    final six = player.fifaSix;
    final metrics = [
      {'label': 'Hız',       'value': six.pace,       'icon': Icons.speed},
      {'label': 'Şut',       'value': six.finishing,  'icon': Icons.sports_soccer},
      {'label': 'Pas',       'value': six.passing,    'icon': Icons.swap_horiz},
      {'label': 'Dripling',  'value': six.dribbling,  'icon': Icons.control_camera},
      {'label': 'Defans',    'value': six.defending,  'icon': Icons.shield_outlined},
      {'label': 'Fizik',     'value': six.strength,   'icon': Icons.fitness_center},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, i) {
        final m = metrics[i];
        final int? raw = hasAnalysis ? m['value'] as int? : null;
        final int val = (raw != null && raw > 0) ? raw : player.overallRating;
        final Color c = _getScoreColor(val);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withOpacity(0.18), c.withOpacity(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withOpacity(0.35), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(m['icon'] as IconData, color: c, size: 18),
              SizedBox(height: 4),
              Text('$val', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 17)),
              Text(
                m['label'] as String,
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoutReportCard(MultiVideoPlayer player, bool hasAnalysis) {
    final report = player.aiSummaryReport;
    final hasReport = hasAnalysis && report != null && report.isNotEmpty;
    final Color accentColor = const Color(0xFF9C6FDE); // purple

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: accentColor, size: 18),
              SizedBox(width: 8),
              Text(
                'AI Scout Değerlendirmesi',
                style: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          SizedBox(height: 10),
          if (!hasReport)
            Row(
              children: [
                Icon(Icons.videocam_off_outlined, color: Colors.white30, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Henüz analiz yapılmadı. Videolarınızı yükleyin.',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              report!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerStatsScreen(player: player, onAnalysisComplete: _loadMyPlayers),
                ),
              ).then((_) => _loadMyPlayers()),
              child: Row(
                children: [
                  Text(
                    'Devamını Gör',
                    style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: accentColor, size: 11),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Eski _buildStatsGrid ve _buildPlayerStatCard kaldırıldı
}

class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({super.key});

  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> {
  List<MultiVideoPlayer> players = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyVideos();
  }

  Future<void> _loadMyVideos() async {
    try {
      final myPlayers = (await MultiUploadService.listMyAnalyses())
          .where((p) => p.videos.any((v) => v.isUploaded))
          .toList();
      
      setState(() {
        players = myPlayers;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Yüklediğim Videolar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
          : players.isEmpty
              ? _buildEmptyState()
              : _buildVideoList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_rounded, size: 80, color: AppColors.accentGreen),
          SizedBox(height: 16),
          Text(
            'Henüz video yüklemediniz',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MultiUploadScreen()),
              );
            },
            child: Text('Video Yükle'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return _buildPlayerVideoCard(player);
      },
    );
  }

  Widget _buildPlayerVideoCard(MultiVideoPlayer player) {
    return GlassmorphismContainer(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  player.position,
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              Text(
                player.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // 3 Video durumu — yüklenmişse tıklayınca oynar
          Row(
            children: player.videos.map((video) {
              final canPlay = video.isUploaded && (video.url ?? '').isNotEmpty;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: canPlay
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                    // 🔑 Key: Benzersiz URL = Flutter bu widget'ı SIFIRDAN oluşturur, recycle etmez
                                    key: ValueKey(video.url!),
                                    videoUrl: video.url!,
                                    title: video.skill ?? 'Slot ${video.slot}',
                                    subtitle: '${player.name} • ${player.position}',
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: canPlay
                              ? AppColors.accentGreen.withValues(alpha: 0.18)
                              : AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: canPlay
                              ? Border.all(
                                  color: AppColors.accentGreen
                                      .withValues(alpha: 0.35),
                                )
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              canPlay
                                  ? Icons.play_circle_fill
                                  : Icons.videocam_off,
                              color: canPlay
                                  ? AppColors.accentGreen
                                  : AppColors.textMuted,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Slot ${video.slot}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (video.isUploaded && video.skill != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                video.skill!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (canPlay) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'İzle',
                                style: TextStyle(
                                  color: AppColors.accentGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (!player.isComplete) ...[
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: player.completionPercentage / 100,
              backgroundColor: AppColors.glassWhite,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            SizedBox(height: 8),
            Text(
              '${player.videos.where((v) => v.isUploaded).length}/3 Video Yüklendi',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  List<MultiVideoPlayer> watchedPlayers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchedPlayers();
  }

  MultiVideoPlayer _playerFromFavorite(PlayerListItem p) {
    return MultiVideoPlayer(
      id: p.id,
      userId: p.userId ?? 0,
      name: p.name,
      age: p.age,
      position: p.position,
      positionCode: '',
      overallRating: p.overallRating,
      averageRating: 0,
      completionPercentage: 100,
      isComplete: true,
      videos: const [],
      skillScores: const {},
      aiStrengths: const [],
      aiImprovements: const [],
    );
  }

  Future<void> _loadWatchedPlayers() async {
    try {
      final myId = currentUserNotifier.value?.id ?? 0;
      final role = (currentUserNotifier.value?.role ?? '').toLowerCase();

      if (role == 'scout') {
        final lists = await BackendApi.fetchMyShortlists();
        final seen = <int>{};
        final favorites = <PlayerListItem>[];
        for (final sl in lists) {
          for (final item in sl.items) {
            final p = item.player;
            if (p != null && seen.add(p.id)) favorites.add(p);
          }
        }
        setState(() {
          watchedPlayers = favorites.map(_playerFromFavorite).toList();
          isLoading = false;
        });
        return;
      }

      final myPlayers = (await MultiUploadService.listMyAnalyses())
          .where((p) => p.isComplete)
          .toList();

      setState(() {
        watchedPlayers = myPlayers;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'İzleme Listem',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : watchedPlayers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: watchedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = watchedPlayers[index];
                    return _buildWatchCard(player);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility_outlined, size: 80, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'İzleme listeniz boş',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            (currentUserNotifier.value?.role ?? '').toLowerCase() == 'scout'
                ? 'Favorilere eklediğiniz oyuncular burada görünür'
                : 'Analizi tamamlanan profilleriniz burada listelenir',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWatchCard(MultiVideoPlayer player) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentBlue.withOpacity(0.3),
                  AppColors.accentBlue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                player.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBlue,
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
                  player.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${player.position} • OVR: ${player.overallRating}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.accentYellow),
                    SizedBox(width: 4),
                    Text(
                      '${player.averageRating.toStringAsFixed(1)} ortalama',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.visibility, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerStatsScreen(player: player),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  List<MultiVideoPlayer> analyzedPlayers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    try {
      final role = (currentUserNotifier.value?.role ?? '').toLowerCase();
      List<MultiVideoPlayer> myCompleted;
      if (role == 'scout') {
        final players = await MultiUploadService.listPlayers();
        myCompleted = players
            .where((p) =>
                p.analysisCompleted ||
                p.isComplete ||
                p.analysisFailed ||
                p.analysisProcessing)
            .toList();
      } else {
        myCompleted = (await MultiUploadService.listMyAnalyses())
            .where((p) => p.isComplete || p.analysisStatus != null)
            .toList();
      }
      myCompleted.sort((a, b) {
        final da = a.updatedAt ?? a.createdAt ?? '';
        final db = b.updatedAt ?? b.createdAt ?? '';
        return db.compareTo(da);
      });

      setState(() {
        analyzedPlayers = myCompleted;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analizler yüklenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10nScope.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.analysisHistory,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : analyzedPlayers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: analyzedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = analyzedPlayers[index];
                    return _buildAnalysisCard(player);
                  },
                ),
    );
  }

  String _formatAnalysisDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _analysisStatusChip(MultiVideoPlayer player) {
    final (label, color) = switch (player.analysisStatus) {
      'completed' => ('Tamamlandı', AppColors.accentGreen),
      'failed' => ('Başarısız', AppColors.error),
      'processing' || 'pending' => ('İşleniyor', AppColors.accentBlue),
      _ when player.isComplete && player.overallRating > 0 =>
        ('Tamamlandı', AppColors.accentGreen),
      _ => ('Hazır', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'Henüz analiz kaydı yok',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Videolarınızı yükleyip analiz tamamlayın',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(MultiVideoPlayer player) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerStatsScreen(player: player),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  player.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                    player.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${player.position} • ${player.age} yaş • OVR: ${player.overallRating}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (player.updatedAt != null) ...[
                    SizedBox(height: 4),
                    Text(
                      _formatAnalysisDate(player.updatedAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _analysisStatusChip(player),
                      if (player.analysisCompleted &&
                          !player.discoverVisible)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Keşfet arşivi',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (player.aiSummaryReport != null) ...[
                    SizedBox(height: 8),
                    Text(
                      player.aiSummaryReport!.substring(
                        0, 
                        player.aiSummaryReport!.length > 60 
                            ? 60 
                            : player.aiSummaryReport!.length
                      ) + '...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
}

class PlayerDetailScreen extends StatefulWidget {
  final PlayerListItem player;
  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  late VideoPlayerController _controller;
  bool _isError = false;
  final GlobalKey _fifaCardKey = GlobalKey();
  late PlayerRatingSummary _ratingSummary;
  late PlayerListItem _player;
  List<PlayerListItem> _comparePool = [];
  bool _isSubmittingRating = false;
  bool _isSharingCard = false;
  List<String> _allVideoUrls = [];
  List<ScoutRating> _scoutRatings = [];
  bool _alreadyRated = false;
  int _ratingCount = 0;
  bool _isInShortlist = false;
  int? _favoriteShortlistId;
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    debugPrint('[CARD] Player: ${_player.name}, ID: ${_player.id}');
    debugPrint('[CARD] Player pac=${_player.pac} sho=${_player.sho} pas=${_player.pas}');
    _ratingSummary = PlayerRatingSummary.fromMultiVideoPlayer(_player);
    debugPrint('[CARD] RatingSummary: pac=${_ratingSummary.pac} sho=${_ratingSummary.sho} pas=${_ratingSummary.pas}');
    // Kullanıcının yüklediği gerçek video URL'sini kullan
    String videoUrl;
    final rawUrl = widget.player.videoUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      if (rawUrl.contains('/static/videos/')) {
        final filename = rawUrl.split('/').last;
        videoUrl = '$kApiBaseUrl/video/$filename';
      } else if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        videoUrl = rawUrl;
      } else if (rawUrl.startsWith('/')) {
        videoUrl = '$kApiBaseUrl$rawUrl';
      } else {
        videoUrl = '$kApiBaseUrl/$rawUrl';
      }
    } else {
      videoUrl = "$kApiBaseUrl/static/deneme_video.mp4";
    }
    debugPrint('[VIDEO] PlayerDetail video URL: $videoUrl');

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize()
          .then((_) {
            setState(() {});
          })
          .catchError((e) {
            setState(() => _isError = true);
          });
    _loadPlayerRatings();
    _loadAllVideoUrls();
    _loadScoutRatings();
    _loadEnrichedDetail();
    _loadShortlistMembership();
  }

  Future<void> _loadShortlistMembership() async {
    final role = (currentUserNotifier.value?.role ?? '').trim().toLowerCase();
    if (role != 'scout') return;
    try {
      final lists = await BackendApi.fetchMyShortlists();
      if (!mounted) return;
      int? listId;
      var inList = false;
      for (final sl in lists) {
        for (final it in sl.items) {
          if (it.playerId == _player.id && it.source == _player.source) {
            inList = true;
            listId = sl.id;
            break;
          }
        }
        if (inList) break;
      }
      setState(() {
        _isInShortlist = inList;
        _favoriteShortlistId = listId;
      });
    } catch (_) {}
  }

  Future<void> _loadEnrichedDetail() async {
    try {
      final detail = await BackendApi.fetchPlayerDetail(_player.id);
      final pool = await BackendApi.fetchPlayers();
      if (!mounted) return;
      setState(() {
        _player = detail.player;
        _comparePool = pool;
        _ratingSummary = detail.rating;
        _alreadyRated = detail.rating.currentUserHasRated;
        _ratingCount = detail.rating.ratingCount;
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final role = (currentUserNotifier.value?.role ?? '').trim().toLowerCase();
    if (role != 'scout' || _favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    final l = L10nScope.of(context);
    try {
      if (_isInShortlist) {
        var listId = _favoriteShortlistId;
        if (listId == null) {
          await _loadShortlistMembership();
          listId = _favoriteShortlistId;
        }
        if (listId == null) return;
        await BackendApi.removeFromShortlist(
          shortlistId: listId,
          playerId: _player.id,
          source: _player.source,
        );
        if (!mounted) return;
        setState(() {
          _isInShortlist = false;
          _favoriteShortlistId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.removedFromFavorites,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2A3448),
          ),
        );
      } else {
        var lists = await BackendApi.fetchMyShortlists();
        if (lists.isEmpty) {
          lists = await BackendApi.fetchMyShortlists();
        }
        if (lists.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favori listesi bulunamadı.')),
          );
          return;
        }
        final listId = lists.first.id;
        await BackendApi.addToShortlist(
          shortlistId: listId,
          playerId: _player.id,
          source: _player.source,
        );
        if (!mounted) return;
        setState(() {
          _isInShortlist = true;
          _favoriteShortlistId = listId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.addedToFavorites,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2A3448),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _loadScoutRatings() async {
    try {
      final res = await ApiClient.get('/players/detail/${_player.id}');
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final rawList = (data['scout_ratings'] as List? ?? []);
      final ratings = rawList.map((r) => ScoutRating.fromJson(Map<String, dynamic>.from(r as Map))).toList();
      final currentUserId = currentUserNotifier.value?.id;
      final myRating = currentUserId != null
          ? rawList.any((r) => (r as Map)['reviewer_id'] == currentUserId || (r as Map)['is_mine'] == true)
          : false;
      if (mounted) {
        setState(() {
          _scoutRatings = ratings;
          _alreadyRated = myRating;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAllVideoUrls() async {
    try {
      final res = await ApiClient.get('/players/multivideo/${_player.id}');
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final videos = (data['videos'] as List? ?? []);
      final urls = videos
          .where((v) => v['url'] != null && (v['url'] as String).isNotEmpty)
          .map<String>((v) {
            final raw = v['url'] as String;
            return raw.startsWith('http') ? raw : '$kApiBaseUrl$raw';
          })
          .toList();
      if (mounted && urls.isNotEmpty) {
        setState(() => _allVideoUrls = urls);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerRatings() async {
    try {
      final summary = await BackendApi.fetchPlayerRatingSummary(
        _player.id,
      );
      if (!mounted) return;
      setState(() {
        _ratingSummary = PlayerRatingSummary(
          ovr: summary.ovr,
          pac: summary.pac,
          sho: summary.sho,
          pas: summary.pas,
          dri: summary.dri,
          def: summary.def,
          phy: summary.phy,
          profileImageUrl:
              summary.profileImageUrl ?? _player.profileImageUrl,
        );
      });
    } catch (_) {
      // Keep screen functional with existing list values.
    }
  }

  Future<void> _openRateDialog() async {
    final role = (currentUserNotifier.value?.role ?? '').trim().toLowerCase();
    if (role == 'pending_scout') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scout hesabınız henüz onaylanmadı. Puan vermek için admin onayını bekleyin.'),
        ),
      );
      return;
    }
    if (role != 'scout') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sadece onaylı Scout hesapları puan verebilir.'),
        ),
      );
      return;
    }

    int pac = _ratingSummary.pac == 0 ? 60 : _ratingSummary.pac;
    int sho = _ratingSummary.sho == 0 ? 60 : _ratingSummary.sho;
    int pas = _ratingSummary.pas == 0 ? 60 : _ratingSummary.pas;
    int dri = _ratingSummary.dri == 0 ? 60 : _ratingSummary.dri;
    int def = _ratingSummary.def == 0 ? 60 : _ratingSummary.def;
    int phy = _ratingSummary.phy == 0 ? 60 : _ratingSummary.phy;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget buildSlider(
              String label,
              int value,
              ValueChanged<int> onChanged,
            ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$value',
                        style: const TextStyle(
                          color: kPitchGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    min: 1,
                    max: 99,
                    divisions: 98,
                    value: value.toDouble(),
                    activeColor: kPitchGreen,
                    inactiveColor: Colors.white24,
                    label: '$value',
                    onChanged: (v) => onChanged(v.round()),
                  ),
                ],
              );
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Oyuncuyu Puanla',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          if (_isSubmittingRating)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kPitchGreen,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      buildSlider(
                        'PAC (Hiz)',
                        pac,
                        (v) => setSheetState(() => pac = v),
                      ),
                      buildSlider(
                        'SHO (Sut)',
                        sho,
                        (v) => setSheetState(() => sho = v),
                      ),
                      buildSlider(
                        'PAS (Pas)',
                        pas,
                        (v) => setSheetState(() => pas = v),
                      ),
                      buildSlider(
                        'DRI (Dripling)',
                        dri,
                        (v) => setSheetState(() => dri = v),
                      ),
                      buildSlider(
                        'DEF (Defans)',
                        def,
                        (v) => setSheetState(() => def = v),
                      ),
                      buildSlider(
                        'PHY (Fizik)',
                        phy,
                        (v) => setSheetState(() => phy = v),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmittingRating
                              ? null
                              : () async {
                                  setState(() => _isSubmittingRating = true);
                                  try {
                                    final result = await BackendApi.ratePlayer(
                                      playerId: _player.id,
                                      source: _player.source,
                                      payload: PlayerRatingPayload(
                                        pac: pac,
                                        sho: sho,
                                        pas: pas,
                                        dri: dri,
                                        def: def,
                                        phy: phy,
                                      ),
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      _ratingSummary = PlayerRatingSummary(
                                        ovr: result.ovr,
                                        pac: result.pac,
                                        sho: result.sho,
                                        pas: result.pas,
                                        dri: result.dri,
                                        def: result.def,
                                        phy: result.phy,
                                        profileImageUrl:
                                            result.profileImageUrl ??
                                            _ratingSummary.profileImageUrl,
                                      );
                                      _alreadyRated = true;
                                    });
                                    // Scout ratings listesini yenile
                                    _loadScoutRatings();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text('✅ Puanlama kaydedildi!'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    final isAlreadyRated = e.toString().contains('409') || e.toString().contains('zaten');
                                    if (isAlreadyRated) setState(() => _alreadyRated = true);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        backgroundColor: isAlreadyRated ? Colors.orange : Colors.red,
                                        content: Text(isAlreadyRated
                                            ? '⚠️ Bu oyuncuya zaten puan verdiniz.'
                                            : 'Puan kaydedilemedi: $e'),
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () => _isSubmittingRating = false,
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPitchGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScoutEvaluationCard(PlayerListItem p) {
    final report = (p.aiScoutReport ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_outlined, color: kPitchGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI Scout Notu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            L10nScope.of(context).scoutNote,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.isNotEmpty ? report : L10nScope.of(context).reportNotReady,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFifaCard() async {
    if (_isSharingCard) return;
    setState(() => _isSharingCard = true);
    try {
      final boundary =
          _fifaCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Kart görüntüsü hazır değil.');
      }
      final pixelRatio = MediaQuery.of(context).devicePixelRatio * 2;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Kart görüntüsü oluşturulamadı.');
      }
      final rawBytes = byteData.buffer.asUint8List();
      final watermarked = await FifaShareImage.addWatermark(rawBytes);
      if (!mounted) return;

      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: kElevatedCard,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.crop_square, color: kPitchGreen),
                title: const Text('Kare paylaş (Instagram / WhatsApp)'),
                onTap: () => Navigator.pop(ctx, 'square'),
              ),
              ListTile(
                leading: const Icon(Icons.phone_iphone, color: kPitchGreen),
                title: const Text('Story formatı (9:16)'),
                onTap: () => Navigator.pop(ctx, 'story'),
              ),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      Uint8List shareBytes = watermarked;
      if (choice == 'story') {
        shareBytes = await FifaShareImage.toStoryFormat(watermarked);
      }
      final file = File('${dir.path}/fifa_share_${_player.id}_$ts.png');
      await file.writeAsBytes(shareBytes);

      final screenSize = MediaQuery.of(context).size;
      final shareOrigin = Rect.fromCenter(
        center: Offset(screenSize.width / 2, screenSize.height / 2),
        width: 100,
        height: 100,
      );
      final deepLink = 'yetenekavcisi://player/${_player.id}';

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '${_player.name} · Scoutiq\n$deepLink',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Paylaşım başarısız: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSharingCard = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _player;
    final isScout =
        (currentUserNotifier.value?.role ?? '').trim().toLowerCase() == 'scout';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerCompareScreen(
                  playerA: p,
                  allPlayers: _comparePool,
                ),
              ),
            ),
          ),
          if (isScout)
            IconButton(
              icon: Icon(
                _isInShortlist ? Icons.favorite : Icons.favorite_border,
                color: _isInShortlist ? kPitchGreen : Colors.white70,
              ),
              tooltip: _isInShortlist
                  ? L10nScope.of(context).removeFromFavorites
                  : L10nScope.of(context).addToFavorites,
              onPressed: _favoriteBusy ? null : _toggleFavorite,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isScout) ...[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
              onPressed: _isSubmittingRating ? null : _openRateDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPitchGreen,
                  side: BorderSide(color: kPitchGreen.withValues(alpha: 0.7)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: Icon(_alreadyRated ? Icons.check_circle_rounded : Icons.star_rate_rounded),
                label: Text(
                  _alreadyRated ? 'Puanı Güncelle' : 'Puan Ver',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (_alreadyRated)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bu oyuncuya daha önce puan verdiniz',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_ratingCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Topluluk puanı: $_ratingCount scout değerlendirmesi',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            ] else
              const SizedBox(height: 4),
            Row(
              children: [
                Hero(
                  tag: 'player_icon_${p.id}_row',
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: kPitchGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      color: kPitchGreen,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'player_name_${p.id}_row',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "${p.position} • ${L10nScope.of(context).yearsOld(p.age)}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                OvrBadge(ovr: p.scoutInfluencedOvr),
              ],
            ),
            const SizedBox(height: 24),
            RepaintBoundary(
              key: _fifaCardKey,
              child: FifaCardWidget(
                player: p,
              ),
            ),
            const SizedBox(height: 10),
            CombinedOvrStrip(
              aiOvr: p.fifaCardOvr,
              displayOvr: p.scoutInfluencedOvr,
              communityOvr: p.communityOvr,
              scoutCount: p.scoutCountForRating,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSharingCard ? null : _shareFifaCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE1306C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSharingCard
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: const Text(
                  "Paylaş",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PlayerProfileV2Section(
              player: p,
              canEdit: currentUserNotifier.value?.id != null &&
                  p.userId != null &&
                  currentUserNotifier.value!.id == p.userId,
              onUpdated: (updated) => setState(() => _player = updated),
            ),
            const SizedBox(height: 16),
            ScoutNotesSection(
              playerId: p.id,
              source: p.source,
              ratings: _scoutRatings.isNotEmpty ? _scoutRatings : p.scoutRatings,
            ),
            const SizedBox(height: 20),
            _buildScoutEvaluationCard(p),
            if (p.source == 'multivideo') ...[
              if (p.slotBreakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                SlotBreakdownCard(breakdown: p.slotBreakdown),
              ],
              const SizedBox(height: 16),
              SmartSummaryCard(playerId: p.id),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                final urls = _allVideoUrls.isNotEmpty
                    ? _allVideoUrls
                    : () {
                        final rawUrl = _player.videoUrl;
                        if (rawUrl == null || rawUrl.isEmpty) return <String>[];
                        final u = rawUrl.startsWith('http') ? rawUrl : '$kApiBaseUrl$rawUrl';
                        return [u];
                      }();
                if (urls.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullscreenMultiVideoPlayer(
                      videoUrls: urls,
                      playerName: _player.name,
                    ),
                  ),
                );
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kPitchGreen.withValues(alpha: 0.3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isError
                      ? const Center(
                          child: Text(
                            "Video yüklenemedi",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : _controller.value.isInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            _VideoControls(controller: _controller),
                          ],
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: kPitchGreen),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GlowPrimaryButton(
              label: L10nScope.of(context).contactPlayer,
              onTap: () => launchWhatsAppForPlayer(context, p),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// === YENİ TEMİZ FIFA KART WIDGET'I ===

class FifaCardWidget extends StatelessWidget {
  const FifaCardWidget({
    super.key,
    required this.player,
  });

  final PlayerListItem player;

  @override
  Widget build(BuildContext context) {
    final cardOvr = player.fifaCardOvr;
    final six = player.fifaSix;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFCE38A), Color(0xFFF38181), Color(0xFFEAFFD0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2A4A), Color(0xFF10172B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cardOvr',
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      player.position.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 108,
                    height: 108,
                    color: Colors.white10,
                    child: (player.profileImageUrl != null && player.profileImageUrl!.trim().isNotEmpty)
                        ? Image.network(
                            player.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.sports_soccer_rounded,
                              color: Color(0xFF00E676),
                              size: 52,
                            ),
                          )
                        : const Icon(
                            Icons.sports_soccer_rounded,
                            color: Color(0xFF00E676),
                            size: 52,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              player.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FifaStatColumn(
                    stats: [
                      ('PAC', six.pace ?? cardOvr),
                      ('SHO', six.finishing ?? cardOvr),
                      ('PAS', six.passing ?? cardOvr),
                    ],
                  ),
                ),
                Container(width: 1, height: 72, color: Colors.white24),
                Expanded(
                  child: _FifaStatColumn(
                    stats: [
                      ('DRI', six.dribbling ?? cardOvr),
                      ('DEF', six.defending ?? cardOvr),
                      ('PHY', six.strength ?? cardOvr),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FifaStatColumn extends StatelessWidget {
  const _FifaStatColumn({required this.stats});

  final List<(String, int)> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stats
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${entry.$2}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// === VIDEO CONTROLS ===

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controller.value.isPlaying
              ? widget.controller.pause()
              : widget.controller.play();
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Icon(
          widget.controller.value.isPlaying
              ? Icons.pause_circle_filled
              : Icons.play_circle_filled,
          color: kPitchGreen.withValues(alpha: 0.8),
          size: 60,
        ),
      ),
    );
  }
}

// ==========================================
// POZISYONA OZEL ADIM ADIM ANALIZ EKRANLARI
// ==========================================

/// Analiz adimlari onizleme ekrani
class AnalysisStepsPreviewScreen extends StatefulWidget {
  final String position;
  final File videoFile;
  final String playerName;
  final int playerAge;

  const AnalysisStepsPreviewScreen({
    super.key,
    required this.position,
    required this.videoFile,
    required this.playerName,
    required this.playerAge,
  });

  @override
  State<AnalysisStepsPreviewScreen> createState() => _AnalysisStepsPreviewScreenState();
}

class _AnalysisStepsPreviewScreenState extends State<AnalysisStepsPreviewScreen> {
  AnalysisStepsResponse? stepsResponse;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAnalysisSteps();
  }

  Future<void> _loadAnalysisSteps() async {
    try {
      final response = await PositionAnalysisService.fetchAnalysisSteps(widget.position);
      setState(() {
        stepsResponse = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(appLanguageNotifier.value);
    
    return Scaffold(
      backgroundColor: kScaffoldDark,
      appBar: AppBar(
        backgroundColor: kScaffoldDark,
        elevation: 0,
        title: Text(
          'Analiz Adimlari',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPitchGreen),
              ),
            )
          : error != null
              ? Center(
                  child: Text(
                    'Hata: $error',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pozisyon ve bilgiler
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kElevatedCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: kPitchGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.position,
                                    style: TextStyle(
                                      color: kPitchGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.timer, color: Colors.white70, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  '${stepsResponse?.estimatedDuration ?? 0} sn',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              widget.playerName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.playerAge} yas',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      Text(
                        'Analiz Asamalari (${stepsResponse?.totalSteps ?? 0} adim)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Adimlar listesi
                      ...(stepsResponse?.steps ?? []).map((step) {
                        return _buildStepCard(step);
                      }).toList(),
                      
                      SizedBox(height: 24),
                      
                      // Baslat butonu
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StepByStepAnalysisScreen(
                                  position: widget.position,
                                  videoFile: widget.videoFile,
                                  playerName: widget.playerName,
                                  playerAge: widget.playerAge,
                                  steps: stepsResponse?.steps ?? [],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPitchGreen,
                            foregroundColor: kScaffoldDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Analizi Baslat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStepCard(AnalysisStep step) {
    final icons = {
      'pace': Icons.speed,
      'finishing': Icons.sports_soccer,
      'dribbling_tight_spaces': Icons.sync_alt,
      'heading': Icons.person,
      'positioning': Icons.place,
      'composure': Icons.psychology,
      'gk_reflexes': Icons.flash_on,
      'gk_diving': Icons.save,
      'gk_handling': Icons.pan_tool,
      'gk_positioning': Icons.center_focus_strong,
      'gk_distribution': Icons.outlined_flag,
      'gk_command_area': Icons.security,
      'gk_1v1': Icons.looks_one,
    };

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kPitchGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPitchGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: TextStyle(
                  color: kPitchGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                  step.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icons[step.focus] ?? Icons.analytics,
            color: kPitchGreen,
            size: 24,
          ),
        ],
      ),
    );
  }
}

/// Adim adim analiz ekrani
class StepByStepAnalysisScreen extends StatefulWidget {
  final String position;
  final File videoFile;
  final String playerName;
  final int playerAge;
  final List<AnalysisStep> steps;

  const StepByStepAnalysisScreen({
    super.key,
    required this.position,
    required this.videoFile,
    required this.playerName,
    required this.playerAge,
    required this.steps,
  });

  @override
  State<StepByStepAnalysisScreen> createState() => _StepByStepAnalysisScreenState();
}

class _StepByStepAnalysisScreenState extends State<StepByStepAnalysisScreen> {
  bool isAnalyzing = true;
  int currentStep = 0;
  PositionSpecificAnalysis? result;
  String? error;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    try {
      final user = currentUserNotifier.value;
      
      final analysis = await PositionAnalysisService.uploadAndAnalyzeStepByStep(
        userId: user?.id ?? 0,
        name: widget.playerName,
        age: widget.playerAge,
        position: widget.position,
        videoFile: widget.videoFile,
        onProgress: (current, total, stepName) {
          setState(() {
            currentStep = current;
          });
        },
      );

      setState(() {
        result = analysis;
        isAnalyzing = false;
      });

      // Sonucu goster
      if (mounted) {
        _showAnalysisResults();
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isAnalyzing = false;
      });
    }
  }

  void _showAnalysisResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PositionSpecificResultScreen(
          analysis: result!,
          playerName: widget.playerName,
          position: widget.position,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldDark,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAnalyzing) ...[
                // Progress indicator
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: widget.steps.isEmpty ? null : currentStep / widget.steps.length,
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(kPitchGreen),
                    backgroundColor: kElevatedCard,
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'AI Analiz Ediyor...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (widget.steps.isNotEmpty && currentStep < widget.steps.length)
                  Text(
                    'Adim ${currentStep + 1}/${widget.steps.length}: ${widget.steps[currentStep].name}',
                    style: TextStyle(
                      color: kPitchGreen,
                      fontSize: 14,
                    ),
                  ),
                SizedBox(height: 24),
                Text(
                  '${widget.playerName} - ${widget.position}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ] else if (error != null) ...[
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Analiz Başarısız',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPitchGreen,
                    foregroundColor: kScaffoldDark,
                  ),
                  child: Text('Geri Don'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pozisyona ozel analiz sonuclari ekrani
class PositionSpecificResultScreen extends StatelessWidget {
  final PositionSpecificAnalysis analysis;
  final String playerName;
  final String position;

  const PositionSpecificResultScreen({
    super.key,
    required this.analysis,
    required this.playerName,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final traits = analysis.getPositionSpecificTraits();
    final l = L10n(appLanguageNotifier.value);
    
    return Scaffold(
      backgroundColor: kScaffoldDark,
      appBar: AppBar(
        backgroundColor: kScaffoldDark,
        elevation: 0,
        title: Text(
          'Analiz Sonuçları',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Genel puan karti
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPitchGreen, kPitchGreen.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    playerName,
                    style: TextStyle(
                      color: kScaffoldDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    position,
                    style: TextStyle(
                      color: kScaffoldDark.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: kScaffoldDark,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${analysis.averageScore}',
                        style: TextStyle(
                          color: kPitchGreen,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'GENEL PUAN',
                    style: TextStyle(
                      color: kScaffoldDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Pozisyona ozel ozellikler
            Text(
              'Pozisyon Ozellikleri',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Ozellikler grid'i
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: traits.length,
              itemBuilder: (context, index) {
                final trait = traits[index];
                final score = (trait['value'] as num?)?.toInt() ?? 0;
                
                return Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kElevatedCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        trait['icon'] as String? ?? '⚽',
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(height: 8),
                      Text(
                        trait['name'] as String? ?? '',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$score',
                        style: TextStyle(
                          color: kPitchGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            SizedBox(height: 24),
            
            // AI Raporu
            if (analysis.aiScoutReport.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kElevatedCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kPitchGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: kPitchGreen,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI Scout Raporu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      analysis.aiScoutReport,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Sadece futbolcu hesabında paylas butonu goster
            if (currentUserNotifier.value?.role == 'Futbolcu') ...[
              SizedBox(height: 24),
              
              // Paylas butonu - GlobalKey ile düzgün konum hesaplama
              ShareButton(
                playerName: playerName,
                position: position,
                analysis: analysis,
                traits: traits,
              ),
            ],
            
            SizedBox(height: 16),
            
            // Ana sayfaya don
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Ana Sayfaya Don'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==========================================
/// PROFİL DÜZENLEME EKRANI
/// Kullanıcı bilgilerini düzenleme
/// ==========================================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _clubController = TextEditingController();
  final _clubHistoryController = TextEditingController();
  String _selectedRole = 'Futbolcu';
  String? _selectedCity;
  String _preferredFoot = 'Sağ';
  int? _playerId;
  File? _profileImage;
  bool _isLoading = false;
  bool _loadingFutbolProfile = false;
  DateTime? _birthDate;

  static const _footOptions = ['Sol', 'Sağ', 'İkisi'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFutbolProfile();
  }

  String _footFromApi(String? value) {
    switch (value) {
      case 'Sol':
        return 'Sol';
      case 'Sag':
        return 'Sağ';
      case 'Ikisi':
        return 'İkisi';
      default:
        return 'Sağ';
    }
  }

  String _footToApi(String value) {
    switch (value) {
      case 'Sol':
        return 'Sol';
      case 'Sağ':
        return 'Sag';
      case 'İkisi':
        return 'Ikisi';
      default:
        return 'Sag';
    }
  }

  Future<void> _loadFutbolProfile() async {
    final user = currentUserNotifier.value;
    if (user?.role != 'Futbolcu') return;

    setState(() => _loadingFutbolProfile = true);
    try {
      final data = await BackendApi.fetchMyMultivideoProfile();
      if (!mounted || data == null) return;

      setState(() {
        _playerId = data['player_id'] as int?;
        _selectedCity = data['city'] as String?;
        final height = data['height_cm'];
        final weight = data['weight_kg'];
        _heightController.text = height == null ? '' : '$height';
        _weightController.text = weight == null ? '' : '$weight';
        _clubController.text = '${data['club_name'] ?? ''}'.trim();
        _clubHistoryController.text = '${data['club_history'] ?? ''}'.trim();
        _preferredFoot = _footFromApi(data['preferred_foot'] as String?);
      });
    } catch (e) {
      debugPrint('Futbol profili yuklenemedi: $e');
    } finally {
      if (mounted) setState(() => _loadingFutbolProfile = false);
    }
  }

  void _loadUserData() {
    final user = currentUserNotifier.value;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phoneNumber ?? '';
      _selectedRole = user.role;
      if (user.birthDate != null) {
        try {
          _birthDate = DateTime.parse(user.birthDate!);
        } catch (_) {}
      }
    }
  }

  int _calculateAge(DateTime birth) {
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) age--;
    return age;
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kPitchGreen,
            onPrimary: Colors.black,
            surface: kElevatedCard,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  // Profil fotoğrafı seç
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Fotoğraf seçme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _clubController.dispose();
    _clubHistoryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Profil fotoğrafı varsa önce Cloudinary'e yükle, URL al
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await BackendApi.uploadProfilePhoto(_profileImage!.path);
      }
      
      final updatedUser = await BackendApi.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: profileImageUrl,
        birthDate: _birthDate?.toIso8601String(),
      );

      final role = currentUserNotifier.value?.role ?? updatedUser.role;
      if (role == 'Futbolcu') {
        final height = int.tryParse(_heightController.text.trim());
        final weight = int.tryParse(_weightController.text.trim());
        final playerData = await BackendApi.updateMyMultivideoProfile({
          'city': _selectedCity,
          'club_name': _clubController.text.trim().isEmpty ? null : _clubController.text.trim(),
          'club_history':
              _clubHistoryController.text.trim().isEmpty ? null : _clubHistoryController.text.trim(),
          'preferred_foot': _footToApi(_preferredFoot),
          'height_cm': height,
          'weight_kg': weight,
        });
        _playerId = playerData['player_id'] as int?;
      }

      // Global state'i güncelle ve kalıcı olarak kaydet
      currentUserNotifier.value = updatedUser;
      final savedToken = currentAccessTokenNotifier.value ?? '';
      await SessionStore.save(AuthSession(accessToken: savedToken, user: updatedUser));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBars.successWithIcon('Profil bilgileriniz güncellendi'),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme başarısız: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUserNotifier.value;

    return Scaffold(
      backgroundColor: kScaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profili Düzenle',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profil Fotoğrafı (Tıklanabilir)
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: _profileImage == null && user?.profileImageUrl == null
                            ? LinearGradient(
                                colors: [
                                  kPitchGreen.withValues(alpha: 0.3),
                                  kPitchGreen.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kPitchGreen.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        image: _profileImage != null
                            ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                            : (user?.profileImageUrl != null
                                ? DecorationImage(
                                    image: user!.profileImageUrl!.startsWith('http')
                                        ? NetworkImage(user.profileImageUrl!)
                                        : FileImage(File(user.profileImageUrl!)),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: _profileImage == null && user?.profileImageUrl == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (user?.fullName ?? '?').substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: kPitchGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: kPitchGreen.withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.camera_alt,
                                size: 24,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                if (user?.role == 'Futbolcu') ...[
                  _buildFutbolProfileSection(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Hesap Bilgileri', Icons.person_outline),
                  const SizedBox(height: 16),
                ],

                _buildAccountFields(),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPitchGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPitchGreen, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFutbolProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sports_soccer, color: kPitchGreen, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Futbol Profili',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_loadingFutbolProfile) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: kPitchGreen),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildCityDropdown(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _heightController,
                label: 'Boy (cm)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _weightController,
                label: 'Kilo (kg)',
                icon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _clubController,
          label: 'Kulüp',
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 20),
        _buildFootDropdown(),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _clubHistoryController,
          label: 'Kulüp geçmişi',
          icon: Icons.history_edu,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şehir',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kElevatedCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String?>(
              value: _selectedCity,
              isExpanded: true,
              dropdownColor: kElevatedCard,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.75)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_city_outlined, color: kPitchGreen),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: 'Şehir seçin',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'Belirtilmedi',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
                ...TurkishCities.all.map(
                  (city) => DropdownMenuItem<String?>(value: city, child: Text(city)),
                ),
              ],
              onChanged: (value) => setState(() => _selectedCity = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFootDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ayak tercihi',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kElevatedCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _preferredFoot,
              isExpanded: true,
              dropdownColor: kElevatedCard,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.75)),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_run_outlined, color: kPitchGreen),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: _footOptions
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _preferredFoot = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountFields() {
    final user = currentUserNotifier.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _fullNameController,
          label: 'Ad Soyad',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ad soyad gereklidir';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildReadOnlyField(
          label: 'E-posta',
          value: user?.email ?? '',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: 'Telefon Numarası',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doğum Tarihi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: kElevatedCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cake_rounded,
                      color: _birthDate != null ? kPitchGreen : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _birthDate != null
                            ? '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}  (${_calculateAge(_birthDate!)} yaş)'
                            : 'Seçmek için tıklayın',
                        style: TextStyle(
                          color: _birthDate != null ? Colors.white : Colors.white38,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_month_rounded, color: Colors.white38, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kElevatedCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: kPitchGreen),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPitchGreen, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: TextFormField(
            initialValue: value,
            readOnly: true,
            enabled: false,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.withValues(alpha: 0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'E-posta adresi değiştirilemez',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mevki (Rol)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kElevatedCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.sports_soccer, color: kPitchGreen),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              dropdownColor: kElevatedCard,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              icon: Icon(Icons.arrow_drop_down, color: kPitchGreen),
              items: ['Futbolcu', 'Scout'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedRole = value!);
              },
            ),
          ),
        ),
      ],
    );
  }
}



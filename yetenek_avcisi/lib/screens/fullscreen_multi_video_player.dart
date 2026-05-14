import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../app_theme.dart';
import '../app_services.dart';

class FullscreenMultiVideoPlayer extends StatefulWidget {
  final List<String> videoUrls;
  final String playerName;

  const FullscreenMultiVideoPlayer({
    Key? key,
    required this.videoUrls,
    required this.playerName,
  }) : super(key: key);

  @override
  State<FullscreenMultiVideoPlayer> createState() => _FullscreenMultiVideoPlayerState();
}

class _FullscreenMultiVideoPlayerState extends State<FullscreenMultiVideoPlayer> {
  VideoPlayerController? _controller;
  int _currentIndex = 0;
  bool _isPlaying = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
    if (widget.videoUrls.isNotEmpty) {
      _initializeAndPlay(widget.videoUrls[_currentIndex]);
    } else {
      _error = "Oynatılacak video bulunamadı.";
    }
  }

  String _resolveUrl(String raw) {
    // /static/videos/ içeren tüm URL'leri /video/ endpoint'ine yönlendir
    if (raw.contains('/static/videos/')) {
      final filename = raw.split('/').last;
      return '$kApiBaseUrl/video/$filename';
    }
    if (raw.startsWith('http')) return raw;
    return '$kApiBaseUrl$raw';
  }

  Future<void> _initializeAndPlay(String rawUrl) async {
    final url = _resolveUrl(rawUrl);
    debugPrint('[VideoPlayer] Initializing URL: $url');
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _controller!.initialize();
      
      // Video bitince diğerine geçmesini dinleyen sistem
      _controller!.addListener(() {
        if (_controller!.value.position >= _controller!.value.duration) {
          _playNextVideo();
        }
      });

      if (mounted) {
        setState(() {});
        _controller!.play();
      }
    } catch (e) {
      debugPrint('[VideoPlayer] HATA url=$url hata=$e');
      if (mounted) setState(() => _error = "Video yüklenirken hata oluştu.");
    }
  }

  // Bu fonksiyonu FullscreenMultiVideoPlayer içindekiyle değiştir:
void _playNextVideo() {
  if (_currentIndex < widget.videoUrls.length - 1) {
    _controller?.dispose(); // Eski kontrolcüyü tamamen öldür
    setState(() {
      _currentIndex++;
      _controller = null; // Yeni video için yer aç
    });
    _initializeAndPlay(widget.videoUrls[_currentIndex]);
  } else {
    // Tüm videolar bittiğinde ekranı kapat
    Navigator.pop(context);
  }
}
  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (_controller != null && _controller!.value.isInitialized) {
            setState(() {
              _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
              _isPlaying = _controller!.value.isPlaying;
            });
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // VİDEO ALANI — tam ekran doldur
            Container(color: Colors.black),
            if (_error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              )
            else if (_controller == null || !_controller!.value.isInitialized)
              Center(child: CircularProgressIndicator(color: AppColors.accentGreen, strokeWidth: 2))
            else
              Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
              ),

            // ÜST GRADIENT + BAŞLIK
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 4,
                  right: 16,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.playerName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_currentIndex + 1} / ${widget.videoUrls.length}",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // DURAKLATILDI İKONU
            if (!_isPlaying && _controller != null && _controller!.value.isInitialized)
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 64),
                ),
              ),

            // ALT GRADIENT + PROGRESS BAR + DOTS
            if (_controller != null && _controller!.value.isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                    top: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Video dots
                      if (widget.videoUrls.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.videoUrls.length, (i) => Container(
                            width: i == _currentIndex ? 20 : 6,
                            height: 6,
                            margin: EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _currentIndex ? AppColors.accentGreen : Colors.white38,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                      SizedBox(height: 8),
                      // Progress bar
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            padding: EdgeInsets.zero,
                            colors: VideoProgressColors(
                              playedColor: AppColors.accentGreen,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
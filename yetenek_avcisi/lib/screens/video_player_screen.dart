import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../app_theme.dart';
import '../app_services.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitle;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.subtitle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  String? _error;

  // 🔴 CACHE BUSTING: URL'ye timestamp ekleyerek her seferinde TAZESİNİ çeker
  String _resolveUrl(String raw) {
    if (raw.contains('/static/videos/')) {
      final filename = raw.split('/').last;
      return '$kApiBaseUrl/video/$filename';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '$kApiBaseUrl$raw';
    return '$kApiBaseUrl/$raw';
  }

  @override
  void initState() {
    super.initState();
    _initializePlayer(widget.videoUrl);
  }

  // 🔴 LİFECYCLE KORUMASI: Video URL'si anlık değişirse eski videoyu durdurup yenisini yükler
  @override
  void didUpdateWidget(covariant VideoPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.pause();
      _controller?.dispose();
      setState(() {
        _initialized = false;
        _error = null;
      });
      _initializePlayer(widget.videoUrl);
    }
  }

  Future<void> _initializePlayer(String rawUrl) async {
    final url = _resolveUrl(rawUrl);
    debugPrint('[VIDEO] Yükleniyor: $url');
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _initialized = true);
        _controller!.play();
        _controller!.setLooping(true);
      }
    } catch (e) {
      debugPrint('[VIDEO HATA] $e');
      if (mounted) {
        setState(() => _error = "Video yüklenirken bir hata oluştu.");
      }
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildPlayer() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 16),
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
        ),
      );
    }

    final c = _controller!;
    return Center(
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 🔴 KEY KULLANIMI: URL değişince Flutter eski widget'ı zorla çöpe atar
            KeyedSubtree(
              key: ValueKey(c.dataSource),
              child: VideoPlayer(c),
            ),
            VideoProgressIndicator(
              c, 
              allowScrubbing: true,
              padding: const EdgeInsets.all(8.0),
              colors: const VideoProgressColors(
                playedColor: AppColors.accentGreen,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Video izleme ekranı tam siyah olmalı
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildPlayer(),
      ),
    );
  }
}
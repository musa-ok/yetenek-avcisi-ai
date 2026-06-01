import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../app_theme.dart';
import '../app_services.dart';

class FullscreenMultiVideoPlayer extends StatefulWidget {
  final List<String> videoUrls;
  final String playerName;

  const FullscreenMultiVideoPlayer({
    super.key,
    required this.videoUrls,
    required this.playerName,
  });

  @override
  State<FullscreenMultiVideoPlayer> createState() =>
      _FullscreenMultiVideoPlayerState();
}

class _FullscreenMultiVideoPlayerState extends State<FullscreenMultiVideoPlayer> {
  VideoPlayerController? _controller;
  int _currentIndex = 0;
  bool _isPlaying = true;
  String? _error;
  bool _switching = false;
  VoidCallback? _videoEndListener;

  bool get _hasMultiple => widget.videoUrls.length > 1;
  bool get _canGoPrevious => _currentIndex > 0;
  bool get _canGoNext => _currentIndex < widget.videoUrls.length - 1;

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
      _loadVideoAt(_currentIndex);
    } else {
      _error = 'Oynatılacak video bulunamadı.';
    }
  }

  String _resolveUrl(String raw) {
    if (raw.contains('/static/videos/')) {
      final filename = raw.split('/').last;
      return '$kApiBaseUrl/video/$filename';
    }
    if (raw.startsWith('http')) return raw;
    return '$kApiBaseUrl$raw';
  }

  void _detachEndListener() {
    if (_controller != null && _videoEndListener != null) {
      _controller!.removeListener(_videoEndListener!);
      _videoEndListener = null;
    }
  }

  Future<void> _loadVideoAt(int index) async {
    if (index < 0 || index >= widget.videoUrls.length) return;

    _detachEndListener();
    await _controller?.pause();
    await _controller?.dispose();

    if (!mounted) return;

    setState(() {
      _currentIndex = index;
      _controller = null;
      _error = null;
      _switching = true;
      _isPlaying = true;
    });

    final url = _resolveUrl(widget.videoUrls[index]);
    debugPrint('[VideoPlayer] Initializing URL: $url');
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await controller.initialize();
      _videoEndListener = () {
        if (!mounted || _controller == null) return;
        final pos = _controller!.value.position;
        final dur = _controller!.value.duration;
        if (dur.inMilliseconds > 0 &&
            pos >= dur - const Duration(milliseconds: 300)) {
          if (_canGoNext) {
            _goToNext();
          }
        }
      };
      controller.addListener(_videoEndListener!);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _switching = false;
      });
      await controller.play();
    } catch (e) {
      debugPrint('[VideoPlayer] HATA url=$url hata=$e');
      if (mounted) {
        setState(() {
          _error = 'Video yüklenirken hata oluştu.';
          _switching = false;
          _controller = null;
        });
      }
    }
  }

  void _goToPrevious() {
    if (!_canGoPrevious || _switching) return;
    _loadVideoAt(_currentIndex - 1);
  }

  void _goToNext() {
    if (!_canGoNext || _switching) return;
    _loadVideoAt(_currentIndex + 1);
  }

  @override
  void dispose() {
    _detachEndListener();
    _controller?.pause();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white : Colors.white38,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
              _isPlaying = _controller!.value.isPlaying;
            });
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            if (_error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (_controller == null ||
                !_controller!.value.isInitialized ||
                _switching)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentGreen,
                  strokeWidth: 2,
                ),
              )
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

            if (_hasMultiple && _error == null)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'Önceki',
                    onTap: _canGoPrevious && !_switching ? _goToPrevious : null,
                  ),
                ),
              ),
            if (_hasMultiple && _error == null)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Sonraki',
                    onTap: _canGoNext && !_switching ? _goToNext : null,
                  ),
                ),
              ),

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
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.videoUrls.length}',
                        style: const TextStyle(
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

            if (!_isPlaying &&
                _controller != null &&
                _controller!.value.isInitialized &&
                !_switching)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 64),
                ),
              ),

            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_switching)
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
                      if (_hasMultiple)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.videoUrls.length,
                            (i) => GestureDetector(
                              onTap: _switching
                                  ? null
                                  : () => _loadVideoAt(i),
                              child: Container(
                                width: i == _currentIndex ? 20 : 6,
                                height: 6,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: i == _currentIndex
                                      ? AppColors.accentGreen
                                      : Colors.white38,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            padding: EdgeInsets.zero,
                            colors: const VideoProgressColors(
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

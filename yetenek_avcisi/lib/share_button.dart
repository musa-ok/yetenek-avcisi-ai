import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// 🛠️ Güvenli Paylaş Butonu - GlobalKey ile düzgün RenderBox hesaplama
class ShareButton extends StatefulWidget {
  final String playerName;
  final String position;
  final dynamic analysis;
  final List<Map<String, dynamic>> traits;

  const ShareButton({
    super.key,
    required this.playerName,
    required this.position,
    required this.analysis,
    required this.traits,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  final GlobalKey _buttonKey = GlobalKey();

  void _handleShare() {
    // 🎯 GlobalKey ile butonun RenderBox'ını al
    final RenderBox? box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? sharePositionOrigin;

    if (box != null && box.hasSize) {
      final size = box.size;
      final position = box.localToGlobal(Offset.zero);
      
      // Ekran sınırları içinde mi kontrol et
      final screenSize = MediaQuery.of(context).size;
      if (size.width > 0 && size.height > 0 &&
          position.dx >= 0 && position.dy >= 0 &&
          position.dx + size.width <= screenSize.width &&
          position.dy + size.height <= screenSize.height) {
        sharePositionOrigin = position & size;
        debugPrint('[SHARE] RenderBox: $sharePositionOrigin');
      } else {
        debugPrint('[SHARE] RenderBox sınırlar dışında, ekran merkezi kullanılacak');
      }
    }

    // Eğer hala null ise, ekranın merkezini kullan
    if (sharePositionOrigin == null) {
      final screenSize = MediaQuery.of(context).size;
      final centerX = screenSize.width / 2;
      final centerY = screenSize.height / 2;
      sharePositionOrigin = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: 100,
        height: 100,
      );
      debugPrint('[SHARE] Ekran merkezi kullanılıyor: $sharePositionOrigin');
    }

    Share.share(
      '${widget.playerName} - ${widget.position} Analizi\n\n'
      'Genel Puan: ${widget.analysis.averageScore}/100\n\n'
      '${widget.traits.map((t) => '${t['name']}: ${t['value']}').join('\n')}',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _buttonKey, // 🔑 GlobalKey burada
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _handleShare,
        icon: const Icon(Icons.share),
        label: const Text('Sonuclari Paylas'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF87),
          foregroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

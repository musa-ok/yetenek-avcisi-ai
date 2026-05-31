import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/multi_upload_service.dart';
import '../screens/player_stats_screen.dart';

/// Analiz hatası: tekrar dene veya kısmi sonuçları gör.
Future<void> showAnalysisFinalizeDialog({
  required BuildContext context,
  required FinalizeAnalysisResult result,
  VoidCallback? onRetry,
  VoidCallback? onAnalysisComplete,
}) async {
  final msg = result.errorMessage ?? 'Analiz tamamlanamadı.';
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(
        (result.errorMessage ?? '').toLowerCase().contains('uyumsuz video')
            ? 'Uyumsuz video'
            : result.partial
                ? 'Kısmi sonuç'
                : 'Analiz başarısız',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        msg,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Kapat'),
        ),
        if (result.partial)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerStatsScreen(
                    player: result.player,
                    onAnalysisComplete: onAnalysisComplete,
                  ),
                ),
              );
            },
            child: const Text('Sonuçları Gör'),
          ),
        if (result.retryable)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRetry?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
      ],
    ),
  );
}

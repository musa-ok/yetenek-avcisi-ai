import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class PlayerDetailPage extends StatelessWidget {
  final String playerId;

  const PlayerDetailPage({
    super.key,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration
    final player = _MockPlayerData(
      id: playerId,
      name: 'Ahmet Yılmaz',
      position: 'Forvet',
      age: 22,
      overallRating: 78,
      pace: 82,
      shooting: 75,
      passing: 70,
      dribbling: 85,
      defending: 45,
      physical: 68,
      aiReport: 'Oyuncu hızlı başlangıçlara sahip, ceza sahası içinde soğuk kanlı. Dar alanda etkili top kontrolü ve 1e1 durumlarında başarılı. Gelişime açık potansiyeli var.',
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage('assets/images/pattern.png'),
                            repeat: ImageRepeat.repeat,
                            opacity: 0.1,
                          ),
                        ),
                      ),
                    ),
                    
                    // Player Info
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            '${player.position} • ${player.age} yaş',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Rating Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Genel Değerlendirme',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AI analiz sonucu',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _getRatingColor(player.overallRating),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: _getRatingColor(player.overallRating).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  player.overallRating.toString(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'PUAN',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Skills Radar Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yetenek Analizi',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                          const SizedBox(height: AppConstants.defaultPadding),
                          
                          // Skill Bars
                          _SkillBar(
                            label: 'Hız (PAC)',
                            value: player.pace,
                            color: AppColors.ratingExcellent,
                          ),
                          
                          const SizedBox(height: AppConstants.defaultPadding),
                          
                          _SkillBar(
                            label: 'Şut (SHO)',
                            value: player.shooting,
                            color: AppColors.ratingGood,
                          ),
                          
                          const SizedBox(height: AppConstants.defaultPadding),
                          
                          _SkillBar(
                            label: 'Pas (PAS)',
                            value: player.passing,
                            color: AppColors.ratingAverage,
                          ),
                          
                          const SizedBox(height: AppConstants.defaultPadding),
                          
                          _SkillBar(
                            label: 'Dripling (DRI)',
                            value: player.dribbling,
                            color: AppColors.ratingExcellent,
                          ),
                          
                          const SizedBox(height: AppConstants.defaultPadding),
                          
                          _SkillBar(
                            label: 'Defans (DEF)',
                            value: player.defending,
                            color: AppColors.ratingPoor,
                          ),
                          
                          const SizedBox(height: AppConstants.defaultPadding),
                          
                          _SkillBar(
                            label: 'Fizik (PHY)',
                            value: player.physical,
                            color: AppColors.ratingAverage,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // AI Report
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.psychology,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Scout Raporu',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppConstants.defaultPadding),
                          
                          Text(
                            player.aiReport,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Rate player
                          },
                          icon: const Icon(Icons.star),
                          label: const Text('Değerlendir'),
                        ),
                      ),
                      
                      const SizedBox(width: AppConstants.defaultPadding),
                      
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Share player
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Paylaş'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 85) return AppColors.ratingExcellent;
    if (rating >= 75) return AppColors.ratingGood;
    if (rating >= 65) return AppColors.ratingAverage;
    if (rating >= 50) return AppColors.ratingPoor;
    return AppColors.ratingVeryPoor;
  }
}

class _SkillBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SkillBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value/99',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 99,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MockPlayerData {
  final String id;
  final String name;
  final String position;
  final int age;
  final int overallRating;
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final String aiReport;

  _MockPlayerData({
    required this.id,
    required this.name,
    required this.position,
    required this.age,
    required this.overallRating,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    required this.aiReport,
  });
}

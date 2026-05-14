import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedPosition = 'Tümü';
  String _selectedSort = 'En Yeni';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyuncular'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Oyuncu ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Filter Chips
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: _selectedPosition,
                        options: ['Tümü', ...AppConstants.positions],
                        onSelected: (value) {
                          setState(() => _selectedPosition = value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: _FilterChip(
                        label: _selectedSort,
                        options: ['En Yeni', 'En İyi', 'En Popüler'],
                        onSelected: (value) {
                          setState(() => _selectedSort = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Players List
          Expanded(
            child: _buildPlayersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new player
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlayersList() {
    // Mock data for demonstration
    final mockPlayers = [
      _PlayerData(
        id: '1',
        name: 'Ahmet Yılmaz',
        position: 'Forvet',
        age: 22,
        overallRating: 78,
        imageUrl: null,
      ),
      _PlayerData(
        id: '2',
        name: 'Mehmet Kaya',
        position: 'Orta Saha',
        age: 20,
        overallRating: 82,
        imageUrl: null,
      ),
      _PlayerData(
        id: '3',
        name: 'Ali Demir',
        position: 'Defans',
        age: 24,
        overallRating: 75,
        imageUrl: null,
      ),
    ];

    if (mockPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz oyuncu bulunmuyor',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni oyuncu eklemek için + butonuna basın',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: mockPlayers.length,
      itemBuilder: (context, index) {
        final player = mockPlayers[index];
        return _PlayerCard(player: player);
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtreler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Position filter
            const Text('Pozisyon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.positions.map((position) {
                final isSelected = _selectedPosition == position;
                return FilterChip(
                  label: Text(position),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedPosition = position);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Sort options
            const Text('Sıralama'),
            const SizedBox(height: 8),
            Column(
              children: ['En Yeni', 'En İyi', 'En Popüler'].map((sort) {
                final isSelected = _selectedSort == sort;
                return RadioListTile<String>(
                  title: Text(sort),
                  value: sort,
                  groupValue: _selectedSort,
                  onChanged: (value) {
                    setState(() => _selectedSort = value!);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final _PlayerData player;

  const _PlayerCard({
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to player detail
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              // Player Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: player.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          player.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 30,
                        color: AppColors.primary,
                      ),
              ),
              
              const SizedBox(width: AppConstants.defaultPadding),
              
              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            player.position,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        Text(
                          '${player.age} yaş',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Overall Rating
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getRatingColor(player.overallRating),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      player.overallRating.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'GENEL',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final List<String> options;
  final Function(String) onSelected;

  const _FilterChip({
    required this.label,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }
}

class _PlayerData {
  final String id;
  final String name;
  final String position;
  final int age;
  final int overallRating;
  final String? imageUrl;

  _PlayerData({
    required this.id,
    required this.name,
    required this.position,
    required this.age,
    required this.overallRating,
    this.imageUrl,
  });
}

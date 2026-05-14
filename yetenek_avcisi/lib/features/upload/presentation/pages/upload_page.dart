import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  
  String _selectedPosition = 'Forvet';
  String? _videoPath;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _videoPath = result.files.single.path!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video seçilemedi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _recordVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.camera);

      if (video != null) {
        setState(() {
          _videoPath = video.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video kaydedilemedi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _uploadAndAnalyze() {
    if (_formKey.currentState!.validate() && _videoPath != null) {
      FocusScope.of(context).unfocus();
      
      setState(() => _isUploading = true);
      
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _uploadProgress = i / 100.0);
            
            if (i == 100) {
              setState(() => _isUploading = false);
              _showAnalysisCompleteDialog();
            }
          }
        });
      }
    } else if (_videoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir video seçin'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAnalysisCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Analiz Tamamlandı!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_nameController.text} isimli oyuncunun analizi başarıyla tamamlandı.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Analiz Sonuçları:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _AnalysisResult(label: 'Hız', value: 82),
            _AnalysisResult(label: 'Bitiricilik', value: 75),
            _AnalysisResult(label: 'Dripling', value: 85),
            _AnalysisResult(label: 'Pozisyon Alma', value: 70),
            const SizedBox(height: 8),
            Text(
              'Genel Puan: 78/100',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.ratingGood,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Yeni Analiz'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Oyuncuyu Gör'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _ageController.clear();
    setState(() {
      _selectedPosition = 'Forvet';
      _videoPath = null;
      _uploadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Yükle ve Analiz Et'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video Selection Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Seç',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      if (_videoPath != null)
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.video_file,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _videoPath!.split('/').last,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() => _videoPath = null);
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Video seçmek için tıklayın',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUploading ? null : _pickVideo,
                              icon: const Icon(Icons.video_library),
                              label: const Text('Galeriden Seç'),
                            ),
                          ),
                          const SizedBox(width: AppConstants.defaultPadding),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : _recordVideo,
                              icon: const Icon(Icons.videocam),
                              label: const Text('Video Çek'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.largePadding),
              
              // Player Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oyuncu Bilgileri',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Oyuncu Adı',
                          hintText: 'Ahmet Yılmaz',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Oyuncu adı gerekli';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Age Field
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Yaş',
                          hintText: '22',
                          prefixIcon: Icon(Icons.cake),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Yaş gerekli';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age < 10 || age > 50) {
                            return 'Geçerli bir yaş girin (10-50)';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Position Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'Pozisyon',
                          prefixIcon: Icon(Icons.sports_soccer),
                        ),
                        items: AppConstants.positions.map((position) {
                          return DropdownMenuItem(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPosition = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.largePadding),
              
              // Upload Progress
              if (_isUploading) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: _uploadProgress,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Video yükleniyor ve analiz ediliyor...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppConstants.largePadding),
              ],
              
              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadAndAnalyze,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(_isUploading ? 'Analiz Ediliyor...' : 'Yükle ve Analiz Et'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisResult extends StatelessWidget {
  final String label;
  final int value;

  const _AnalysisResult({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (value >= 85) color = AppColors.ratingExcellent;
    else if (value >= 75) color = AppColors.ratingGood;
    else if (value >= 65) color = AppColors.ratingAverage;
    else if (value >= 50) color = AppColors.ratingPoor;
    else color = AppColors.ratingVeryPoor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value/99',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yetenek_avcisi/core/constants/turkish_cities.dart';
import 'package:yetenek_avcisi/core/utils/profile_formatters.dart';
import 'package:yetenek_avcisi/app_services.dart';
import 'package:yetenek_avcisi/features/product/product_screens.dart';

const _card = Color(0xFF151C2B);
const _green = Color(0xFF00FF87);

/// Oyuncu profil v2 düzenleme (PATCH /players/multivideo/{id}/profile).
Future<PlayerListItem?> showPlayerProfileEditSheet(
  BuildContext context,
  PlayerListItem player,
) {
  return showModalBottomSheet<PlayerListItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PlayerProfileEditSheet(player: player),
  );
}

class _PlayerProfileEditSheet extends StatefulWidget {
  const _PlayerProfileEditSheet({required this.player});

  final PlayerListItem player;

  @override
  State<_PlayerProfileEditSheet> createState() => _PlayerProfileEditSheetState();
}

class _PlayerProfileEditSheetState extends State<_PlayerProfileEditSheet> {
  late final TextEditingController _club;
  late final TextEditingController _history;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  String? _selectedCity;
  String _foot = 'Sag';
  File? _pickedPhoto;
  String? _existingPhotoUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _selectedCity = p.city;
    _club = TextEditingController(text: p.clubName ?? '');
    _history = TextEditingController(text: p.clubHistory ?? '');
    _height = TextEditingController(text: p.heightCm?.toString() ?? '');
    _weight = TextEditingController(text: p.weightKg?.toString() ?? '');
    _existingPhotoUrl = p.profileImageUrl;
    _foot = footToApi(footFromApi(p.preferredFoot));
  }

  @override
  void dispose() {
    _club.dispose();
    _history.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _pickedPhoto = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
      );
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _green),
              title: const Text('Galeriden seç', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _green),
              title: const Text('Fotoğraf çek', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'city': _selectedCity,
        'club_name': _club.text.trim().isEmpty ? null : _club.text.trim(),
        'club_history': _history.text.trim().isEmpty ? null : _history.text.trim(),
        'preferred_foot': _foot,
      };
      final h = int.tryParse(_height.text.trim());
      final w = int.tryParse(_weight.text.trim());
      body['height_cm'] = h;
      body['weight_kg'] = w;

      if (_pickedPhoto != null) {
        body['profile_image_url'] =
            await BackendApi.uploadProfilePhoto(_pickedPhoto!.path);
      }

      final res = await BackendApi.updateMultivideoProfile(widget.player.id, body);
      if (!mounted) return;
      final updated = PlayerListItem.fromJson(res);
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildPhotoPicker() {
    ImageProvider? preview;
    if (_pickedPhoto != null) {
      preview = FileImage(_pickedPhoto!);
    } else if (_existingPhotoUrl != null && _existingPhotoUrl!.startsWith('http')) {
      preview = NetworkImage(_existingPhotoUrl!);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _showPhotoSourceSheet,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  image: preview == null
                      ? null
                      : DecorationImage(image: preview, fit: BoxFit.cover),
                ),
                child: preview == null
                    ? const Icon(Icons.image_outlined, color: _green, size: 26)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profil fotoğrafı',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pickedPhoto != null || _existingPhotoUrl != null
                          ? 'Değiştirmek için dokunun'
                          : 'Galeri veya kamera',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_a_photo_outlined, color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Futbol Profili',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _selectedCity,
              dropdownColor: _card,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Şehir').copyWith(
                prefixIcon: const Icon(Icons.location_city_outlined, color: _green, size: 22),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Belirtilmedi', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                ),
                ...TurkishCities.all.map(
                  (city) => DropdownMenuItem<String?>(value: city, child: Text(city)),
                ),
              ],
              onChanged: (v) => setState(() => _selectedCity = v),
            ),
            const SizedBox(height: 10),
            _field(_club, 'Kulüp', Icons.shield_outlined),
            _field(_history, 'Kulüp geçmişi', Icons.history_edu, maxLines: 3),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _foot,
              dropdownColor: _card,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Ayak tercihi'),
              items: preferredFootDropdownEntries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.value,
                      child: Text(e.key),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _foot = v ?? 'Sag'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field(_height, 'Boy (cm)', Icons.height)),
                const SizedBox(width: 12),
                Expanded(child: _field(_weight, 'Kilo (kg)', Icons.monitor_weight_outlined)),
              ],
            ),
            _buildPhotoPicker(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration(hint).copyWith(
          prefixIcon: Icon(icon, color: _green, size: 22),
        ),
      ),
    );
  }
}

/// Profil kartı + düzenle butonu.
class PlayerProfileV2Section extends StatelessWidget {
  const PlayerProfileV2Section({
    super.key,
    required this.player,
    required this.canEdit,
    this.onUpdated,
  });

  final PlayerListItem player;
  final bool canEdit;
  final ValueChanged<PlayerListItem>? onUpdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canEdit)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final updated = await showPlayerProfileEditSheet(context, player);
                if (updated != null) onUpdated?.call(updated);
              },
              icon: const Icon(Icons.edit_outlined, size: 18, color: _green),
              label: const Text('Düzenle', style: TextStyle(color: _green)),
            ),
          ),
        PlayerProfileV2Card(player: player),
      ],
    );
  }
}

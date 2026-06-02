import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yetenek_avcisi/core/constants/app_constants.dart';
import 'package:yetenek_avcisi/core/utils/profile_formatters.dart';
import 'package:yetenek_avcisi/app_services.dart';

const _card = Color(0xFF151C2B);
const _green = Color(0xFF00FF87);

class ScoutNotesSection extends StatefulWidget {
  const ScoutNotesSection({
    super.key,
    required this.playerId,
    this.source = 'multivideo',
    this.ratings = const <ScoutRating>[],
  });

  final int playerId;
  final String source;
  final List<ScoutRating> ratings;

  @override
  State<ScoutNotesSection> createState() => _ScoutNotesSectionState();
}

class _ScoutNotesSectionState extends State<ScoutNotesSection> {
  late Future<List<ScoutNoteItem>> _future;
  final _controller = TextEditingController();
  String _visibility = 'private';
  bool _submitting = false;

  bool get _isScout =>
      (currentUserNotifier.value?.role ?? '').trim().toLowerCase() == 'scout';

  @override
  void initState() {
    super.initState();
    _future = BackendApi.fetchPlayerNotes(widget.playerId, source: widget.source);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = BackendApi.fetchPlayerNotes(widget.playerId, source: widget.source);
    });
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isScout) return;
    setState(() => _submitting = true);
    try {
      await BackendApi.createPlayerNote(
        playerId: widget.playerId,
        body: text,
        visibility: _visibility,
        source: widget.source,
      );
      _controller.clear();
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scout Notları',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<ScoutNoteItem>>(
          future: _future,
          builder: (context, snap) {
            final notes = snap.data ?? [];
            if (snap.connectionState == ConnectionState.waiting && notes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator(color: _green)),
              );
            }
            if (notes.isEmpty) {
              return Text(
                'Henüz scout notu yok.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              );
            }
            return Column(
              children: notes
                  .map(
                    (n) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(n.scoutName, style: const TextStyle(color: _green, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              if (n.isMine)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  onPressed: () async {
                                    try {
                                      await BackendApi.deletePlayerNote(n.id);
                                      await _reload();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                    }
                                  },
                                ),
                              Icon(
                                n.visibility == 'public' ? Icons.public : Icons.lock_outline,
                                size: 16,
                                color: Colors.white38,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(n.body, style: const TextStyle(color: Colors.white70, height: 1.4)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Scout Puanları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.ratings.isEmpty)
          Text(
            'Henüz bir scout değerlendirmesi yapılmadı',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          )
        else
          Column(
            children: widget.ratings
                .map(
                  (r) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  r.scoutName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (r.isMine) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _green.withValues(alpha: 0.4)),
                                  ),
                                  child: const Text(
                                    'Sizin puanınız',
                                    style: TextStyle(
                                      color: _green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: _green, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${r.score}',
                                style: const TextStyle(
                                  color: _green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        if (_isScout) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Gizli veya herkese açık scout yorumu yazın...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Gizli'),
                selected: _visibility == 'private',
                onSelected: (_) => setState(() => _visibility = 'private'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Herkese açık'),
                selected: _visibility == 'public',
                onSelected: (_) => setState(() => _visibility = 'public'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.black),
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class ShortlistScreen extends StatefulWidget {
  const ShortlistScreen({super.key, this.onOpenPlayer});

  final void Function(PlayerListItem player)? onOpenPlayer;

  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  late Future<List<ShortlistSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.fetchMyShortlists();
  }

  Future<void> _reload() async {
    setState(() {
      _future = BackendApi.fetchMyShortlists();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: const Text('Favorilerim'),
        backgroundColor: const Color(0xFF0B0F19),
      ),
      body: RefreshIndicator(
        color: _green,
        onRefresh: _reload,
        child: FutureBuilder<List<ShortlistSummary>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _green));
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${snap.error}', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ],
              );
            }
            final lists = snap.data ?? [];
            if (lists.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz favori oyuncu yok',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lists.length,
              itemBuilder: (context, i) {
                final sl = lists[i];
                return Card(
                  color: _card,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    iconColor: _green,
                    collapsedIconColor: Colors.white54,
                    title: Text(sl.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    subtitle: Text('${sl.itemCount} oyuncu', style: const TextStyle(color: Colors.white54)),
                    trailing: IconButton(
                      icon: const Icon(Icons.share, color: _green),
                      onPressed: () {
                        final link = sl.shareUrl ?? '${kApiBaseUrl}/shortlists/share/${sl.shareToken}';
                        Share.share('${AppConstants.appName} favorilerim: $link');
                      },
                    ),
                    children: [
                      if (sl.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Bu listede oyuncu yok',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      else
                        ...sl.items.map((item) {
                          final p = item.player;
                          final label = p?.name ?? 'Oyuncu #${item.playerId}';
                          return ListTile(
                            title: Text(label, style: const TextStyle(color: Colors.white)),
                            subtitle: p != null
                                ? Text('${p.position} · OVR ${p.overallRating}', style: const TextStyle(color: Colors.white54))
                                : null,
                            onTap: p != null ? () => widget.onOpenPlayer?.call(p) : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () async {
                                try {
                                  await BackendApi.removeFromShortlist(
                                    shortlistId: sl.id,
                                    playerId: item.playerId,
                                    source: item.source,
                                  );
                                  await _reload();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendApi.fetchNotifications();
  }

  Future<void> _reload() async {
    setState(() {
      _future = BackendApi.fetchNotifications();
    });
    await _future;
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'rating':
      case 'rating_updated':
        return Icons.star;
      case 'analysis_done':
      case 'shortlist_analysis':
        return Icons.analytics;
      case 'analysis_failed':
        return Icons.error_outline;
      case 'ovr_changed':
        return Icons.trending_up;
      case 'videos_ready':
        return Icons.video_library_outlined;
      case 'quota_exhausted':
      case 'quota_warning':
        return Icons.timer_outlined;
      case 'scout_note':
        return Icons.note_alt_outlined;
      case 'scout_approved':
      case 'scout_document_received':
        return Icons.verified;
      case 'scout_rejected':
        return Icons.cancel_outlined;
      case 'shortlist_added':
        return Icons.bookmark_add_outlined;
      case 'security_password_changed':
      case 'security_new_login':
        return Icons.security;
      case 'admin_pending_scout':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: const Color(0xFF0B0F19),
      ),
      body: RefreshIndicator(
        color: _green,
        onRefresh: _reload,
        child: FutureBuilder<List<AppNotificationItem>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _green));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Bildirim yok', style: TextStyle(color: Colors.white54))),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                return ListTile(
                  leading: Icon(_iconFor(n.kind), color: n.read ? Colors.white38 : _green),
                  title: Text(n.title, style: TextStyle(color: n.read ? Colors.white54 : Colors.white)),
                  subtitle: n.body == null ? null : Text(n.body!, style: const TextStyle(color: Colors.white38)),
                  onTap: () async {
                    if (!n.read) {
                      await BackendApi.markNotificationRead(n.id);
                      _reload();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Profil duzenleme: player_profile_edit_sheet.dart

String formatPreferredFoot(String? foot) {
  switch (foot) {
    case 'Sag':
      return 'Sağ ayak';
    case 'Sol':
      return 'Sol ayak';
    case 'Ikisi':
      return 'İki ayak';
    default:
      return foot?.trim() ?? '';
  }
}

class PlayerProfileV2Card extends StatelessWidget {
  const PlayerProfileV2Card({
    super.key,
    required this.player,
    this.showTitle = true,
  });

  final PlayerListItem player;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final rows = <String, String>{
      if (player.birthDate != null)
        'Doğum': formatBirthDateDisplay(player.birthDate),
      if (player.city != null) 'Şehir': player.city!,
      if (player.clubName != null) 'Kulüp': player.clubName!,
      if (player.preferredFoot != null) 'Ayak': formatPreferredFoot(player.preferredFoot),
      if (player.heightCm != null) 'Boy': '${player.heightCm} cm',
      if (player.weightKg != null) 'Kilo': '${player.weightKg} kg',
    };
    final history = player.clubHistory?.trim();
    final empty = rows.isEmpty && (history == null || history.isEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const Row(
              children: [
                Icon(Icons.sports_soccer, color: _green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Futbol Profili',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (empty)
            Text(
              'Profil bilgisi henüz eklenmedi.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), height: 1.4),
            )
          else ...[
            ...rows.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (history != null && history.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Kulüp geçmişi',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                history,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

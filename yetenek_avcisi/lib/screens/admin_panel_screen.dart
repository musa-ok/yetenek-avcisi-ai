import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../app_services.dart';

/// Admin Panel Screen - Pending Scout Approval Management
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<dynamic> _pendingScouts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingScouts();
  }

  /// Fetch pending scouts from backend
  Future<void> _loadPendingScouts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = currentAccessTokenNotifier.value;
      if (token == null || token.isEmpty) {
        throw Exception("Oturum bulunamadı. Lütfen tekrar giriş yapın.");
      }

      final response = await http.get(
        Uri.parse('$kApiBaseUrl/admin/pending-scouts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _pendingScouts = data;
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        throw Exception("Bu sayfaya erişim yetkiniz yok. Sadece adminler görüntüleyebilir.");
      } else {
        throw Exception("Bekleyen scout listesi alınamadı: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Approve a pending scout
  Future<void> _approveScout(int userId, String userName) async {
    setState(() {
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final token = currentAccessTokenNotifier.value;
      if (token == null || token.isEmpty) {
        throw Exception("Oturum bulunamadı");
      }

      final response = await http.put(
        Uri.parse('$kApiBaseUrl/admin/approve-scout/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _successMessage = "$userName başarıyla onaylandı. ${data['email_sent'] == true ? 'Mail gönderildi.' : ''}";
        });
        // Refresh list
        await _loadPendingScouts();
      } else {
        throw Exception("Onay işlemi başarısız: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Onay hatası: ${e.toString()}";
      });
    }
  }

  /// Open document URL
  Future<void> _openDocument(String? documentUrl) async {
    if (documentUrl == null || documentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belge URL bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final fullUrl = documentUrl.startsWith('http')
        ? documentUrl
        : '$kApiBaseUrl$documentUrl';
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Belge açılamadı: $fullUrl'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPendingScouts,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await SessionStore.clear();
              currentUserNotifier.value = null;
              currentAccessTokenNotifier.value = null;
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            tooltip: 'Çıkış',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPendingScouts,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Status Bar
        if (_successMessage != null)
          Container(
            width: double.infinity,
            color: Colors.green.withOpacity(0.2),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.green, size: 18),
                  onPressed: () => setState(() => _successMessage = null),
                ),
              ],
            ),
          ),

        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Onay Bekleyen Scoutlar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_pendingScouts.length} kullanıcı onay bekliyor',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Scout List
        Expanded(
          child: _pendingScouts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Onay bekleyen scout bulunmuyor',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tüm scoutlar onaylanmış durumda! 🎉',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingScouts.length,
                  itemBuilder: (context, index) {
                    final scout = _pendingScouts[index];
                    return _buildScoutCard(scout);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScoutCard(dynamic scout) {
    final userId = scout['id'] as int;
    final fullName = scout['full_name'] as String? ?? 'İsimsiz';
    final email = scout['email'] as String? ?? 'Email yok';
    final phone = scout['phone_number'] as String? ?? 'Telefon yok';
    final documentUrl = scout['scout_document_url'] as String?;
    final createdAt = scout['created_at'] as String?;
    final referrerName = scout['referrer_name'] as String?;
    final referrerEmail = scout['referrer_email'] as String?;
    final inviteLabel = (referrerName != null && referrerName.trim().isNotEmpty)
        ? referrerName.trim()
        : (referrerEmail != null && referrerEmail.trim().isNotEmpty)
            ? referrerEmail.trim()
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1D2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF00E676),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      if (phone.isNotEmpty && phone != 'Telefon yok')
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.orange,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Onay Bekliyor',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 14,
                  color: inviteLabel != null
                      ? const Color(0xFF00E676)
                      : Colors.white.withOpacity(0.4),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    inviteLabel != null
                        ? 'Davet: $inviteLabel'
                        : 'Davet: Doğrudan kayıt',
                    style: TextStyle(
                      color: inviteLabel != null
                          ? const Color(0xFF00E676)
                          : Colors.white.withOpacity(0.45),
                      fontSize: 13,
                      fontWeight:
                          inviteLabel != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Document Info
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Başvuru: ${_formatDate(createdAt)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                // View Document Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: documentUrl != null
                        ? () => _openDocument(documentUrl)
                        : null,
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('Belgeyi Gör'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.8),
                      side: BorderSide(
                        color: documentUrl != null
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Approve Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveScout(userId, fullName),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}

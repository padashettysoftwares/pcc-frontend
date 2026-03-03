import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class ParentNewsScreen extends StatefulWidget {
  final String studentId;
  const ParentNewsScreen({super.key, required this.studentId});

  @override
  State<ParentNewsScreen> createState() => _ParentNewsScreenState();
}

class _ParentNewsScreenState extends State<ParentNewsScreen> {
  final _api = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.getStudentNotifications(widget.studentId, limit: 30);
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
          _page = 1;
          _hasMore = data.length >= 30;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    try {
      final data = await _api.getStudentNotifications(widget.studentId, page: _page + 1, limit: 30);
      if (mounted) {
        setState(() {
          _notifications.addAll(data);
          _page++;
          _hasMore = data.length >= 30;
        });
      }
    } catch (_) {}
    _loadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).pcc;
    return Scaffold(
      backgroundColor: c.scaffold,
      appBar: AppBar(
        backgroundColor: c.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'News & Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: c.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: c.textSecondary, size: 22),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _buildBody(c),
    );
  }

  Widget _buildBody(PccColorSet c) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7), strokeWidth: 2.5),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 28, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text('Failed to load', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: c.textTertiary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C5CE7)),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.newspaper_rounded, size: 36, color: Color(0xFF6C5CE7)),
            ),
            const SizedBox(height: 20),
            Text('No News Yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(
              'Notifications from your coaching\nwill appear here',
              style: GoogleFonts.inter(fontSize: 14, color: c.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF6C5CE7),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C5CE7))),
            );
          }
          final n = _notifications[i];
          return _buildNotificationCard(n, c, i);
        },
      ),
    );
  }

  Widget _buildNotificationCard(dynamic n, PccColorSet c, int index) {
    final type = n['notification_type'] ?? 'general';
    final sentAt = DateTime.tryParse(n['sent_at'] ?? '');
    final icon = _typeIcon(type);
    final color = _typeColor(type);
    final title = n['title'] ?? 'Notification';
    final body = n['body'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showDetailDialog(title, body, type, sentAt, color, icon),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _typeLabel(type),
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                          ),
                        ),
                        const Spacer(),
                        if (sentAt != null)
                          Text(
                            _formatTime(sentAt),
                            style: GoogleFonts.inter(fontSize: 11, color: c.textTertiary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.inter(fontSize: 13, color: c.textSecondary, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

  void _showDetailDialog(String title, String body, String type, DateTime? sentAt, Color color, IconData icon) {
    final c = Theme.of(context).pcc;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _typeLabel(type),
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                                ),
                              ),
                              if (sentAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(sentAt),
                                  style: GoogleFonts.inter(fontSize: 12, color: c.textTertiary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: c.border, height: 1),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: c.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'fee_reminder': return Icons.currency_rupee_rounded;
      case 'holiday': return Icons.beach_access_rounded;
      case 'paper_published': return Icons.description_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'fee_reminder': return const Color(0xFFF39C12);
      case 'holiday': return const Color(0xFF2ECC71);
      case 'paper_published': return const Color(0xFF8E44AD);
      default: return const Color(0xFF3498DB);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'fee_reminder': return 'FEE REMINDER';
      case 'holiday': return 'HOLIDAY';
      case 'paper_published': return 'NEW PAPER';
      default: return 'ANNOUNCEMENT';
    }
  }
}

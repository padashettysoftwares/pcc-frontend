import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  // General notification
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _targetType = 'all';
  String? _targetClass;
  String _channel = 'both';
  bool _sending = false;

  // Holiday
  final _holidayNameCtrl = TextEditingController();
  final _holidayDescCtrl = TextEditingController();
  DateTime? _holidayDate;

  // History
  List<dynamic> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _holidayNameCtrl.dispose();
    _holidayDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await _api.getNotifications(limit: 50);
      if (mounted) setState(() { _history = data; _loadingHistory = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _sendGeneral() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      _showSnack('Please fill in title and message', Colors.orange);
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await _api.sendNotification(
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
        targetType: _targetType,
        targetClass: _targetClass,
        channel: _channel,
      );
      _showSnack('✅ Sent! Push: ${result['push']?['sent'] ?? 0}, SMS: ${result['sms']?['sent'] ?? 0}', Colors.green);
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _loadHistory();
    } catch (e) {
      _showSnack('❌ Failed: $e', Colors.red);
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _sendFeeReminder() async {
    setState(() => _sending = true);
    try {
      final result = await _api.sendFeeReminder(channel: _channel);
      _showSnack('✅ Fee reminders sent to ${result['studentsWithPendingFees']} students!', Colors.green);
      _loadHistory();
    } catch (e) {
      _showSnack('❌ Failed: $e', Colors.red);
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _sendHoliday() async {
    if (_holidayNameCtrl.text.isEmpty || _holidayDate == null) {
      _showSnack('Please fill holiday name and date', Colors.orange);
      return;
    }
    setState(() => _sending = true);
    try {
      final dateStr = DateFormat('dd MMM yyyy').format(_holidayDate!);
      await _api.sendHolidayNotification(
        holidayName: _holidayNameCtrl.text,
        date: dateStr,
        description: _holidayDescCtrl.text.isNotEmpty ? _holidayDescCtrl.text : null,
        channel: _channel,
      );
      _showSnack('✅ Holiday announcement sent!', Colors.green);
      _holidayNameCtrl.clear();
      _holidayDescCtrl.clear();
      setState(() => _holidayDate = null);
      _loadHistory();
    } catch (e) {
      _showSnack('❌ Failed: $e', Colors.red);
    }
    if (mounted) setState(() => _sending = false);
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).pcc;
    return Scaffold(
      backgroundColor: c.scaffold,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: c.card,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C5CE7),
          unselectedLabelColor: c.textTertiary,
          indicatorColor: const Color(0xFF6C5CE7),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.campaign_rounded, size: 20), text: 'General'),
            Tab(icon: Icon(Icons.currency_rupee_rounded, size: 20), text: 'Fees'),
            Tab(icon: Icon(Icons.beach_access_rounded, size: 20), text: 'Holiday'),
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(c),
          _buildFeeReminderTab(c),
          _buildHolidayTab(c),
          _buildHistoryTab(c),
        ],
      ),
    );
  }

  // ══════════ Channel Selector (reusable) ══════════
  Widget _channelSelector(PccColorSet c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send via', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _channelChip('📱 Push', 'push', c),
              const SizedBox(width: 8),
              _channelChip('💬 SMS', 'sms', c),
              const SizedBox(width: 8),
              _channelChip('📱+💬 Both', 'both', c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _channelChip(String label, String value, PccColorSet c) {
    final selected = _channel == value;
    return GestureDetector(
      onTap: () => setState(() => _channel = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6C5CE7) : c.fieldFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF6C5CE7) : c.fieldBorder),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : c.textSecondary)),
      ),
    );
  }

  // ══════════ General Tab ══════════
  Widget _buildGeneralTab(PccColorSet c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.fieldBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send to', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _targetChip('All Students', 'all', c),
                    const SizedBox(width: 8),
                    _targetChip('By Class', 'class', c),
                  ],
                ),
                if (_targetType == 'class') ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _targetClass,
                    decoration: InputDecoration(
                      hintText: 'Select class',
                      filled: true,
                      fillColor: c.fieldFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.fieldBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5', 'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10', 'Class 11', 'Class 12']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _targetClass = v),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          _channelSelector(c),
          const SizedBox(height: 12),

          // Title
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.inter(color: c.textPrimary),
            decoration: InputDecoration(
              labelText: 'Title',
              prefixIcon: const Icon(Icons.title_rounded),
              filled: true,
              fillColor: c.fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.fieldBorder)),
            ),
          ),
          const SizedBox(height: 12),

          // Body
          TextField(
            controller: _bodyCtrl,
            style: GoogleFonts.inter(color: c.textPrimary),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message',
              prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 60), child: Icon(Icons.message_rounded)),
              filled: true,
              fillColor: c.fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.fieldBorder)),
            ),
          ),
          const SizedBox(height: 16),

          // Send button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendGeneral,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Sending...' : 'Send Notification', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetChip(String label, String value, PccColorSet c) {
    final selected = _targetType == value;
    return GestureDetector(
      onTap: () => setState(() { _targetType = value; if (value == 'all') _targetClass = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6C5CE7) : c.fieldFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF6C5CE7) : c.fieldBorder),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : c.textSecondary)),
      ),
    );
  }

  // ══════════ Fee Reminder Tab ══════════
  Widget _buildFeeReminderTab(PccColorSet c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF39C12), Color(0xFFE74C3C)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(Icons.currency_rupee_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text('Fee Payment Reminder', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Send personalized SMS & push notifications to all parents with pending fees. Each parent gets their specific pending amount.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _channelSelector(c),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : () => _confirmAndSend('Send fee reminders to ALL students with pending fees?', _sendFeeReminder),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF39C12),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Sending...' : 'Send Fee Reminders', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════ Holiday Tab ══════════
  Widget _buildHolidayTab(PccColorSet c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF27AE60)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.beach_access_rounded, size: 40, color: Colors.white),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Holiday Announcement', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Notify all parents about an upcoming holiday', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _holidayNameCtrl,
            style: GoogleFonts.inter(color: c.textPrimary),
            decoration: InputDecoration(
              labelText: 'Holiday Name',
              hintText: 'e.g. Republic Day, Diwali',
              prefixIcon: const Icon(Icons.celebration_rounded),
              filled: true,
              fillColor: c.fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.fieldBorder)),
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _holidayDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: c.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.fieldBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: c.textTertiary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _holidayDate != null ? DateFormat('dd MMMM yyyy (EEEE)').format(_holidayDate!) : 'Select Holiday Date',
                    style: GoogleFonts.inter(fontSize: 14, color: _holidayDate != null ? c.textPrimary : c.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _holidayDescCtrl,
            style: GoogleFonts.inter(color: c.textPrimary),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Custom Message (optional)',
              hintText: 'Leave empty for default message',
              prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.message_rounded)),
              filled: true,
              fillColor: c.fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.fieldBorder)),
            ),
          ),
          const SizedBox(height: 12),

          _channelSelector(c),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendHoliday,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Sending...' : 'Announce Holiday', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════ History Tab ══════════
  Widget _buildHistoryTab(PccColorSet c) {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_rounded, size: 64, color: c.textTertiary),
            const SizedBox(height: 12),
            Text('No notifications sent yet', style: GoogleFonts.inter(fontSize: 16, color: c.textTertiary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final n = _history[i];
          final type = n['notification_type'] ?? 'general';
          final sentAt = DateTime.tryParse(n['sent_at'] ?? '');
          final icon = _typeIcon(type);
          final color = _typeColor(type);

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.fieldBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(n['title'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: c.textPrimary))),
                          GestureDetector(
                            onTap: () => _showEditDialog(n, c),
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF6C5CE7)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(type.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n['body'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (n['target_class'] != null) ...[
                            Icon(Icons.class_rounded, size: 12, color: c.textTertiary),
                            const SizedBox(width: 4),
                            Text(n['target_class'], style: GoogleFonts.inter(fontSize: 11, color: c.textTertiary)),
                            const SizedBox(width: 12),
                          ],
                          if (n['channel'] != null) ...[
                            Icon(n['channel'] == 'sms' ? Icons.sms_rounded : n['channel'] == 'push' ? Icons.notifications_rounded : Icons.all_inclusive_rounded, size: 12, color: c.textTertiary),
                            const SizedBox(width: 4),
                            Text(n['channel'] ?? 'both', style: GoogleFonts.inter(fontSize: 11, color: c.textTertiary)),
                            const SizedBox(width: 12),
                          ],
                          if (sentAt != null) ...[
                            Icon(Icons.access_time_rounded, size: 12, color: c.textTertiary),
                            const SizedBox(width: 4),
                            Text(DateFormat('dd MMM, HH:mm').format(sentAt), style: GoogleFonts.inter(fontSize: 11, color: c.textTertiary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

  void _confirmAndSend(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white),
            onPressed: () { Navigator.pop(ctx); onConfirm(); },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(dynamic notification, PccColorSet c) {
    final editTitleCtrl = TextEditingController(text: notification['title'] ?? '');
    final editBodyCtrl = TextEditingController(text: notification['body'] ?? '');
    final notifId = notification['id'];

    showDialog(
      context: context,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setDState) => AlertDialog(
            backgroundColor: c.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF6C5CE7)),
                ),
                const SizedBox(width: 12),
                Text('Edit Message', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: c.textPrimary)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editTitleCtrl,
                    style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: GoogleFonts.inter(color: c.textTertiary, fontSize: 13),
                      filled: true,
                      fillColor: c.fieldFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.fieldBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editBodyCtrl,
                    style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      labelStyle: GoogleFonts.inter(color: c.textTertiary, fontSize: 13),
                      filled: true,
                      fillColor: c.fieldFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.fieldBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: c.textSecondary)),
              ),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  if (editTitleCtrl.text.isEmpty && editBodyCtrl.text.isEmpty) return;
                  setDState(() => saving = true);
                  try {
                    await _api.updateNotification(
                      id: notifId,
                      title: editTitleCtrl.text.isNotEmpty ? editTitleCtrl.text : null,
                      body: editBodyCtrl.text.isNotEmpty ? editBodyCtrl.text : null,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnack('✅ Message updated successfully', Colors.green);
                    _loadHistory();
                  } catch (e) {
                    setDState(() => saving = false);
                    _showSnack('❌ Failed to update: $e', Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}

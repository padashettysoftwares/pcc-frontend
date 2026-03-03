import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _filterAction;

  final List<String> _actionFilters = [
    'All',
    'ADMIN_LOGIN',
    'STUDENT_CREATED',
    'STUDENT_UPDATED',
    'STUDENT_DELETED',
    'FEE_UPDATED',
    'PAYMENT_RECORDED',
    'STAFF_CREATED',
    'STAFF_UPDATED',
    'STAFF_DELETED',
    'PASSWORD_CHANGED',
    'CONSENT_ACCEPTED',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getAuditLog(
        page: _currentPage,
        action: _filterAction,
      );
      setState(() {
        _logs = result['data'] ?? [];
        _totalPages = result['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading audit log: $e');
      setState(() => _isLoading = false);
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'ADMIN_LOGIN':
        return Icons.login;
      case 'STUDENT_CREATED':
        return Icons.person_add;
      case 'STUDENT_UPDATED':
        return Icons.edit;
      case 'STUDENT_DELETED':
        return Icons.person_remove;
      case 'FEE_UPDATED':
        return Icons.currency_rupee;
      case 'PAYMENT_RECORDED':
        return Icons.payment;
      case 'STAFF_CREATED':
        return Icons.group_add;
      case 'STAFF_UPDATED':
        return Icons.manage_accounts;
      case 'STAFF_DELETED':
        return Icons.group_remove;
      case 'PASSWORD_CHANGED':
        return Icons.lock;
      case 'CONSENT_ACCEPTED':
        return Icons.shield;
      default:
        return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    if (action.contains('DELETE')) return AppColors.error;
    if (action.contains('CREATE') || action.contains('PAYMENT')) return AppColors.success;
    if (action.contains('LOGIN')) return AppColors.primary;
    if (action.contains('UPDATE') || action.contains('CHANGE')) return AppColors.warning;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _actionFilters.length,
              itemBuilder: (context, index) {
                final filter = _actionFilters[index];
                final isSelected = (filter == 'All' && _filterAction == null) ||
                    filter == _filterAction;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.cardBg,
                    side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                    onSelected: (selected) {
                      setState(() {
                        _filterAction = filter == 'All' ? null : filter;
                        _currentPage = 1;
                      });
                      _loadLogs();
                    },
                  ),
                );
              },
            ),
          ),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history, size: 64, color: AppColors.textTertiary),
                            const SizedBox(height: 16),
                            Text('No audit logs found', style: AppTextStyles.body),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            final action = log['action'] ?? '';
                            final color = _getActionColor(action);
                            final timestamp = log['created_at']?.toString() ?? '';
                            final date = timestamp.length > 10
                                ? '${timestamp.substring(0, 10)} ${timestamp.substring(11, 16)}'
                                : timestamp;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(_getActionIcon(action), color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          action.replaceAll('_', ' '),
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'By: ${log['performed_by'] ?? 'Unknown'} (${log['performed_by_role'] ?? ''})',
                                          style: AppTextStyles.caption,
                                        ),
                                        if (log['entity_id'] != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${log['entity_type']}: ${log['entity_id']}',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          date,
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (log['ip_address'] != null && log['ip_address'].toString().isNotEmpty)
                                    Tooltip(
                                      message: 'IP: ${log['ip_address']}',
                                      child: Icon(Icons.language, size: 16, color: AppColors.textTertiary),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // Pagination
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadLogs();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadLogs();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

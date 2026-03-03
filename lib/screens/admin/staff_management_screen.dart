import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getStaffList();
      _staff = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).pcc;
    return Scaffold(
      backgroundColor: c.scaffold,
      appBar: AppBar(
        title: Text('Staff Management', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: c.card,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffDialog(),
        icon: const Icon(Icons.person_add_rounded),
        label: Text('Add Staff', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? Center(child: Text('No staff members yet', style: GoogleFonts.inter(color: c.textTertiary)))
              : RefreshIndicator(
                  onRefresh: _fetchStaff,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _staff.length,
                    itemBuilder: (_, i) => _staffCard(_staff[i]),
                  ),
                ),
    );
  }

  Widget _staffCard(Map<String, dynamic> staff) {
    final c = Theme.of(context).pcc;
    final role = staff['role'] ?? 'teacher';
    final roleColor = role == 'super_admin'
        ? const Color(0xFFE74C3C)
        : role == 'teacher'
            ? const Color(0xFF3498DB)
            : const Color(0xFF2ECC71);
    final isActive = staff['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.fieldBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Icon(
            role == 'super_admin' ? Icons.admin_panel_settings : role == 'teacher' ? Icons.school : Icons.receipt_long,
            color: roleColor,
            size: 22,
          ),
        ),
        title: Text(staff['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: c.textPrimary)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(role.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
            ),
            const SizedBox(width: 8),
            Text('@${staff['username']}', style: GoogleFonts.inter(fontSize: 12, color: c.textTertiary)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'toggle') {
                  await _api.updateStaff(staff['id'], {'is_active': !isActive});
                  _fetchStaff();
                } else if (val == 'delete') {
                  await _api.deleteStaff(staff['id']);
                  _fetchStaff();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameC = TextEditingController();
    final userC = TextEditingController();
    final passC = TextEditingController();
    final pinC = TextEditingController();
    String selectedRole = 'teacher';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDState) {
            return AlertDialog(
              title: Text('Add Staff', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Full Name')),
                    const SizedBox(height: 8),
                    TextField(controller: userC, decoration: const InputDecoration(labelText: 'Username')),
                    const SizedBox(height: 8),
                    TextField(controller: passC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                    const SizedBox(height: 8),
                    TextField(controller: pinC, decoration: const InputDecoration(labelText: 'PIN (optional)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                        DropdownMenuItem(value: 'front_desk', child: Text('Front Desk')),
                        DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                      ],
                      onChanged: (v) => setDState(() => selectedRole = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white),
                  onPressed: () async {
                    try {
                      await _api.createStaff({
                        'username': userC.text.trim(),
                        'password': passC.text.trim(),
                        'name': nameC.text.trim(),
                        'role': selectedRole,
                        'pin': pinC.text.trim().isNotEmpty ? pinC.text.trim() : null,
                      });
                      if (mounted) Navigator.pop(ctx);
                      _fetchStaff();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

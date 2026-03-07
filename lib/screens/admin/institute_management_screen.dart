import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../utils/theme.dart';
import '../../../services/api_service.dart';

class InstituteManagementScreen extends StatefulWidget {
  const InstituteManagementScreen({super.key});

  @override
  State<InstituteManagementScreen> createState() => _InstituteManagementScreenState();
}

class _InstituteManagementScreenState extends State<InstituteManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _institutes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInstitutes();
  }

  Future<void> _fetchInstitutes() async {
    setState(() => _isLoading = true);
    try {
      final token = ApiService().token;
      final url = Uri.parse('${ApiService.baseUrl}/institutes');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _institutes = data is List ? data : (data['institutes'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception(json.decode(res.body)['error'] ?? 'Failed to load institutes');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateInstituteDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 24, left: 20, right: 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).pcc.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Institute', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).pcc.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: _inputDeco('Institute Name', Icons.business_rounded, context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: _inputDeco('Institute Code (e.g. XYZ)', Icons.tag_rounded, context),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: _inputDeco('Address', Icons.location_on_rounded, context),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
                
                try {
                  final token = ApiService().token;
                  final res = await http.post(
                    Uri.parse('${ApiService.baseUrl}/institutes'),
                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                    body: json.encode({
                      'name': nameCtrl.text.trim(),
                      'code': codeCtrl.text.trim().toUpperCase(),
                      'address': addressCtrl.text.trim(),
                    }),
                  );
                  if (res.statusCode == 201 && mounted) {
                    Navigator.pop(ctx);
                    _fetchInstitutes();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json.decode(res.body)['error'])));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAddAdminDialog(dynamic institute) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).pcc.card,
        title: Text('Add Admin for ${institute['name']}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).pcc.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: _inputDeco('Admin Name', Icons.person_rounded, context)),
            const SizedBox(height: 12),
            TextField(controller: userCtrl, decoration: _inputDeco('Username', Icons.alternate_email_rounded, context)),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, decoration: _inputDeco('Password (min 8)', Icons.lock_rounded, context), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || userCtrl.text.isEmpty || passCtrl.text.length < 8) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields properly (password min 8 chars)')));
                 return;
              }
              Navigator.pop(ctx);
              _createAdmin(institute['id'], institute['name'], userCtrl.text.trim(), passCtrl.text, nameCtrl.text.trim());
            },
            child: const Text('Create Admin'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAdmin(int instituteId, String instName, String username, String password, String name) async {
    try {
      final token = ApiService().token;
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/institutes/$instituteId/admin'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'username': username,
          'password': password,
          'name': name
        }),
      );
      
      final data = json.decode(res.body);
      if (res.statusCode == 201 && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).pcc.card,
            title: Text('Admin Created!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Save these credentials now. They will not be shown again.', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).pcc.textSecondary)),
                const SizedBox(height: 16),
                _credRow('Institute', instName),
                _credRow('Admin Name', name),
                _credRow('Username', data['username'] ?? username),
                _credRow('Note', 'Admin should change their password immediately after login.'),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).pcc.textPrimary))),
          Expanded(child: SelectableText(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF6C5CE7)))),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, BuildContext context) {
    final c = Theme.of(context).pcc;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.textTertiary),
      prefixIcon: Icon(icon, color: c.textTertiary, size: 20),
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.fieldBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).pcc;
    
    return Scaffold(
      backgroundColor: c.scaffold,
      appBar: AppBar(
        title: Text('Institutes', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: c.textPrimary, fontSize: 18)),
        backgroundColor: c.card,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: _showCreateInstituteDialog,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: Text('New Institute', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
        : _error != null
          ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _institutes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final inst = _institutes[i];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.fieldBorder),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              inst['name'], 
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(inst['code'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF6C5CE7), fontSize: 13)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(inst['address'] ?? 'No address provided', style: GoogleFonts.inter(color: c.textSecondary, fontSize: 13)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people_alt_rounded, size: 16, color: c.textTertiary),
                              const SizedBox(width: 6),
                              Text('${inst['student_count']?.toString() ?? '0'} Students', style: GoogleFonts.inter(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddAdminDialog(inst),
                            icon: const Icon(Icons.person_add_rounded, size: 16, color: Color(0xFF6C5CE7)),
                            label: Text('Add Admin', style: GoogleFonts.inter(color: const Color(0xFF6C5CE7), fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}

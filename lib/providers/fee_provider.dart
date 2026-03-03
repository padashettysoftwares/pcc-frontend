import 'package:flutter/material.dart';
import '../models/fee.dart';
import '../services/api_service.dart';

class FeeProvider with ChangeNotifier {
  final _api = ApiService();
  List<Fee> _fees = [];
  bool _isLoading = false;
  double _totalFeesCollected = 0;
  double _pendingFees = 0;

  List<Fee> get fees => _fees;
  bool get isLoading => _isLoading;
  double get totalFeesCollected => _totalFeesCollected;
  double get pendingFees => _pendingFees;
  double get totalCollected => _totalFeesCollected;
  double get totalPending => _pendingFees;

  Future<void> fetchFees() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getAllFees();
      _fees = data.map<Fee>((item) => Fee.fromMap(Map<String, dynamic>.from(item))).toList();
      
      _totalFeesCollected = 0;
      _pendingFees = 0;
      for (var fee in _fees) {
        _totalFeesCollected += fee.paidAmount;
        _pendingFees += fee.dueAmount;
      }
    } catch (e) {
      debugPrint("Error fetching fees: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update total fee amount (requires reason for audit trail)
  Future<void> updateTotalFees(String studentId, double totalFees, String reason) async {
    await _api.updateTotalFees(studentId, totalFees, reason);
    await fetchFees();
  }

  /// Record a payment in the immutable ledger (requires reason)
  Future<void> addPayment(String studentId, double amount, String reason) async {
    await _api.addPayment(studentId, amount, reason);
    await fetchFees();
  }

  /// Record an adjustment — super admin only (requires reason)
  Future<void> addAdjustment(String studentId, double amount, String reason) async {
    await _api.addAdjustment(studentId, amount, reason);
    await fetchFees();
  }

  Fee? getFee(String studentId) {
    try {
      return _fees.firstWhere((f) => f.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

  // Legacy — kept for backward compat
  Future<void> setOrUpdateFee(Fee fee) async {
    await _api.updateFees(fee.studentId, {
      'totalFees': fee.totalFees,
      'reason': 'Fee update (admin)',
    });
    await fetchFees();
  }

  Future<void> updateFee(Fee fee) async {
    await setOrUpdateFee(fee);
  }
}

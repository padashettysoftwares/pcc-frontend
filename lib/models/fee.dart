class Fee {
  final int? id;
  final String studentId;
  final double totalFees;
  final double paidAmount;
  final double dueAmount;

  Fee({
    this.id,
    required this.studentId,
    required this.totalFees,
    required this.paidAmount,
    required this.dueAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'total_fees': totalFees,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
    };
  }

  factory Fee.fromMap(Map<String, dynamic> map) {
    return Fee(
      id: map['id'],
      studentId: map['student_id'] ?? '',
      totalFees: double.tryParse(map['total_fees'].toString()) ?? 0.0,
      paidAmount: double.tryParse(map['paid_amount'].toString()) ?? 0.0,
      dueAmount: double.tryParse(map['due_amount'].toString()) ?? 0.0,
    );
  }
}

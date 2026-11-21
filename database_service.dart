import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // 1. Stream a student's profile (used by HomePage & ProfilePage)
  // ============================================================
  Stream<DocumentSnapshot> getStudentProfile(String studentId) {
    return _firestore.collection('students').doc(studentId).snapshots();
  }

  // ============================================================
  // 2. Update permit status (used after successful payment)
  // ============================================================
  Future<void> activatePermit({
    required String studentUid,
    required DateTime startDate,
    required DateTime expiryDate,
    required double amountPaid,
  }) async {
    await _firestore.collection('students').doc(studentUid).update({
      'permitStatus': 'Active',
      'parkingQuota': 1,
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'paidAmount': amountPaid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // 3. Process early checkout refund (used by ProfilePage)
  // ============================================================
  Future<void> processEarlyCheckoutRefund({
    required String studentUid,
    required double annualFeePaid,
    required DateTime startDate,
    required DateTime expiryDate,
  }) async {
    // Calculate refund based on remaining days
    final totalDays = expiryDate.difference(startDate).inDays;
    final usedDays = DateTime.now().difference(startDate).inDays;
    final remainingDays = (totalDays - usedDays).clamp(0, totalDays);

    final refundAmount =
        totalDays > 0 ? (annualFeePaid * remainingDays / totalDays) : 0.0;

    // 1. Log the refund request
    await _firestore.collection('refunds').add({
      'studentUid': studentUid,
      'annualFeePaid': annualFeePaid,
      'refundAmount': double.parse(refundAmount.toStringAsFixed(2)),
      'remainingDays': remainingDays,
      'totalDays': totalDays,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending', // admin will review and change to 'approved' / 'rejected'
    });

    // 2. Mark the student's permit as "pending refund"
    await _firestore.collection('students').doc(studentUid).update({
      'permitStatus': 'Refund Pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // 4. Update vehicle plate (optional — for profile editing later)
  // ============================================================
  Future<void> updatePlateNumber({
    required String studentUid,
    required String newPlate,
  }) async {
    await _firestore.collection('students').doc(studentUid).update({
      'plateNumber': newPlate.toUpperCase().replaceAll(' ', ''),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // 5. Stream entry logs for a specific student (used on HomePage)
  // ============================================================
  Stream<QuerySnapshot> getStudentEntryLogs(String studentUid, {int limit = 10}) {
    return _firestore
        .collection('entry_logs')
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}
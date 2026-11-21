import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final String studentId;
  const ProfilePage({super.key, required this.studentId});

  static const Color primaryBlue = Color(0xFF1E50ED);
  static const Color bgLight     = Color(0xFFF8FAFC);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color textDark    = Color(0xFF0F172A);
  static const Color textMuted   = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: DatabaseService().getStudentProfile(studentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryBlue));
            }

            String name = "Unregistered";
            String matric = studentId;
            String plate = "N/A";
            DateTime startDate = DateTime.now();
            DateTime expiryDate = DateTime(startDate.year + 1, startDate.month, startDate.day);
            double paidAmount = 20.00;

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['fullName'] ?? "Unregistered";
              matric = data['matricNo'] ?? studentId;
              plate = data['plateNumber'] ?? "N/A";
              
              if (data['startDate'] != null) {
                startDate = (data['startDate'] as Timestamp).toDate();
              }
              if (data['expiryDate'] != null) {
                expiryDate = (data['expiryDate'] as Timestamp).toDate();
              }
              if (data['paidAmount'] != null) {
                paidAmount = (data['paidAmount'] as num).toDouble();
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryBlue,
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('Student Profile', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: textDark)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _buildProfileItem(title: 'Name', value: name),
                        const Divider(),
                        _buildProfileItem(title: 'Student ID', value: matric),
                        const Divider(),
                        _buildProfileItem(title: 'Registered Vehicle', value: plate),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Early Checkout & Refund Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
                    label: Text(
                      'Request Early Checkout & Refund',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () => _showRefundConfirmationDialog(
                      context: context,
                      studentUid: studentId,
                      paidAmount: paidAmount,
                      startDate: startDate,
                      expiryDate: expiryDate,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Log Out Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: Text(
                      'Log Out',
                      style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showRefundConfirmationDialog({
    required BuildContext context,
    required String studentUid,
    required double paidAmount,
    required DateTime startDate,
    required DateTime expiryDate,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Early Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to submit an early checkout request? Your refund will be calculated based on remaining active days.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseService().processEarlyCheckoutRefund(
                studentUid: studentUid,
                annualFeePaid: paidAmount,
                startDate: startDate,
                expiryDate: expiryDate,
              );

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refund request submitted to administrator!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Submit', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(color: textMuted, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.poppins(color: textDark, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
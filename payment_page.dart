import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import 'renewal_page.dart';
import 'toyyibpay_page.dart';

class PaymentPage extends StatelessWidget {
  final String studentId;

  const PaymentPage({super.key, required this.studentId});

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color bgLight     = Color(0xFFF1F5F9);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color textDark    = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: Text('Permit Payments', style: GoogleFonts.poppins(color: textDark, fontWeight: FontWeight.w800)),
        backgroundColor: cardBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permit Services', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'New Permit Registration',
              subtitle: 'Apply & pay RM20 for new annual parking permit',
              icon: Icons.app_registration_rounded,
              onTap: () => _handleNewRegistrationPayment(context),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Renew Existing Permit',
              subtitle: 'Extend your active parking permit validity',
              icon: Icons.autorenew_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RenewalPaymentPage(studentUid: studentId)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNewRegistrationPayment(BuildContext context) {
    // Uses the permalink created on the ToyyibPay dashboard
    const String billUrl = 'https://dev.toyyibpay.com/Annually-Parking-Fee';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToyyibPayPage(
          billUrl: billUrl,
          onSuccess: () async {
          final now = DateTime.now();
          final expiry = DateTime(now.year + 1, now.month, now.day);
          await DatabaseService().activatePermit(
            studentUid: studentId,
            startDate: now,
            expiryDate: expiry,
            amountPaid: 20.00,
          );
  
          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration payment successful! Permit activated.'),
              backgroundColor: Colors.green,
            ),
          );
        },
          onFailure: () {
            Navigator.pop(context);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment cancelled or failed.'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryBlue.withValues(alpha: 0.1),
              radius: 26,
              child: Icon(icon, color: primaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
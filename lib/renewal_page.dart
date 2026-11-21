import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RenewalPaymentPage extends StatefulWidget {
  final String studentUid;
  const RenewalPaymentPage({super.key, required this.studentUid});

  @override
  State<RenewalPaymentPage> createState() => _RenewalPaymentPageState();
}

class _RenewalPaymentPageState extends State<RenewalPaymentPage> {
  String selectedMethod = 'FPX';

  static const Color primaryBlue = Color(0xFF1E50ED);
  static const Color bgLight     = Color(0xFFF8FAFC);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color textDark    = Color(0xFF0F172A);
  static const Color textMuted   = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
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
                const Icon(Icons.autorenew_rounded, size: 64, color: primaryBlue),
                const SizedBox(height: 8),
                Text('Permit Renewal', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: textDark)),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car_rounded, color: primaryBlue),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${widget.studentUid}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
                                Text('Extension Period: 1 Year', style: GoogleFonts.poppins(fontSize: 11, color: textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Renewal Fee:', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted)),
                      Text('RM 20.00', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: textDark)),
                      const SizedBox(height: 20),
                      Text('Select Payment Method:', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMethodTile('TnG', 'Touch \'n Go')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMethodTile('GrabPay', 'GrabPay')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildMethodTile('FPX', 'FPX Online Banking'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Processing Renewal via $selectedMethod...'), backgroundColor: primaryBlue),
                    );
                  },
                  child: Text('RENEW NOW', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTile(String id, String label) {
    final isSelected = selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withValues(alpha: 0.08) : bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryBlue : borderColor, width: isSelected ? 2 : 1),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? primaryBlue : textDark)),
        ),
      ),
    );
  }
}

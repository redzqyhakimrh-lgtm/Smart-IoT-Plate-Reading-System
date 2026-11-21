import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pushNotifications = true;
  bool expiryAlerts = true;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Text('Settings', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: textDark)),
              const SizedBox(height: 20),
              Text('Notifications', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: textMuted)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: primaryBlue,
                      title: Text('Push Notifications', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
                      value: pushNotifications,
                      onChanged: (val) => setState(() => pushNotifications = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: primaryBlue,
                      title: Text('Permit Expiry Reminders', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
                      value: expiryAlerts,
                      onChanged: (val) => setState(() => expiryAlerts = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
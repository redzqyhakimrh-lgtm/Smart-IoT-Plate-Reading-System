import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_wrapper.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  final Color primaryBlue = const Color(0xFF1E50ED);
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color cardBg = Colors.white;
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _plateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    final name = _fullNameController.text.trim();
    final studentId = _studentIdController.text.trim();
    final plate = _plateController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || studentId.isEmpty || plate.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create User in Firebase Auth
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final String uid = credential.user!.uid;

      // 2. Save Student Record in Firestore
      await FirebaseFirestore.instance.collection('students').doc(uid).set({
        'studentUid': uid,
        'fullName': name,
        'matricNo': studentId,
        'plateNumber': plate,
        'email': email,
        'permitStatus': 'Inactive',
        'parkingQuota': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 3. Navigate to Main Application
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainWrapper(studentUid: uid)),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textMuted),
          prefixIcon: Icon(icon, color: primaryBlue),
          filled: true,
          fillColor: cardBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: BackButton(color: textDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 48,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 24),
              _buildTextField('Full Name', Icons.person_outline, _fullNameController),
              _buildTextField('Student ID', Icons.badge_outlined, _studentIdController),
              _buildTextField('Vehicle Plate Number', Icons.directions_car_outlined, _plateController),
              _buildTextField('Email Address', Icons.email_outlined, _emailController),
              _buildTextField('Password', Icons.lock_outline, _passwordController, isPassword: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
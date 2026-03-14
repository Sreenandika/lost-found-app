import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lost_found_app/main.dart';
import 'package:lost_found_app/pages/landing_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _otpSent = false; // New flag to toggle between Email and OTP entry
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _otpController = TextEditingController();

  // 1. Send the OTP Code
  Future<void> _sendOtp() async {
    try {
      setState(() => _isLoading = true);

      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        shouldCreateUser: true,
      );

      if (mounted) {
        setState(() => _otpSent = true);
        context.showSnackBar('Check your email for the 6-digit code!');
      }
    } on AuthException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted)
        context.showSnackBar('Unexpected error occurred', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Verify the OTP Code
  Future<void> _verifyOtp() async {
    try {
      setState(() => _isLoading = true);

      final response = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      if (response.session != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Landing_Page()),
        );
      }
    } on AuthException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) context.showSnackBar('Invalid code', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome Back')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(LineIcons.userSecret, size: 80, color: Color(0xFF006C4C)),
              const SizedBox(height: 32),
              Text(
                _otpSent
                    ? 'Verify your identity'
                    : 'Sign in to Lost&Found',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to ${_emailController.text}'
                    : 'Enter your email to receive a secure login code',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: _emailController,
                enabled: !_otpSent,
                decoration: const InputDecoration(
                  hintText: 'Email Address',
                  prefixIcon: Icon(LineIcons.envelope),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    hintText: '6-Digit Code',
                    prefixIcon: Icon(LineIcons.lock),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _otpSent ? 'Verify Code' : 'Send Code',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              if (_otpSent)
                TextButton(
                  onPressed: () => setState(() => _otpSent = false),
                  child: const Text('Change Email'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

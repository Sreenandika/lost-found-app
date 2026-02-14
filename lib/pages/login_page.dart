import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lost_found_app/main.dart';
import 'package:lost_found_app/pages/account_page.dart';
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
      if (mounted) context.showSnackBar('Unexpected error occurred', isError: true);
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
      appBar: AppBar(title: const Text('Sign In')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          Text(_otpSent 
            ? 'Enter the 6-digit code sent to ${_emailController.text}' 
            : 'Enter your email to receive a login code'),
          const SizedBox(height: 18),
          
          // Email Field (Disabled once OTP is sent)
          TextFormField(
            controller: _emailController,
            enabled: !_otpSent,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),

          if (_otpSent) ...[
            const SizedBox(height: 18),
            // OTP Field (Shows up after email is sent)
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: '6-Digit Code', hintText: '123456'),
              keyboardType: TextInputType.number,
            ),
          ],

          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading 
              ? null 
              : (_otpSent ? _verifyOtp : _sendOtp),
            child: Text(_isLoading 
              ? 'Processing...' 
              : (_otpSent ? 'Verify Code' : 'Send Code')),
          ),
          
          if (_otpSent)
            TextButton(
              onPressed: () => setState(() => _otpSent = false),
              child: const Text('Edit Email'),
            )
        ],
      ),
    );
  }
}
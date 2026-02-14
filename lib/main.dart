import 'package:flutter/material.dart';
import 'package:lost_found_app/pages/landing_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lost_found_app/pages/account_page.dart';
import 'package:lost_found_app/pages/login_page.dart';

Future<void> main() async {
  await Supabase.initialize(
     url: 'https://kkpmzruqsvcjxuaksqci.supabase.co',
    anonKey: 'sb_publishable_tJWSVb1QEL0QKplUsVCZyQ_kMdWG1mR',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost&Found',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
          ),
        ),
      ),
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : Landing_Page(),
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
  
}

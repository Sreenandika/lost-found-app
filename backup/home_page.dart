import 'package:flutter/material.dart';
import 'report_lost_page.dart';
import 'report_found_page.dart';
import 'view_lost_page.dart';
import 'view_found_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget item(BuildContext context, String title, Widget page) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lost & Found")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            item(context, "Report Lost Item", ReportLostPage()),
            item(context, "Report Found Item", ReportFoundPage()),
            item(context, "View Lost Items", ViewLostPage()),
            item(context, "View Found Items", ViewFoundPage()),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("Logout"),
            )
          ],
        ),
      ),
    );
  }
}

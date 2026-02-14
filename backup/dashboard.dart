import 'package:flutter/material.dart';
import 'report_lost_page.dart';
import 'report_found_page.dart';
import 'view_lost_page.dart';
import 'view_found_page.dart';
import 'search_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int index = 0;

  final pages = [
    const HomePage(),
    const SearchPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lost & Found")),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
        ],
      ),
    );
  }
}

/* HOME SCREEN */
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget card(BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          card(context, "Report Lost Item", Icons.search, ReportLostPage()),
          card(context, "Report Found Item", Icons.inventory, ReportFoundPage()),
          card(context, "View Lost Items", Icons.list,  ViewLostPage()),
          card(context, "View Found Items", Icons.check_circle, ViewFoundPage()),
        ],
      ),
    );
  }
}

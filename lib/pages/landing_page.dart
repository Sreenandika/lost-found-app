import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';

import 'package:lost_found_app/pages/report_page.dart';
import 'package:lost_found_app/pages/account_page.dart';
import 'package:lost_found_app/pages/my_reports_page.dart';
import 'package:lost_found_app/pages/search_page.dart';

class Landing_Page extends StatefulWidget {
  const Landing_Page({Key? key}) : super(key: key);

  @override
  State<Landing_Page> createState() => _Landing_PageState();
}

class _Landing_PageState extends State<Landing_Page> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    SearchPage(),
    ReportPage(),
    MyReportsPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GNav(
              rippleColor: Theme.of(context).primaryColor.withOpacity(0.1),
              hoverColor: Theme.of(context).primaryColor.withOpacity(0.05),
              gap: 8,
              activeColor: Theme.of(context).primaryColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              color: Colors.grey[600]!,
              tabs: const [
                GButton(icon: LineIcons.search, text: 'Search'),
                GButton(icon: LineIcons.plus, text: 'Report'),
                GButton(icon: LineIcons.folderOpen, text: 'Reported'),
                GButton(icon: LineIcons.userCircle, text: 'Profile'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ReportItemPage extends StatelessWidget {
  final String type;
  const ReportItemPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Report $type item")),
      body: Center(
        child: Text("Upload $type item form here"),
      ),
    );
  }
}

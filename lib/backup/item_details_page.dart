import 'package:flutter/material.dart';

class ItemDetailsPage extends StatelessWidget {
  final dynamic item;
  const ItemDetailsPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item["name"])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (item["image"] != null)
              Image.network(
                "http://10.127.18.235:3000/uploads/${item["image"]}",
                height: 200,
              ),
            const SizedBox(height: 20),
            Text(item["description"]),
          ],
        ),
      ),
    );
  }
}

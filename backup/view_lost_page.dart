import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewLostPage extends StatefulWidget {
  const ViewLostPage({super.key});

  @override
  State<ViewLostPage> createState() => _ViewLostPageState();
}

class _ViewLostPageState extends State<ViewLostPage> {
  List items = [];

  Future loadItems() async {
    final res = await http.get(
      Uri.parse("http://10.127.18.235:3000/lost-items"),
    );
    setState(() => items = jsonDecode(res.body));
  }

  Future deleteItem(int id) async {
    await http.delete(
      Uri.parse("http://10.127.18.235:3000/delete-lost-item/$id"),
    );
    loadItems();
  }

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lost Items")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: item["image"] != null
                  ? Image.network(
                      "http://10.127.18.235:3000/uploads/${item["image"]}",
                      width: 50,
                      fit: BoxFit.cover,
                    )
                  : null,
              title: Text(item["name"]),
              subtitle: Text(item["description"]),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteItem(item["id"]),
              ),
            ),
          );
        },
      ),
    );
  }
}

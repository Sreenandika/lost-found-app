import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewFoundPage extends StatefulWidget {
  const ViewFoundPage({super.key});

  @override
  State<ViewFoundPage> createState() => _ViewFoundPageState();
}

class _ViewFoundPageState extends State<ViewFoundPage> {
  List items = [];

  Future loadItems() async {
    final res = await http.get(
      Uri.parse("http://10.127.18.235:3000/found-items"),
    );
    setState(() => items = jsonDecode(res.body));
  }

  Future deleteItem(int id) async {
    await http.delete(
      Uri.parse("http://10.127.18.235:3000/delete-found-item/$id"),
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
      appBar: AppBar(title: const Text("Found Items")),
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
                    )
                  : null,
              title: Text(item["name"]),
              subtitle: Text(
                "Desc: ${item["description"]}\nContact: ${item["contact"]}",
              ),
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

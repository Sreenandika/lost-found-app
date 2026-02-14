import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List allItems = [];
  List results = [];

  Future loadItems() async {
    final lost = await http.get(
      Uri.parse("http://10.127.18.235:3000/lost-items"),
    );
    final found = await http.get(
      Uri.parse("http://10.127.18.235:3000/found-items"),
    );

    allItems = [
      ...jsonDecode(lost.body),
      ...jsonDecode(found.body),
    ];
    results = allItems;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void search(String text) {
    results = allItems
        .where((item) =>
            item["name"].toLowerCase().contains(text.toLowerCase()))
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(labelText: "Search item"),
            onChanged: search,
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text("Item not found"))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final item = results[i];
                    return ListTile(
                      title: Text(item["name"]),
                      subtitle: Text(item["description"] ?? ""),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

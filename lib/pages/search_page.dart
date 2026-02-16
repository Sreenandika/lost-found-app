import 'package:flutter/material.dart';
import 'package:lost_found_app/main.dart';
import 'package:lost_found_app/pages/item_search_page.dart';
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allResults = []; // Preloaded items
  List<Map<String, dynamic>> _filteredResults = []; // Items shown to user
  //LMAOOOOOOO
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // 1. Preload results from Supabase
  Future<void> _fetchItems() async {
    try {
      final data = await supabase
          .from('items') // Replace with your actual table name
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _allResults = List<Map<String, dynamic>>.from(data);
        _filteredResults = _allResults;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) context.showSnackBar('Error loading items', isError: true);
    }
  }

  // 2. Filter logic
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allResults;
    } else {
      results = _allResults
          .where((item) => item['name']
              .toString()
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Items')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                labelText: 'Search by item name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredResults.isNotEmpty
                    ? ListView.builder(
                        itemCount: _filteredResults.length,
                        itemBuilder: (context, index) {
                          final item = _filteredResults[index];
                          return ListTile(
                            leading: const Icon(Icons.inventory_2),
                            title: Text(item['name'] ?? 'Unknown Item'),
                            subtitle: Text(item['description'] ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItemDetailsPage(item: item),
                                      ),
                                    );
                                  },
                        );
                        },
                      )
                    : const Center(
                        child: Text('No items found'),
                      ),
          ),
        ],
      ),
    );
  }
}
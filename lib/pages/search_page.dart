import 'package:flutter/material.dart';
import 'package:lost_found_app/main.dart';
import 'package:lost_found_app/pages/item_search_page.dart';
import 'package:lost_found_app/pages/chat_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _filteredResults = [];

  bool _isLoading = true;

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _getUnreadMessages();
    _listenForNewMessages();
  }

  // Load items
  Future<void> _fetchItems() async {
    try {
      final data = await supabase
          .from('items_details_view')
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

  // Filter items
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];

    if (enteredKeyword.isEmpty) {
      results = _allResults;
    } else {
      results = _allResults
          .where(
            (item) => item['name'].toString().toLowerCase().contains(
              enteredKeyword.toLowerCase(),
            ),
          )
          .toList();
    }

    setState(() {
      _filteredResults = results;
    });
  }

  // Get unread messages
  Future<void> _getUnreadMessages() async {
    final userId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('messages')
        .select()
        .eq('receiver_id', userId);

    setState(() {
      _unreadCount = data.length;
    });
  }

  // Listen realtime
  void _listenForNewMessages() {
    final userId = supabase.auth.currentUser!.id;

    supabase
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            if (payload.newRecord['receiver_id'] == userId) {
              setState(() {
                _unreadCount++;
              });
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Items'),

        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatListPage()),
                  );
                },
              ),

              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,

                  child: Container(
                    padding: const EdgeInsets.all(5),

                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
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
                : const Center(child: Text('No items found')),
          ),
        ],
      ),
    );
  }
}

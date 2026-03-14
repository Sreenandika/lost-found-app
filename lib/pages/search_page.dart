import 'package:flutter/material.dart';
import 'package:lost_found_app/main.dart';
import 'package:lost_found_app/pages/item_search_page.dart';
import 'package:lost_found_app/pages/chat_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_icons/line_icons.dart';

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
      .eq('receiver_id', userId)
      .eq('is_read', false);   // Only unread

  print(data);
  setState(() {
    _unreadCount = data.length;
  });
}

  // Listen realtime
void _listenForNewMessages() {
  supabase
      .channel('messages-channel')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          _getUnreadMessages(); // recompute instead of ++
        },
      )
      .subscribe();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(LineIcons.comment),
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
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                hintText: 'Search lost or found items...',
                prefixIcon: const Icon(LineIcons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LineIcons.times),
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
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredResults.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _filteredResults[index];
                      final isLost = item['type'] == 'lost';

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: (isLost ? Colors.orange : Colors.blue).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isLost ? LineIcons.search : LineIcons.checkCircle,
                              color: isLost ? Colors.orange : Colors.blue,
                            ),
                          ),
                          title: Text(
                            item['name'] ?? 'Unknown Item',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isLost ? Colors.orange : Colors.blue).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isLost ? 'LOST' : 'FOUND',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isLost ? Colors.orange[800] : Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailsPage(item: item),
                              ),
                            );
                          },
                        ),
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

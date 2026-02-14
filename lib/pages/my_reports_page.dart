import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lost_found_app/main.dart'; // Ensure your supabase instance is here
import 'package:line_icons/line_icons.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  String _filter = 'all'; // 'all', 'lost', or 'found'
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  /// The corrected fetch logic
  Future<void> _fetchMyReports() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  
  try {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("DEBUG: No user logged in");
      return;
    }

    print("DEBUG: Fetching for User ID: ${user.id} with Filter: $_filter");

    // Initialize the query
    var query = supabase.from('items').select();

    // Apply User Filter
    query = query.eq('user_id', user.id);

    // Apply Type Filter ONLY if not 'all'
    if (_filter != 'all') {
      // Use .ilike for case-insensitive matching just in case
      query = query.ilike('type', _filter); 
    }

    final data = await query.order('created_at', ascending: false);
    
    print("DEBUG: Data received: ${data.length} items");

    if (mounted) {
      setState(() {
        _reports = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    }
  } catch (e) {
    print("DEBUG: Catch error: $e");
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

  /// Delete a report from Supabase
  Future<void> _deleteReport(String itemId) async {
    try {
      await supabase.from('items').delete().eq('id', itemId);
      _fetchMyReports(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report deleted"), backgroundColor: Colors.black),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delete failed"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Reports", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Items'),
                const SizedBox(width: 8),
                _buildFilterChip('lost', 'Lost'),
                const SizedBox(width: 8),
                _buildFilterChip('found', 'Found'),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _reports.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchMyReports,
                        color: Colors.black,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            return _buildReportCard(_reports[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    bool isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
          _fetchMyReports();
        }
      },
      selectedColor: Colors.black,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> item) {
    final bool isLost = item['type'] == 'lost';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.5), // High contrast border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image Section
          if (item['image_url'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                item['image_url'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[100],
                  child: const Icon(LineIcons.image, size: 40, color: Colors.grey),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'] ?? 'Untitled',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLost ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLost ? "LOST" : "FOUND",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Details
                Row(
                  children: [
                    const Icon(LineIcons.list, size: 16),
                    const SizedBox(width: 8),
                    Text(item['category'] ?? 'Category', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LineIcons.mapMarker, size: 16),
                    const SizedBox(width: 8),
                    Text(item['location'] ?? 'Location', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                
                const Divider(height: 24, thickness: 1),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmDelete(item['id']),
                      icon: const Icon(LineIcons.trash, color: Colors.red),
                      label: const Text("Remove", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Report?"),
        content: const Text("Are you sure you want to remove this report permanently?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReport(id);
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LineIcons.clipboardList, size: 80, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            "No $_filter items reported yet.",
            style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
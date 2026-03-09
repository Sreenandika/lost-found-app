import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'chat_page.dart';

class ItemDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailsPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isLost = item['type'] == 'lost';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(item['name'] ?? 'Item Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE
            if (item['image_url'] != null)
              Image.network(
                item['image_url'],
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(
                    LineIcons.image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // TITLE + BADGE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLost ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLost ? "LOST" : "FOUND",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Reported on ${item['created_at'].toString().substring(0, 10)}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),

                  const Divider(height: 40),

                  _buildInfoRow(LineIcons.tag, "Category", item['category']),
                  const SizedBox(height: 15),
                  _buildInfoRow(LineIcons.mapMarker, "Location", item['location']),

                  const SizedBox(height: 30),

                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    item['description'] ?? "No description provided.",
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // CONTACT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(item: item),
                          ),
                        );
                      },

                      icon: const Icon(
                        LineIcons.envelope,
                        color: Colors.white,
                      ),

                      label: const Text(
                        "Contact Reporter",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String? value,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 24),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            Text(
              value ?? 'Not specified',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
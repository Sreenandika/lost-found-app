import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'chat_page.dart';

class ItemDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailsPage({super.key, required this.item});

  // Updated Parsing Strategy for "POINT(76.3291 10.0456)"
  LatLng? _parseLocation(String? pointString) {
    print(pointString);
    if (pointString == null || pointString.isEmpty) return null;
    try {
      // 1. Remove the "POINT(" and ")" wrappers
      final cleanString = pointString
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .trim();

      // 2. Split by space to get Longitude and Latitude
      final coordinates = cleanString.split(' ');

      // PostGIS format is Longitude first, then Latitude
      final double lng = double.parse(coordinates[0]);
      final double lat = double.parse(coordinates[1]);

      return LatLng(lat, lng);
    } catch (e) {
      debugPrint("Error parsing location: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLost = item['type'] == 'lost';

    // Use 'location_text' from our SQL view
    final LatLng? collectionLatLng = _parseLocation(item['location_text']);

    final DateTime? collectionTime = item['collection_time'] != null
        ? DateTime.parse(item['collection_time'])
        : null;

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
            // IMAGE SECTION
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
                  // TITLE & STATUS
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
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),

                  const Divider(height: 40),

                  // CORE INFO
                  _buildInfoRow(LineIcons.tag, "Category", item['category']),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                    LineIcons.mapMarker,
                    "General Location",
                    item['location'],
                  ),

                  // COLLECTION DETAILS (Only for Found items)
                  if (!isLost) ...[
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      LineIcons.calendar,
                      "Collection Time",
                      collectionTime != null
                          ? DateFormat('MMM dd, hh:mm a').format(collectionTime)
                          : 'Not specified',
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      LineIcons.building,
                      "Meeting Spot",
                      item['collection_notes'],
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      "Meeting Location Pin",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // MAP PREVIEW
                    if (collectionLatLng != null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: collectionLatLng,
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                // Use your actual package name from android/app/build.gradle
                                userAgentPackageName:
                                    'com.example.lost_found_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: collectionLatLng,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Text(
                        "No coordinate data available",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],

                  const SizedBox(height: 30),

                  // DESCRIPTION
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['description'] == null || item['description'].isEmpty
                        ? "No description provided."
                        : item['description'],
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ACTION BUTTON
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
                      icon: const Icon(LineIcons.envelope, color: Colors.white),
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

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 24),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value ?? 'Not specified',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

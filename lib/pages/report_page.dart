import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:lost_found_app/main.dart'; 

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController(); 
  final _descriptionController = TextEditingController();
  final _collectionNotesController = TextEditingController();

  // State
  String _reportType = 'lost';
  String? _category = 'Electronics';
  bool _isSaving = false;
  File? _imageFile;
  DateTime? _selectedTime;
  
  // Default Map Settings (Centered on Kerala/CUSAT area)
  LatLng _pickedLocation = const LatLng(10.0456, 76.3291); 
  final MapController _mapController = MapController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _collectionNotesController.dispose();
    super.dispose();
  }

  // --- Logic ---

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (selected != null) setState(() => _imageFile = File(selected.path));
  }

  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    setState(() {
      _selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reportType == 'found' && _selectedTime == null) {
      context.showSnackBar('Please select a collection time', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'You must be logged in';

      String? imageUrl;
      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = '${user.id}/$fileName';
        await supabase.storage.from('item-images').upload(path, _imageFile!);
        imageUrl = supabase.storage.from('item-images').getPublicUrl(path);
      }

      final Map<String, dynamic> reportData = {
        'user_id': user.id,
        'type': _reportType,
        'name': _nameController.text.trim(),
        'category': _category,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
      };

      if (_reportType == 'found') {
        reportData['collection_notes'] = _collectionNotesController.text.trim();
        reportData['collection_time'] = _selectedTime?.toIso8601String();
        // PostGIS Format
        reportData['collection_location'] = 'POINT(${_pickedLocation.longitude} ${_pickedLocation.latitude})';
      }

      await supabase.from('items').insert(reportData);

      if (mounted) {
        context.showSnackBar('Report submitted successfully!');
        _resetForm();
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _collectionNotesController.clear();
    setState(() {
      _imageFile = null;
      _reportType = 'lost';
      _selectedTime = null;
      _pickedLocation = const LatLng(10.0456, 76.3291);
    });
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Report", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),

              const Text("Report Type", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildChoiceChip('lost', 'I lost it', LineIcons.search),
                  const SizedBox(width: 12),
                  _buildChoiceChip('found', 'I found it', LineIcons.handHolding),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Item Name", LineIcons.tag),
                validator: (val) => val!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _inputDecoration("Category", LineIcons.list),
                items: ['Electronics', 'Wallets', 'Keys', 'Pets', 'Documents']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setState(() => _category = val),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration("General Area", LineIcons.mapMarker),
                validator: (val) => val!.isEmpty ? 'Location is required' : null,
              ),
              
              // Conditional Found Fields
              if (_reportType == 'found') ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                const Text("Collection Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Map Picker Section
                const Text("Move the map to mark the meeting spot:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _pickedLocation,
                            initialZoom: 15.0,
                            onPositionChanged: (position, hasGesture) {
                              if (hasGesture) {
                                setState(() => _pickedLocation = position.center!);
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.lost_found_app',
                            ),
                          ],
                        ),
                        // Fixed Pin in Center
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 35),
                            child: Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildListTile(
                  icon: LineIcons.calendar,
                  title: _selectedTime == null 
                      ? "Select Meeting Time" 
                      : DateFormat('MMM dd, hh:mm a').format(_selectedTime!),
                  onTap: _pickDateTime,
                  isSet: _selectedTime != null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _collectionNotesController,
                  decoration: _inputDecoration("Specific meeting point (e.g. Lab)", LineIcons.building),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _submitReport,
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: _imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.file(_imageFile!, fit: BoxFit.cover))
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LineIcons.camera, size: 40, color: Colors.black),
                  Text("Add Item Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required VoidCallback onTap, required bool isSet}) {
    return ListTile(
      onTap: onTap,
      tileColor: isSet ? Colors.green[50] : Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSet ? Colors.green : Colors.black, width: 1.2)),
      leading: Icon(icon, color: isSet ? Colors.green : Colors.black),
      title: Text(title, style: TextStyle(fontWeight: isSet ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
    );
  }

  Widget _buildChoiceChip(String value, String label, IconData icon) {
    bool isSelected = _reportType == value;
    return ChoiceChip(
      avatar: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 18),
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) { if (selected) setState(() => _reportType = value); },
      selectedColor: Colors.black,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black)),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
    );
  }
}
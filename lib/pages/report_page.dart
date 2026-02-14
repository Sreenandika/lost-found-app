import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lost_found_app/main.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _reportType = 'lost';
  String? _category = 'Electronics';
  bool _isSaving = false;

  // Image Picking State
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compresses image to save storage space
    );
    if (selected != null) {
      setState(() => _imageFile = File(selected.path));
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'You must be logged in';

      String? imageUrl;

      // 1. Upload image to Supabase Storage if an image was picked
      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = '${user.id}/$fileName';

        await supabase.storage.from('item-images').upload(path, _imageFile!);
        
        // Get the public URL
        imageUrl = supabase.storage.from('item-images').getPublicUrl(path);
      }

      // 2. Insert record into Database
      await supabase.from('items').insert({
        'user_id': user.id,
        'type': _reportType,
        'name': _nameController.text.trim(),
        'category': _category,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl, // Link to the uploaded storage file
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Success!'), backgroundColor: Colors.green),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _locationController.clear();
    _descriptionController.clear();
    setState(() {
      _imageFile = null;
      _reportType = 'lost';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Report an Item", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 20),

              // IMAGE UPLOAD SECTION
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LineIcons.camera, size: 40, color: Colors.black),
                            const SizedBox(height: 8),
                            const Text("Tap to add photo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // MCQ: Lost vs Found
              const Text("Is this item lost or found?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildChoiceChip('lost', 'I lost it', LineIcons.search),
                  const SizedBox(width: 12),
                  _buildChoiceChip('found', 'I found it', LineIcons.handHolding),
                ],
              ),
              const SizedBox(height: 20),

              // Form Fields
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration("Item Name", LineIcons.tag),
                validator: (val) => val!.isEmpty ? 'Enter item name' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _inputDecoration("Category", LineIcons.list),
                items: ['Electronics', 'Wallets', 'Keys', 'Pets', 'Documents']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration("Location", LineIcons.mapMarker),
                validator: (val) => val!.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitReport,
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Report"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String value, String label, IconData icon) {
    bool isSelected = _reportType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) { if (selected) setState(() => _reportType = value); },
      selectedColor: Colors.black,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black)),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: Colors.black),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.5)),
    );
  }
}
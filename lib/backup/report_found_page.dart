import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ReportFoundPage extends StatefulWidget {
  const ReportFoundPage({super.key});

  @override
  State<ReportFoundPage> createState() => _ReportFoundPageState();
}

class _ReportFoundPageState extends State<ReportFoundPage> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final contactController = TextEditingController();

  File? image;

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  Future submitItem() async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://10.127.18.235:3000/add-found-item"),
    );

    request.fields["name"] = nameController.text;
    request.fields["description"] = descController.text;
    request.fields["contact"] = contactController.text;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath("image", image!.path),
      );
    }

    await request.send();
  }

  void deleteForm() {
    nameController.clear();
    descController.clear();
    contactController.clear();
    setState(() => image = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Found Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
            const SizedBox(height: 10),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 10),
            TextField(controller: contactController, decoration: const InputDecoration(labelText: "Contact")),
            const SizedBox(height: 20),

            if (image != null) Image.file(image!, height: 150),

            ElevatedButton(onPressed: pickImage, child: const Text("Upload Image")),
            const SizedBox(height: 20),

            ElevatedButton(onPressed: submitItem, child: const Text("Submit")),
            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: deleteForm,
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }
}

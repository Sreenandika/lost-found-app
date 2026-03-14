import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lost_found_app/components/avatar.dart';
import 'package:lost_found_app/main.dart';
import 'package:lost_found_app/pages/login_page.dart';
import 'package:line_icons/line_icons.dart';
import 'chat_list_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _avatarUrl;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _getProfile() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentSession!.user.id;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _usernameController.text = (data['username'] ?? '') as String;
      _websiteController.text = (data['website'] ?? '') as String;
      _avatarUrl = (data['avatar_url'] ?? '') as String;
    } on PostgrestException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (_) {
      if (mounted)
        context.showSnackBar('Unexpected error occurred', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _loading = true);

    final updates = {
      'id': supabase.auth.currentUser!.id,
      'username': _usernameController.text.trim(),
      'website': _websiteController.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('profiles').upsert(updates);

      if (mounted) context.showSnackBar('Successfully updated profile!');
    } on PostgrestException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (_) {
      if (mounted) context.showSnackBar('Error signing out', isError: true);
    }
  }

  Future<void> _onUpload(String imageUrl) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('profiles').upsert({
        'id': userId,
        'avatar_url': imageUrl,
      });

      setState(() => _avatarUrl = imageUrl);
    } catch (_) {
      if (mounted) context.showSnackBar('Error uploading image', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Profile'),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Settings",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Manage your public profile and preferences.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 32),

                  Center(
                    child: Avatar(imageUrl: _avatarUrl, onUpload: _onUpload),
                  ),

                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: "Full Name",
                      prefixIcon: Icon(LineIcons.user),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      hintText: "Website or Social Link",
                      prefixIcon: Icon(LineIcons.globe),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onUpdatePressed,
                      child: Text(
                        _loading ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Divider(),

                  const SizedBox(height: 10),

                  const Text(
                    "Messages",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(LineIcons.alternateComment, color: Theme.of(context).primaryColor),
                      ),
                      title: const Text("Conversations", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Manage your messages"),
                      trailing: const Icon(LineIcons.angleRight, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatListPage()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Divider(),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,

                    child: TextButton(
                      onPressed: _signOut,

                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),

                      child: const Text(
                        'Sign Out',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _onUpdatePressed() {
    _updateProfile();
  }
}

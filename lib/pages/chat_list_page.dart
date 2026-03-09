import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {

  final supabase = Supabase.instance.client;
  List chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future loadChats() async {

    final userId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('messages')
        .select('item_id, items(*)')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId');

    setState(() {
      chats = data;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),

      body: ListView.builder(
        itemCount: chats.length,

        itemBuilder: (context, index) {

          final item = chats[index]['items'];

          return ListTile(
            title: Text(item['name']),
            subtitle: const Text("Open chat"),

            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(item: item),
                ),
              );

            },
          );
        },
      ),
    );
  }
}
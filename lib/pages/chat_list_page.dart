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
  Map unreadCounts = {};

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future loadChats() async {

    final userId = supabase.auth.currentUser!.id;

    final messages = await supabase
        .from('messages')
        .select('*, items(*)')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);

    Map latestChats = {};
    Map unread = {};

    for (var msg in messages) {

      final itemId = msg['item_id'];

      if (!latestChats.containsKey(itemId)) {
        latestChats[itemId] = msg;
      }

      if (msg['receiver_id'] == userId && msg['is_read'] == false) {
        unread[itemId] = (unread[itemId] ?? 0) + 1;
      }
    }

    setState(() {
      chats = latestChats.values.toList();
      unreadCounts = unread;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text("Messages")),

      body: ListView.builder(

        itemCount: chats.length,

        itemBuilder: (context, index) {

          final chat = chats[index];

          final item = chat['items'];

          final itemId = chat['item_id'];

          final unread = unreadCounts[itemId] ?? 0;

          return ListTile(

            title: Text(item['name']),

            subtitle: Text(chat['message'] ?? ""),

            trailing: unread > 0
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Text(
                      unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,

            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(item: item),
                ),
              ).then((_) {
                loadChats();
              });

            },
          );
        },
      ),
    );
  }
}
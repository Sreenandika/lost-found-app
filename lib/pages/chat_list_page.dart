import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_icons/line_icons.dart';
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
      final otherId = msg['sender_id'] == userId ? msg['receiver_id'] : msg['sender_id'];
      final chatKey = "${itemId}_$otherId";

      if (!latestChats.containsKey(chatKey)) {
        latestChats[chatKey] = {
          'message': msg,
          'other_user_id': otherId,
        };
      }

      if (msg['receiver_id'] == userId && msg['is_read'] == false) {
        unread[chatKey] = (unread[chatKey] ?? 0) + 1;
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

      appBar: AppBar(title: const Text("Conversations")),

      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chatData = chats[index];
          final chat = chatData['message'];
          final otherUserId = chatData['other_user_id'];
          final item = chat['items'];
          final itemId = chat['item_id'];
          final chatKey = "${itemId}_$otherUserId";
          final unread = unreadCounts[chatKey] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LineIcons.comment, color: Color(0xFF006C4C)),
              ),
              title: Text(
                item['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                chat['message'] ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: unread > 0
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Icon(LineIcons.angleRight, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(item: item, receiverId: otherUserId),
                  ),
                ).then((_) {
                  loadChats();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_icons/line_icons.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const ChatPage({super.key, required this.item});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List messages = [];

  String get currentUser => supabase.auth.currentUser!.id;

  late String otherUser;

  @override
  void initState() {
    super.initState();

    otherUser = widget.item['user_id'];

    markMessagesRead();
    subscribeMessages();
  }

  Future markMessagesRead() async {
    await supabase
        .from('messages')
        .update({'is_read': true})
        .eq('item_id', widget.item['id'])
        .eq('receiver_id', currentUser);
  }

  void subscribeMessages() {
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('item_id', widget.item['id'])
        .order('created_at', ascending: true)
        .listen((data) {
          setState(() {
            messages = data;
          });

          Future.delayed(const Duration(milliseconds: 200), () {
            if (scrollController.hasClients) {
              scrollController.jumpTo(
                scrollController.position.maxScrollExtent,
              );
            }
          });
        });
  }

  Future sendMessage() async {
    if (controller.text.trim().isEmpty) return;
    print(currentUser);
    print(otherUser);

    await supabase.from('messages').insert({
      'item_id': widget.item['id'],
      'sender_id': currentUser,
      'receiver_id': otherUser,
      'message': controller.text.trim(),
      'is_read': false,
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(title: Text(widget.item['name'] ?? "Chat")),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,

              padding: const EdgeInsets.all(10),

              itemCount: messages.length,

              itemBuilder: (context, index) {
                final msg = messages[index];

                final isMe = msg['sender_id'] == currentUser;

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF006C4C) : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      msg['message'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF006C4C),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(LineIcons.paperPlane, color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

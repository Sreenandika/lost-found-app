import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                    margin: const EdgeInsets.symmetric(vertical: 5),

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: isMe ? Colors.black : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Text(
                      msg['message'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(10),

              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Type message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
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

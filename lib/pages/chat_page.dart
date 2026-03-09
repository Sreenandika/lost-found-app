import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const ChatPage({super.key, required this.item});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController controller = TextEditingController();

  List messages = [];

  String get currentUser => supabase.auth.currentUser!.id;

  late String otherUser;

  @override
  void initState() {
    super.initState();

    otherUser = widget.item['user_id'];

    loadMessages();
    subscribeMessages();
  }

  Future loadMessages() async {

    final data = await supabase
        .from('messages')
        .select()
        .eq('item_id', widget.item['id'])
        .order('created_at');

    setState(() {
      messages = data;
    });
  }

  void subscribeMessages() {

    supabase.channel('chat_${widget.item['id']}')

      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'item_id',
          value: widget.item['id'],
        ),
        callback: (payload) {

          setState(() {
            messages.add(payload.newRecord);
          });

        },
      ).subscribe();
  }

  Future sendMessage() async {

    if (controller.text.trim().isEmpty) return;

    await supabase.from('messages').insert({
      'item_id': widget.item['id'],
      'sender_id': currentUser,
      'receiver_id': otherUser,
      'message': controller.text.trim(),
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.item['name'] ?? "Chat"),
      ),

      body: Column(

        children: [

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {

                final msg = messages[index];

                final isMe = msg['sender_id'] == currentUser;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
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

          Container(
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

                const SizedBox(width: 10),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )

              ],
            ),
          )
        ],
      ),
    );
  }
}
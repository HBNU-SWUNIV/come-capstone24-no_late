import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;

  MessageInput({required this.onSendMessage});

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'Enter your message'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../model/message_model.dart';

class MessageList extends StatelessWidget {
  final List<MessageModel> messages;

  MessageList({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          title: Align(
            alignment: message.isUserMessage
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: message.isUserMessage
                    ? Colors.blueAccent
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                    color: message.isUserMessage
                        ? Colors.white
                        : Colors.black),
              ),
            ),
          ),
        );
      },
    );
  }
}
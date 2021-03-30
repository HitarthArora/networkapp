import 'package:flutter/material.dart';
import 'package:networkapp/widget/message_reply/lib/model/message.dart';
import 'package:networkapp/const.dart';

class ReplyMessageWidget extends StatelessWidget {
  var message;
  final VoidCallback onCancelReply;

  ReplyMessageWidget({
    @required this.message,
    this.onCancelReply,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      IntrinsicHeight(
        child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(5.0),
            ),
            child: Row(
              children: [
                Container(
                  color: Colors.green,
                  width: 6,
                ),
                const SizedBox(width: 9),
                Expanded(
                    child: buildReplyMessage()),
              ],
            )),
      );

  Widget buildReplyMessage() => Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${message['username']}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              if (onCancelReply != null)
                GestureDetector(
                  child: IconButton(
                    onPressed: onCancelReply,
                    padding: EdgeInsets.all(0.0),
                    color: Colors.white,
                    icon: Icon(
                      Icons.close,
                      color: Colors.redAccent,
                      size: 12.0,
                    ),
                  ),
                  onTap: onCancelReply,
                )
            ],
          ),
          Container(
              margin: EdgeInsets.only(
                  bottom: 8.0, top: 0.0),
              padding: EdgeInsets.all(0.0),
              child: Text(message['message'],
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontStyle:
                          FontStyle.italic))),
        ],
      );
}

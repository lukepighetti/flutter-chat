import 'package:flutter/material.dart';

import 'package:tmi/tmi.dart' as tmi;

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:http/http.dart' as http;

import 'package:dio/dio.dart';

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

class ChatPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final channelName = useState("");
    final userName = useState("");
    final oauthToken = useState("");
    final connected = useState(false);
    // This widget is the home page of your application. It is stateful, meaning
    // that it has a State object (defined below) that contains fields that affect
    // how it looks.

    // This class is the configuration for the state. It holds the values (in this
    // case the title) provided by the parent (in this case the App widget) and
    // used by the build method of the State. Fields in a Widget subclass are
    // always marked "final".

    if (connected.value == false) {
      return Column(children: [
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Choose Channel',
          ),
          onChanged: (current) => channelName.value = current.toString(),
          onSubmitted: (_c) => connected.value = true,
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Username',
          ),
          onChanged: (current) => userName.value = current.toString(),
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Oauth token',
          ),
          onChanged: (current) => oauthToken.value = current.toString(),
        )
      ]);
    }
    return ChatView(channelName.value, userName.value, oauthToken.value);
  }

  @override
  State<ChatView> createState() => _ChatState();
}

class ChatView extends StatefulWidget {
  var channelName;
  var userName;
  var oauthToken;
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  ChatView(this.channelName, this.userName, this.oauthToken);
  // always marked "final".

  @override
  State<ChatView> createState() => _ChatState();
}

class Message {
  var name;
  var body;
  var color;

  Message(this.name, this.body, this.color);
}

class _ChatState extends State<ChatView> {
  List<Message> messages = [];
  var client;

  var channel;

  void initState() {
    this.client = tmi.Client(
      channels: widget.channelName,
      secure: true,
    );

    client.connect();

    client.on("message", (channel, userstate, message, self) {
      if (self) return;

      print("${channel}| ${userstate['display-name']}: ${userstate['color']}");

      var newColor = userstate['color'];
      if (newColor == "") newColor = "#000000";

      setState(() =>
          messages.add(Message(userstate['display-name'], message, newColor)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: messages
                    .map(
                      (e) => RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                                text: "${e.name}: ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: HexColor.fromHex(e.color),
                                )),
                            TextSpan(text: e.body),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          MessageInput(widget.channelName, widget.userName, widget.oauthToken),
        ],
      ),
    );
  }
}

class MessageInput extends HookWidget {
  var channelName;
  var userName;
  var oauthToken;

  var client = http.Client();

  MessageInput(this.channelName, this.userName, this.oauthToken);

  @override
  Widget build(BuildContext context) {
    final message = useState("");
    // This widget is the home page of your application. It is stateful, meaning
    // that it has a State object (defined below) that contains fields that affect
    // how it looks.

    // This class is the configuration for the state. It holds the values (in this
    // case the title) provided by the parent (in this case the App widget) and
    // used by the build method of the State. Fields in a Widget subclass are
    // always marked "final".

    return TextField(
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Choose Channel',
      ),
      onChanged: (current) => message.value = current.toString(),
      onSubmitted: (current) async {
        print("CURRENTLY SENDING");
        print(current);

        var postUrl =
            "https://hacky-chat-sends.vercel.app/api/chat-hell?channel=${channelName}&message=${Uri.encodeComponent(message.value)}&username=${userName}&token=${oauthToken}";

        print(postUrl);

        var res = await Dio().get(postUrl);
        print(res);
      },
    );
  }

  @override
  State<ChatView> createState() => _ChatState();
}

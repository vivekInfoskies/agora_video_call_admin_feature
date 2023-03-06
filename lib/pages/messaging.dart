import 'dart:developer';

import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:agora_interactive_broadcasting/utils/appId.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtm/agora_rtm.dart';

class RealTimeMessaging extends StatefulWidget {
  final String channelName;
  final String userName;
  final bool isBroadcaster;

  const RealTimeMessaging(
      {Key key, this.channelName, this.userName, this.isBroadcaster})
      : super(key: key);

  @override
  _RealTimeMessagingState createState() => _RealTimeMessagingState();
}

class _RealTimeMessagingState extends State<RealTimeMessaging> {
  bool _isLogin = false;
  bool _isInChannel = false;

  final _channelMessageController = TextEditingController();

  final _infoStrings = <String>[];

  AgoraRtmClient _client;
  AgoraRtmChannel _channel;

  @override
  void initState() {
    super.initState();
    _createClient();
    // _initSDK();
    _addChatListener();
  }

  void _signIn() async {
    try {
      await ChatClient.getInstance.logout();
      // await ChatClient.getInstance.createAccount(widget.userName, "1234");
      await ChatClient.getInstance.login(
        "vysagh",
        '1234',
      );

      log("login success");
      _sendMessage();
      _addLogToConsole("login succeed, userId: ");
    } on ChatError catch (e) {
      _addLogToConsole("login failed, code: ${e.code}, desc: ${e.description}");
      log("Login failed");
      log("login failed, code: ${e.code}, desc: ${e.description}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text("Messages"),
          ),
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoList(),
                Container(
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                  child: _buildSendChannelMessage(),
                ),
              ],
            ),
          )),
    );
  }

  void _initSDK() async {
    ChatOptions options = ChatOptions(
      appKey: "61869881#1055439",
      autoLogin: true,
    );
    await ChatClient.getInstance.init(options);

    _signIn();
  }

  void _addChatListener() {
    ChatClient.getInstance.chatManager.addEventHandler(
      "UNIQUE_HANDLER_ID",
      ChatEventHandler(onMessagesReceived: onMessagesReceived),
    );
  }

  void onMessagesReceived(List<ChatMessage> messages) {
    for (var msg in messages) {
      switch (msg.body.type) {
        case MessageType.TXT:
          {
            ChatTextMessageBody body = msg.body as ChatTextMessageBody;
            _addLogToConsole(
              "receive text message: ${body.content}, from: ${msg.from}",
            );
          }
          break;
        case MessageType.IMAGE:
          {
            _addLogToConsole(
              "receive image message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.VIDEO:
          {
            _addLogToConsole(
              "receive video message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.LOCATION:
          {
            _addLogToConsole(
              "receive location message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.VOICE:
          {
            _addLogToConsole(
              "receive voice message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.FILE:
          {
            _addLogToConsole(
              "receive image message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.CUSTOM:
          {
            _addLogToConsole(
              "receive custom message, from: ${msg.from}",
            );
          }
          break;
        case MessageType.CMD:
          {
            // Receiving command messages does not trigger the `onMessagesReceived` event, but triggers the `onCmdMessagesReceived` event instead.
          }
          break;
      }
    }
  }

  final List<String> _logText = [];

  void _addLogToConsole(String log) {
    _logText.add(_timeString + ": " + log);
    setState(() {
      // scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  String get _timeString {
    return DateTime.now().toString().split(".").first;
  }

  void _sendMessage() async {
    var msg = ChatMessage.createTxtSendMessage(
      targetId: widget.channelName,
      content: "helllolooooo",
    );
    msg.setMessageStatusCallBack(MessageStatusCallBack(
      onSuccess: () {
        // _addLogToConsole("send message: $_messageContent");
        log("message sent");
      },
      onError: (e) {
        log("message not sent");

        // _addLogToConsole(
        //   "send message failed, code: ${e.code}, desc: ${e.description}",
        // );
      },
    ));
    ChatClient.getInstance.chatManager.sendMessage(msg);
  }

  void _createClient() async {
    _client = await AgoraRtmClient.createInstance(appId);
    await _toggleLogin();
    await _toggleJoinChannel();
    log(_client.toString());
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      _logPeer(message.text);
    };
    _client.onConnectionStateChanged = (int state, int reason) {
      print('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());
      if (state == 5) {
        _client.logout();
        print('Logout.');
        setState(() {
          _isLogin = false;
        });
      }
    };
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await _client.createChannel(name);
    channel.onMemberJoined = (AgoraRtmMember member) {
      print(
          "Member joined: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMemberLeft = (AgoraRtmMember member) {
      print("Member left: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      _logPeer(message.text);
    };
    return channel;
  }

  Widget _buildSendChannelMessage() {
    if (!_isLogin || !_isInChannel) {
      return Container();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width * 0.75,
          child: TextFormField(
            showCursor: true,
            enableSuggestions: true,
            textCapitalization: TextCapitalization.sentences,
            controller: _channelMessageController,
            decoration: InputDecoration(
              hintText: 'Comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey, width: 2),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(40)),
              border: Border.all(
                color: Colors.blue,
                width: 2,
              )),
          child: IconButton(
            icon: Icon(Icons.send, color: Colors.blue),
            onPressed: _toggleSendChannelMessage,
          ),
        )
      ],
    );
  }

  Widget _buildInfoList() {
    return Expanded(
        child: Container(
            child: _infoStrings.length > 0
                ? ListView.builder(
                    reverse: true,
                    itemBuilder: (context, i) {
                      return Container(
                        child: ListTile(
                          title: Align(
                            alignment: _infoStrings[i].startsWith('%')
                                ? Alignment.bottomLeft
                                : Alignment.bottomRight,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              color: Colors.grey,
                              child: Column(
                                crossAxisAlignment:
                                    _infoStrings[i].startsWith('%')
                                        ? CrossAxisAlignment.start
                                        : CrossAxisAlignment.end,
                                children: [
                                  _infoStrings[i].startsWith('%')
                                      ? Text(
                                          _infoStrings[i].substring(1),
                                          maxLines: 10,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(color: Colors.black),
                                        )
                                      : Text(
                                          _infoStrings[i],
                                          maxLines: 10,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(color: Colors.black),
                                        ),
                                  Text(
                                    widget.userName,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 10,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: _infoStrings.length,
                  )
                : Container()));
  }

  Future<void> _toggleLogin() async {
    if (!_isLogin) {
      try {
        log(widget.userName);
        dynamic user = await _client.login(null, widget.userName.toString());
        log(user.toString());
        print('Login success: ' + widget.userName);
        setState(() {
          _isLogin = true;
        });
      } catch (errorCode) {
        log('Login error: ' + errorCode.toString());
      }
    }
  }

  Future<void> _toggleJoinChannel() async {
    try {
      _channel = await _createChannel(widget.channelName);
      await _channel.join();
      print('Join channel success.');

      setState(() {
        _isInChannel = true;
      });
    } catch (errorCode) {
      print('Join channel error: ' + errorCode.toString());
    }
  }

  void _toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      print('Please input text to send.');
      return;
    }
    try {
      await _channel.sendMessage(AgoraRtmMessage.fromText(text));
      _log(text);
      _channelMessageController.clear();
    } catch (errorCode) {
      print('Send channel message error: ' + errorCode.toString());
    }
  }

  void _logPeer(String info) {
    info = '%' + info;
    print(info);
    setState(() {
      _infoStrings.insert(0, info);
    });
  }

  void _log(String info) {
    print(info);
    setState(() {
      _infoStrings.insert(0, info);
    });
  }
}

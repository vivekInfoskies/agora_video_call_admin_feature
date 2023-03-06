import 'dart:developer';

import 'package:agora_interactive_broadcasting/pages/admin_panel.dart';
import 'package:agora_interactive_broadcasting/pages/messaging.dart';
import 'package:agora_interactive_broadcasting/pages/signaling.dart';
import 'package:agora_interactive_broadcasting/utils/appId.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class BroadcastPage extends StatefulWidget {
  final String channelName;
  final String userName;
  bool isBroadcaster;
  int uid;

  BroadcastPage(
      {Key key, this.channelName, this.userName, this.isBroadcaster, this.uid})
      : super(key: key);

  @override
  _BroadcastPageState createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  List<int> users = <int>[];
  List<int> lobbyUsers = <int>[];
  final _infoStrings = <String>[];
  RtcEngine _engine;
  AgoraRtmClient client;
  AgoraRtmChannel channel;
  bool muted = false;

  @override
  void dispose() {
    // clear users
    users.clear();
    // destroy sdk and leave channel
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
  }

  Future<void> initialize() async {
    print('Client Role: ${widget.isBroadcaster}');
    if (appId.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    client = await AgoraRtmClient.createInstance(appId);
    dynamic user = await client?.login(null, widget.userName.toString());
    log("userrrrrrrrrrrrrrr rtm");
    log(user.toString());

    channel = await client.createChannel(widget.channelName);

    channel.onMemberJoined = (AgoraRtmMember member) {
      print(
          "Member joined: " + member.userId + ', channel: ' + member.channelId);
    };
    channel.onMemberLeft = (AgoraRtmMember member) {
      print("Member left: " + member.userId + ', channel: ' + member.channelId);
    };

    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) async {
      log("==============================message recieved============================");
      List<String> parsedMessage = message.text.split(" ");
      switch (parsedMessage[0]) {
        case "mute":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              muted = true;
            });
            _engine.muteLocalAudioStream(true);
          }
          break;
        case "unmute":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              muted = false;
            });
            _engine.muteLocalAudioStream(false);
          }
          break;
        case "disable":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              // videoDisabled = true;
            });
            _engine.muteLocalVideoStream(true);
          }
          break;
        case "enable":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              // videoDisabled = false;
            });
            _engine.muteLocalVideoStream(false);
          }
          break;
        case "demote":
          log("+++++++++++++++++++++++++++++++++++++++++");
          log("demote");
          // users = Message().parseActiveUsers(uids: parsedMessage[1]);
          users.remove(int.parse(parsedMessage[1]));
          lobbyUsers
              .removeWhere((element) => element == int.parse(parsedMessage[1]));
          lobbyUsers.add(int.parse(parsedMessage[1]));
          if (int.parse(parsedMessage[1]) == widget.uid) {
            await _engine.setClientRole(ClientRole.Audience);
            widget.isBroadcaster = false;
            log("widget brodcaster changed =========");
          }

          setState(() {
            log("=========================setstate worked====================");
          });
          break;

        case "promote":
          log("+++++++++++++++++++++++++++++++++++++++++");
          log("promote");
          // users = Message().parseActiveUsers(uids: parsedMessage[1]);
          // users
          //     .removeWhere((element) => element == int.parse(parsedMessage[1]));
          log(parsedMessage[1]);
          if (int.parse(parsedMessage[1]) != widget.uid) {
            users.add(int.parse(parsedMessage[1]));
          }

          log("jldjljfkldjlkfjd klf");
          log(users.toString());
          lobbyUsers.remove(int.parse(parsedMessage[1]));
          if (int.parse(parsedMessage[1]) == widget.uid) {
            await _engine.setClientRole(ClientRole.Broadcaster);
            widget.isBroadcaster = true;
            log("widget brodcaster changed to true =========");
          }

          setState(() {
            log("=========================setstate worked====================");
          });
          break;
        default:
      }
      print("Public Message from " +
          member.userId +
          ": " +
          (message.text ?? "null"));
    };

    await _engine.joinChannel(null, widget.channelName, null, widget.uid);

    await channel.join();
    // print("UID when joining int ${uid} and string ${uid.toString()}");
    // await _engine.joinChannel(
    //     null, widget.channelName, null, 4, ChannelMediaOptions());
  }

  removeUser(int userId, bool add) {
    log(userId.toString());
    print(users);
    if (add) {
      setState(() {
        users.remove(userId);
        lobbyUsers.removeWhere((element) => element == userId);
        lobbyUsers.add(userId);
      });
    } else {
      setState(() {
        users.removeWhere((element) => element == userId);
        users.add(userId);
        lobbyUsers.remove(userId);
      });
    }
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(appId);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    if (widget.isBroadcaster) {
      await _engine.setClientRole(
        ClientRole.Broadcaster,
      );
    } else {
      await _engine.setClientRole(ClientRole.Audience);
    }
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    }, joinChannelSuccess: (channel, uid, elapsed) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
        uid = uid;
      });
    }, leaveChannel: (stats) {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        users.clear();
      });
    }, userJoined: (uid, elapsed) {
      log("PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP");
      log("User joined worked");
      setState(() {
        final info = 'userJoined: $uid';
        _infoStrings.add(info);
        if (uid != widget.uid) {
          users.add(uid);
        }
        // users.remove(uid);

        lobbyUsers.remove(uid);
      });
    }, userOffline: (uid, elapsed) {
      log("user offline worked");
      setState(() {
        final info = 'userOffline: $uid';
        _infoStrings.add(info);
        users.remove(uid);
        lobbyUsers.add(uid);
      });
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      });
    }));
  }

  Widget _toolbar() {
    return widget.isBroadcaster
        ? Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Wrap(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RawMaterialButton(
                  onPressed: _onToggleMute,
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
                RawMaterialButton(
                  onPressed: () => _onCallEnd(context),
                  child: Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 35.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.redAccent,
                  padding: const EdgeInsets.all(15.0),
                ),
                RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  child: Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
                RawMaterialButton(
                  onPressed: _goToChatPage,
                  child: Icon(
                    Icons.message_rounded,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
                RawMaterialButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AdminPanel(
                            uid: users,
                            client: client,
                            channel: channel,
                            lobyUsers: lobbyUsers,
                            removeUser: removeUser)));
                  },
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
              ],
            ),
          )
        : Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(bottom: 48),
            child: RawMaterialButton(
              onPressed: _goToChatPage,
              child: Icon(
                Icons.message_rounded,
                color: Colors.blueAccent,
                size: 20.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    log("=================rebuild worked================");
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            _viewRows(),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    log("===========length===============");
    log(users.length.toString());
    final List<StatefulWidget> list = [];
    if (widget.isBroadcaster) {
      list.add(RtcLocalView.SurfaceView());
    }
    users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(
          uid: uid,
          channelId: "",
        )));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
    }
    return Container();
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void _goToChatPage() {
    log(widget.uid.toString());
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => RealTimeMessaging(
        channelName: widget.channelName,
        userName: widget.userName,
        isBroadcaster: widget.isBroadcaster,
        // client: client,
        // channel: channel,
      ),
    ));
  }
}

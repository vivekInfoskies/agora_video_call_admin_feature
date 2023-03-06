import 'dart:developer';

import 'package:agora_interactive_broadcasting/pages/signaling.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class AdminPanel extends StatefulWidget {
  AdminPanel(
      {Key key,
      this.uid,
      this.channel,
      this.client,
      this.removeUser,
      this.lobyUsers})
      : super(key: key);
  List<int> uid;
  List<int> lobyUsers;
  final AgoraRtmClient client;
  final AgoraRtmChannel channel;
  final Function(int, bool) removeUser;

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  @override
  Widget build(BuildContext context) {
    log("users");

    log(widget.uid.length.toString());
    log("loby users");
    log(widget.lobyUsers.length.toString());
    log("}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}");
    return Scaffold(
      body: Column(
        children: [
          ...widget.uid
              .map((e) => SizedBox(
                    height: 100,
                    width: 100,
                    child: Column(
                      children: [
                        Expanded(
                          child: RtcRemoteView.SurfaceView(
                            uid: e,
                            channelId: "",
                          ),
                        ),
                        RawMaterialButton(
                            child: Icon(Icons.delete),
                            onPressed: () async {
                              await widget.channel.sendMessage(
                                  AgoraRtmMessage.fromText(
                                      Message().sendDemote(uid: e)));

                              log("=========message sent=========");
                              // widget.removeUser(e, true);

                              // widget.lobyUsers.add(e);
                              // widget.uid.remove(e);
                              setState(() {});
                            })
                      ],
                    ),
                  ))
              .toList(),
          Text(
            "Lobby",
            style: TextStyle(color: Colors.red, fontSize: 32),
          ),
          ...widget.lobyUsers
              .map((e) => SizedBox(
                    height: 100,
                    width: 100,
                    child: Column(
                      children: [
                        Expanded(
                          child: RtcRemoteView.SurfaceView(
                            uid: e,
                            channelId: "",
                          ),
                        ),
                        RawMaterialButton(
                            child: Icon(Icons.delete),
                            onPressed: () async {
                              await widget.channel.sendMessage(
                                  AgoraRtmMessage.fromText(
                                      Message().sendPromote(uid: e)));

                              log("=========message sent=========");
                              // widget.removeUser(e, false);
                              // widget.lobyUsers.remove(e);
                              // widget.uid.add(e);
                              setState(() {});
                            })
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}

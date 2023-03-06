import 'dart:developer';

class Message {
  String sendMuteMessage({int uid, bool mute}) {
    if (mute) {
      return "mute $uid";
    } else {
      return "unmute $uid";
    }
  }

  String sendDemote({int uid}) {
    return "demote $uid";
  }
 String sendPromote({int uid}) {
    return "promote $uid";
  }

  String sendDisableVideoMessage({int uid, bool enable}) {
    if (enable) {
      return "enable $uid";
    } else {
      return "disable $uid";
    }
  }

  String sendActiveUsers(List<int> activeUsers) {
    log("================================");
    String _userString = "demote ";
    for (int i = 0; i < activeUsers.length; i++) {
      _userString = _userString + activeUsers.elementAt(i).toString() + ",";
    }
    log(_userString);
    return _userString;
  }

  List<int> parseActiveUsers({String uids}) {
    List<String> activeUsers = uids.split(",");
    List<int> users;

    for (int i = 0; i < activeUsers.length; i++) {
      if (activeUsers[i] == "") continue;
      users.add(int.parse(
        activeUsers[i],
      ));
    }
    print(users);
    return users;
  }
}

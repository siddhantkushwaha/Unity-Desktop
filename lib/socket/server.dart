import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:realm/realm.dart';
import 'package:unity/dbHelper.dart';
import 'package:unity/realmUtils.dart';
import 'package:unity/util.dart';
import 'package:unity/socket/client.dart';

class SocketServer {
  int port;

  Realm realm = getRealm();

  final clipboardConnection = SocketClient(8000);

  SocketServer(this.port);

  void init() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    debugPrint('Starting Unity server on port [$port].');
    server.listen((client) {
      handle(client);
    });
  }

  void handle(Socket client) {
    client.listen(
      (Uint8List data) {
        final message = String.fromCharCodes(data);
        final messageObject = json.decode(message);
        final response = handleMessageObject(messageObject);
        client.write(response);
        client.close();
      },
      onError: (error) {
        debugPrint(error);
        client.close();
      },
      onDone: () {
        client.close();
      },
    );
  }

  String handleMessageObject(messageObject) {
    debugPrint(messageObject);
    final messageType = messageObject['messageType'];
    switch (messageType) {

      // syncMessage types should be shared with other connected devices
      case 'syncMessage':
        final updateMessage = messageObject['updateMessage'];
        final type = updateMessage['type'];
        switch (type) {
          case 1:
            var text = updateMessage['text'];
            var newText = processText(text);
            addTextItemToDb(realm, newText);
            if (newText != text) {
              clipboardConnection.copyTextToClipboard(newText);
            }
            break;
          default:
            break;
        }
        break;

      default:
        break;
    }
    return '{"status": 0}';
  }
}

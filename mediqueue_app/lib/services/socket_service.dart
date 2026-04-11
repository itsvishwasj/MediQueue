import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api.dart';

class SocketService {
  static IO.Socket? _socket;

  static void connect() {
    _socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  static void joinQueue(String doctorId) {
    _socket?.emit('joinQueue', doctorId);
  }

  static void leaveQueue(String doctorId) {
    _socket?.emit('leaveQueue', doctorId);
  }

  static void onQueueUpdate(String doctorId, Function(dynamic) callback) {
    _socket?.on('queue:$doctorId', callback);
  }

  static void offQueueUpdate(String doctorId) {
    _socket?.off('queue:$doctorId');
  }

  static void disconnect() {
    _socket?.disconnect();
  }
}

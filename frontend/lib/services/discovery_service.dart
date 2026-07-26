import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DiscoveryResult {
  final String ip;
  final int port;
  DiscoveryResult(this.ip, this.port);
}

class DiscoveryService {
  static const int discoveryPort = 42069;
  static const String discoveryMsg = 'OUTDOOR_DISCOVER';
  static const Duration timeout = Duration(seconds: 3);

  static Future<DiscoveryResult?> discoverServer() async {
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;

      final data = utf8.encode(discoveryMsg);
      socket.send(
        data,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );

      final completer = Completer<DiscoveryResult?>();
      final timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
          socket.close();
        }
      });

      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null) return;
        try {
          final msg = utf8.decode(datagram.data);
          final info = jsonDecode(msg);
          if (info is Map && info['ip'] != null && info['port'] != null) {
            if (!completer.isCompleted) {
              completer.complete(DiscoveryResult(info['ip'], info['port']));
              timer.cancel();
              socket.close();
            }
          }
        } catch (_) {}
      });

      return completer.future;
    } catch (e) {
      return null;
    }
  }
}

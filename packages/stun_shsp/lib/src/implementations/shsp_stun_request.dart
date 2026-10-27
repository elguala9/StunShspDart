import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:shsp/shsp.dart';
import 'package:stun/stun.dart';

/// Performs a STUN Binding Request over an [IShspSocket] without listening on
/// it.
///
/// `StunHandler` reads its answer by calling `listen()` on the socket. An SHSP
/// socket already holds the single subscription of its raw socket, so that
/// call throws, and `stun` "recovers" by closing the shared socket and binding
/// a private one — after which every STUN answer describes a port SHSP does not
/// listen on. Here the request is sent with [IShspSocket.sendTo] and the answer
/// is taken from the socket's own dispatch, through a message callback keyed on
/// the STUN server's address, so the socket keeps a single reader.
Future<StunResponse> performShspStunRequest(
  IShspSocket socket, {
  required String stunAddress,
  required int stunPort,
  required Duration timeout,
}) async {
  final type = socket.socket.address.type;
  final addresses = await InternetAddress.lookup(stunAddress, type: type);
  if (addresses.isEmpty) {
    throw StateError('Could not resolve STUN server address: $stunAddress');
  }
  final server = PeerInfo(address: addresses.first, port: stunPort);
  final request = StunMessage.createBindingRequest();
  final completer = Completer<StunResponse>();

  void onDatagram(MessageRecord record) {
    final response = _parseResponse(record.msg, request.transactionId, type);
    if (response != null && !completer.isCompleted) {
      completer.complete(response);
    }
  }

  socket.setMessageCallback(server, onDatagram);
  try {
    if (socket.sendTo(request.toBytes(), server) == 0) {
      throw StateError('STUN request not sent: the SHSP socket is closed');
    }
    return await completer.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'STUN request timed out after ${timeout.inSeconds}s',
      ),
    );
  } finally {
    socket.removeMessageCallback(server, onDatagram);
  }
}

/// Parses [data] as the Binding Response to [transactionId], or returns null
/// when it is anything else (a stray or late datagram from the same server).
StunResponse? _parseResponse(
  List<int> data,
  Uint8List transactionId,
  InternetAddressType type,
) {
  final StunMessage message;
  try {
    message = StunMessage.fromBytes(Uint8List.fromList(data));
  } on Object {
    return null;
  }
  if (!_sameBytes(message.transactionId, transactionId)) {
    return null;
  }
  final mapped = message.getXorMappedAddress();
  if (mapped == null) {
    return null;
  }
  return StunResponse((
    publicIp: mapped.ip,
    publicPort: mapped.port,
    ipVersion: type == InternetAddressType.IPv6 ? IpVersion.v6 : IpVersion.v4,
    transactionId: message.transactionId,
    raw: Uint8List.fromList(data),
    attrs: <String, dynamic>{'transactionId': message.transactionId},
  ), null);
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

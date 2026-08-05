import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() {
  group('IStunShspHandler — resolved from the registry', () {
    const key = 'integration_single';
    late IStunShspHandler handler;

    setUpAll(() async {
      await initializeStunShsp(key: key);
      handler = RegistryManager.instance.getInstance<IStunShspHandler>(
        key: key,
        subkey: 'ipv4',
      );
    });

    tearDownAll(() {
      if (!handler.isClosed) handler.destroy();
    });

    test('is a StunShspHandler over an open socket', () {
      expect(handler, isA<StunShspHandler>());
      expect(handler.shspSocket, isA<IShspSocketMigratable>());
      expect(handler.shspSocket.isClosed, isFalse);
      expect(handler.shspSocket.localPort, greaterThan(0));
    });

    test('both halves are reachable, on one endpoint', () {
      expect(handler.stunHandler.getSocket().port,
          equals(handler.shspSocket.localPort));
      expect(handler.getSocket(), same(handler.stunHandler.getSocket()));
      expect(handler.getIpVersion(), InternetAddressType.IPv4);
    });

    test('the RawDatagramSocket surface reads through to the socket', () {
      expect(handler.port, equals(handler.shspSocket.localPort));
      expect(handler.address, equals(handler.shspSocket.localAddress));
      expect(handler.address.type, InternetAddressType.IPv4);
    });

    test('the socket surface reads through to the socket', () {
      expect(handler.localAddress, equals(handler.shspSocket.localAddress));
      expect(handler.localPort, equals(handler.shspSocket.localPort));
      expect(handler.compressionCodec, same(handler.shspSocket.compressionCodec));
      expect(handler.isClosed, isFalse);
    });

    test('extractProfile carries the registered callbacks', () {
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9801);
      final peerKey = MessageCallbackMap.formatKey(peer.address, peer.port);

      void callback(MessageRecord _) {}
      handler.setMessageCallback(peer, callback);

      expect(handler.extractProfile().messageListeners.keys,
          contains(peerKey));
      expect(handler.removeMessageCallback(peer, callback), isTrue);
      expect(handler.extractProfile().messageListeners.keys,
          isNot(contains(peerKey)));
    });

    test('migrateSocket moves both halves onto the new socket', () async {
      final newSocket = await ShspSocket.bindDefault(ipv6: false);
      handler.migrateSocket(newSocket);

      expect(handler.isClosed, isFalse);
      expect(handler.localPort, equals(newSocket.localPort));
      expect(handler.getSocket().port, equals(newSocket.localPort));
    });
  });

  group('IDualStunShspHandler — resolved from the registry', () {
    const key = 'integration_dual';
    late IDualStunShspHandler dual;

    setUpAll(() async {
      await initializeStunShsp(key: key);
      dual = RegistryManager.instance.getInstance<IDualStunShspHandler>(
        key: key,
      );
    });

    tearDownAll(() {
      if (!dual.isClosed) dual.destroy();
    });

    test('is a dual SHSP socket', () {
      expect(dual, isA<DualShspSocket>());
      expect(dual.getSocket(InternetAddressType.IPv4), isNotNull);
      expect(dual.getSocket(InternetAddressType.IPv4)!.isClosed, isFalse);
    });

    test('exposes the dual STUN handler over the combined handlers', () {
      expect(dual.dualStunHandler, isA<DualStunHandler>());
      expect(dual.dualStunHandler.ipv4Handler, same(dual.ipv4StunShspHandler));
      expect(dual.dualStunHandler.ipv6Handler, same(dual.ipv6StunShspHandler));
    });

    test('the STUN half is bound to the SHSP sockets', () {
      expect(
        dual.dualStunHandler.getSocket(type: InternetAddressType.IPv4).port,
        equals(dual.getSocket(InternetAddressType.IPv4)!.localPort),
      );
    });

    test('the IPv6 half follows what the host supports', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      if (hasIPv6) {
        expect(dual.getSocket(InternetAddressType.IPv6), isNotNull);
        expect(dual.ipv6StunShspHandler, isNotNull);
      } else {
        expect(dual.getSocket(InternetAddressType.IPv6), isNull);
        expect(dual.ipv6StunShspHandler, isNull);
      }
    });

    test('repeated resolution returns the cached singleton', () {
      expect(
        RegistryManager.instance.getInstance<IDualStunShspHandler>(key: key),
        same(dual),
      );
    });
  });
}

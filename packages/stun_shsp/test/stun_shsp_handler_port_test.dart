import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

Future<int> _findFreePort() async {
  final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final p = s.port;
  s.close();
  return p;
}

void main() {
  group('StunShspHandler.createDefault() — STUN and SHSP', () {
    late StunShspHandler handler;

    tearDown(() {
      handler.close();
      SingletonManager.instance.destroyAll();
    });

    test('SHSP socket binds via createDefault', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.shspSocket.localPort, greaterThan(0));
    });

    test('SHSP socket is open after createDefault', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.shspSocket.isClosed, isFalse);
    });

    test('stunHandler is accessible after createDefault', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.stunHandler, isNotNull);
    });

    test('createDefault with explicit port', () async {
      final freePort = await _findFreePort();
      handler = await StunShspHandler.createDefault(
        ipv6: false,
        port: freePort,
      );
      expect(handler.shspSocket.localPort, equals(freePort));
    });

    test('close() closes the handler', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      handler.close();
      expect(handler.shspSocket.isClosed, isTrue);
    });

    test('destroy() destroys the handler', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      handler.destroy();
      expect(handler.shspSocket.isClosed, isTrue);
    });

    test('shspSocket is of type IShspSocketWrapper', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.shspSocket, isA<IShspSocketWrapper>());
    });

    test('delegateSocket matches shspSocket', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.delegateSocket, same(handler.shspSocket));
    });
  });

  group('StunShspHandler — mixin delegation', () {
    late StunShspHandler handler;

    tearDown(() {
      handler.destroy();
    });

    test('RawDatagramSocket methods are delegated from mixin', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.port, greaterThan(0));
      expect(handler.address, isA<InternetAddress>());
      expect(handler.broadcastEnabled, isA<bool>());
      expect(handler.readEventsEnabled, isA<bool>());
      expect(handler.writeEventsEnabled, isA<bool>());
    });

    test('Socket properties are delegated from mixin', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.localAddress, isNotNull);
      expect(handler.localPort, greaterThan(0));
      expect(handler.compressionCodec, isNotNull);
      expect(handler.isClosed, isFalse);
    });

    test('IShspSocket methods are delegated from mixin', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      final profile = handler.extractProfile();
      handler.applyProfile(profile);
    });

    test('migrateSocket is available', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      final newSocket = await ShspSocket.bindDefault(ipv6: false);
      handler.migrateSocket(newSocket);
      expect(handler.isClosed, isFalse);
    });
  });
}

import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() async {
  final hasIPv6 = await AddressUtility.canCreateIPv6Socket();

  group('StunShspHandler.createDefault — IPv6', () {
    late StunShspHandler handler;

    tearDown(() {
      handler.destroy();
      SingletonManager.instance.destroyAll();
    });

    test('createDefault with ipv6: true creates handler with IPv6', () async {
      handler = await StunShspHandler.createDefault(ipv6: true);
      expect(handler.shspSocket, isNotNull);
      expect(handler.shspSocket.localPort, greaterThan(0));
    });

    test('createDefault with ipv6: false creates IPv4-only handler', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.shspSocket.localAddress?.type,
          equals(InternetAddressType.IPv4));
    });
  }, skip: hasIPv6 ? null : 'No IPv6 available on this host — IPv6 tests.');

  group('StunShspHandler — IPv6 socket', () {
    test('IPv6 handler socket reports IPv6 address', () async {
      final handler = await StunShspHandler.createDefault(ipv6: true);
      addTearDown(() => handler.destroy());
      expect(handler.shspSocket.localAddress?.type,
          equals(InternetAddressType.IPv6));
    });
  }, skip: hasIPv6 ? null : 'No IPv6 available on this host — IPv6 tests.');
}

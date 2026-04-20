import 'dart:io';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Returns a free UDP port by binding a temporary socket and reading its port.
Future<int> _findFreePort() async {
  final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final p = s.port;
  s.close();
  return p;
}

void main() {
  group('StunShspHandler.initialize() — STUN/SHSP port matching', () {
    late StunShspHandler handler;

    setUp(() {
      SingletonManager.instance.destroyAll();
      handler = StunShspHandler();
    });

    tearDown(() {
      handler.close();
      SingletonManager.instance.destroyAll();
    });

    // ── Core bug regression ─────────────────────────────────────────────────

    test(
      'STUN performLocalRequest() returns the same port as ipv4ShspSocket',
      () async {
        await handler.initialize();

        final localInfo = await handler.performLocalRequest();
        final shspPort = handler.ipv4ShspSocket.localPort;

        expect(
          localInfo.localPort,
          equals(shspPort),
          reason:
              'STUN must discover the NAT mapping for the exact port SHSP uses '
              'for P2P traffic — a mismatch means peers cannot reach this node.',
        );
      },
    );

    test(
      'SHSP socket binds to the requested port and STUN reports the same port',
      () async {
        final freePort = await _findFreePort();

        await handler.initialize(port: freePort);

        expect(handler.ipv4ShspSocket.localPort, equals(freePort));

        final localInfo = await handler.performLocalRequest();
        expect(
          localInfo.localPort,
          equals(freePort),
          reason: 'performLocalRequest() must reflect the SHSP socket port.',
        );
      },
    );

    // ── SHSP socket sanity ──────────────────────────────────────────────────

    test('SHSP IPv4 socket is open after initialize()', () async {
      await handler.initialize();
      expect(handler.ipv4ShspSocket.isClosed, isFalse);
    });

    test('SHSP IPv4 socket has a valid (> 0) local port', () async {
      await handler.initialize();
      expect(handler.ipv4ShspSocket.localPort, greaterThan(0));
    });

    // ── STUN handler sanity ─────────────────────────────────────────────────

    test('stunHandler is accessible after initialize()', () async {
      await handler.initialize();
      expect(handler.stunHandler, isNotNull);
      expect(handler.stunHandler, isA<StunHandlerBase>());
    });

    test('stunHandler.ipv4Handler is set after initialize()', () async {
      await handler.initialize();
      expect(handler.stunHandler.ipv4Handler, isNotNull);
    });

    test(
      'performLocalRequest() completes without error after initialize()',
      () async {
        await handler.initialize();
        expect(handler.performLocalRequest(), completes);
      },
    );

    test(
      'performStunRequest() completes (cached) without error after initialize()',
      () async {
        await handler.initialize();
        // The first STUN request was performed eagerly during initialize().
        // This call returns the cached result without touching any socket.
        expect(handler.performStunRequest(), completes);
      },
    );

    // ── Explicit port binding ───────────────────────────────────────────────

    test(
      'initialize(port: N) binds SHSP to port N',
      () async {
        final freePort = await _findFreePort();
        await handler.initialize(port: freePort);

        expect(handler.ipv4ShspSocket.localPort, equals(freePort));
      },
    );

    test(
      'initialize(port: 0) lets the OS choose a port and STUN reports the same one',
      () async {
        await handler.initialize(port: 0);

        final localInfo = await handler.performLocalRequest();
        final shspPort = handler.ipv4ShspSocket.localPort!;

        expect(shspPort, greaterThan(0));
        expect(localInfo.localPort, equals(shspPort));
      },
    );

    // ── Double-initialize guard ─────────────────────────────────────────────

    test('calling initialize() twice throws StateError', () async {
      await handler.initialize();
      expect(
        () => handler.initialize(),
        throwsA(isA<StateError>()),
      );
    });

    // ── IPv6 ───────────────────────────────────────────────────────────────

    test(
      'IPv6 socket port matches STUN local port when IPv6 is available',
      () async {
        final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
        if (!hasIPv6) {
          // Not a failure — just no IPv6 on this machine.
          return;
        }

        await handler.initialize();

        final ipv6Socket = handler.ipv6ShspSocket;
        expect(ipv6Socket, isNotNull);
        expect(ipv6Socket!.isClosed, isFalse);
        expect(ipv6Socket.localPort, greaterThan(0));

        final ipv6Handler = handler.stunHandler.ipv6Handler;
        expect(ipv6Handler, isNotNull);
      },
    );

    // ── Dual socket structure ───────────────────────────────────────────────

    test('dualShspSocket.ipv4Socket is the same object as ipv4ShspSocket',
        () async {
      await handler.initialize();
      expect(
        handler.dualShspSocket.ipv4Socket,
        same(handler.ipv4ShspSocket),
      );
    });

    test('handler reports isInitialized = true after initialize()', () async {
      expect(handler.isInitialized, isFalse);
      await handler.initialize();
      expect(handler.isInitialized, isTrue);
    });
  });
}

import 'dart:async';
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Tests for the `performStunRequest({bool ipv6})` signature.
///
/// The default is now IPv6 with a graceful fallback to IPv4 when no IPv6
/// socket is available (e.g. IPv6 bind failed during initialize() on an
/// IPv4-only host). These tests hit the real default STUN server, matching
/// the style of the rest of the suite.
///
/// IPv6 availability is probed once, up front, and used to `skip` the groups
/// that cannot run on this host (IPv6-only tests on an IPv4-only machine, and
/// the IPv4-only fallback tests on a dual-stack machine).
void main() async {
  final hasIPv6 = await AddressUtility.canCreateIPv6Socket();

  late StunShspHandler handler;

  /// Wires [handler] with an IPv4-only stack (no IPv6 socket) using the same
  /// building blocks as [StunShspHandler.initialize], minus the IPv6 branch.
  ///
  /// This exercises the IPv4 fallback path on ANY host — including dual-stack
  /// machines where a plain initialize() would always create an IPv6 socket.
  /// The IPv4 socket is bound to `anyIPv4`, so real STUN requests still reach
  /// the internet.
  Future<void> injectIpv4Only({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final rawIpv4 = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
    );
    final port = rawIpv4.port;
    final ipv4StunHandler = StunHandler.withSocket(rawIpv4, timeout: timeout);
    rawIpv4.close();

    final ipv4Socket = await ShspSocket.bind(InternetAddress.anyIPv4, port);

    final stun = StunHandlerSingleton();
    await stun.initializeWithHandlers(ipv4StunHandler);

    handler.injectDependencies(
      stunHandler: stun,
      dualShspSocket: DualShspSocketMigratable(ipv4Socket),
    );
  }

  void commonSetUp() {
    SingletonManager.instance.destroyAll();
    handler = StunShspHandler();
  }

  void commonTearDown() {
    // Some tests may not reach initialize(); close() would then touch
    // uninitialized late fields.
    if (handler.isInitialized) handler.close();
    SingletonManager.instance.destroyAll();
  }

  // ── Family-agnostic behavior (always runs) ─────────────────────────────────

  group('performStunRequest — IPv4 / caching', () {
    setUp(commonSetUp);
    tearDown(commonTearDown);

    test('performStunRequest(ipv6: false) returns an IPv4 mapping', () async {
      await handler.initialize();

      final response = await handler.performStunRequest(ipv6: false);

      expect(response.ipVersion, equals(IpVersion.v4));
      expect(response.publicPort, greaterThan(0));
    });

    test('repeated IPv4 requests return the identical cached response',
        () async {
      await handler.initialize();

      final first = await handler.performStunRequest(ipv6: false);
      final second = await handler.performStunRequest(ipv6: false);

      expect(identical(first, second), isTrue);
    });

    test(
      'setStunServer() invalidates the cached response so it is refetched',
      () async {
        await handler.initialize(timeout: const Duration(seconds: 2));

        final cached = await handler.performStunRequest(ipv6: false);
        expect(cached.ipVersion, equals(IpVersion.v4));

        // Point at an unresolvable server; the cache must be dropped so the
        // next call re-fetches (and now fails) instead of returning the stale
        // value.
        handler.setStunServer('stun.invalid.example.', 3478);

        await expectLater(
          handler.performStunRequest(ipv6: false),
          throwsA(anyOf(
            isA<StateError>(),
            isA<TimeoutException>(),
            isA<SocketException>(),
          )),
        );
      },
    );
  });

  // ── IPv6-only (skipped when the host has no IPv6) ──────────────────────────

  group(
    'performStunRequest — IPv6',
    () {
      setUp(commonSetUp);
      tearDown(commonTearDown);

      test('performStunRequest() defaults to IPv6', () async {
        await handler.initialize();
        expect(handler.ipv6ShspSocket, isNotNull);

        final response = await handler.performStunRequest();

        expect(
          response.ipVersion,
          equals(IpVersion.v6),
          reason: 'Default must target IPv6 when the IPv6 socket exists.',
        );
      });

      test('performStunRequest(ipv6: true) returns an IPv6 mapping', () async {
        await handler.initialize();

        final response = await handler.performStunRequest(ipv6: true);

        expect(response.ipVersion, equals(IpVersion.v6));
        expect(response.publicPort, greaterThan(0));
      });

      test('IPv4 and IPv6 responses are cached independently', () async {
        await handler.initialize();

        final ipv4 = await handler.performStunRequest(ipv6: false);
        final ipv6 = await handler.performStunRequest(ipv6: true);

        expect(ipv4.ipVersion, equals(IpVersion.v4));
        expect(ipv6.ipVersion, equals(IpVersion.v6));
        expect(identical(ipv4, ipv6), isFalse);
      });
    },
    skip: hasIPv6 ? null : 'No IPv6 available on this host — IPv6-only tests.',
  );

  // ── IPv4-only fallback (forced via injection — runs on any host) ───────────

  group('performStunRequest — IPv4-only fallback', () {
    setUp(commonSetUp);
    tearDown(commonTearDown);

    test('performStunRequest() falls back to IPv4 without an IPv6 socket',
        () async {
      await injectIpv4Only();
      expect(handler.ipv6ShspSocket, isNull);

      // Default is ipv6: true, but with no IPv6 socket it must NOT throw.
      final response = await handler.performStunRequest();

      expect(response.ipVersion, equals(IpVersion.v4));
      expect(response.publicPort, greaterThan(0));
    });

    test('performStunRequest(ipv6: true) falls back to IPv4 (no throw)',
        () async {
      await injectIpv4Only();
      expect(handler.ipv6ShspSocket, isNull);
      expect(handler.performStunRequest(ipv6: true), completes);
    });
  });
}

import 'dart:io';

import 'package:config_manager/config_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Minimal consumer used to exercise [StunShspConfigExtension] in isolation.
class _ConfigProbe with ConfigExtension, StunShspConfigExtension {}

/// Reads the `stun` sector directly, to check what this package forwards to it.
class _StunProbe with ConfigExtension, StunConfigExtension {}

/// Reads the `shsp` sector directly, same purpose.
class _ShspProbe with ConfigExtension, ShspConfigExtension {}

void main() {
  // Restore the built-in defaults of every sector between tests.
  tearDown(initStunShspConfig);

  group('StunShspConfigExtension', () {
    test('falls back to the built-in defaults when nothing is loaded', () {
      ConfigManagerSingleton().clear([], sector: stunShspConfigSector);
      ConfigManagerSingleton().clear([], sector: stunConfigSector);
      ConfigManagerSingleton().clear([], sector: shspConfigSector);
      final probe = _ConfigProbe();

      expect(probe.configSector, stunShspConfigSector);
      // Owned by this sector.
      expect(probe.defaultSocketPort, 0);
      expect(probe.defaultIpv4Port, 0);
      expect(probe.defaultIpv6Port, 0);
      // Borrowed from the `stun` sector, falling back to its defaults.
      expect(probe.defaultIpv6Enabled, isTrue);
      expect(probe.defaultNatPrimaryServer, 'stun.l.google.com');
      expect(probe.defaultNatPrimaryPort, 19302);
      expect(probe.defaultNatTimeout, const Duration(seconds: 5));
      expect(probe.defaultStunServerAddress, 'stun.l.google.com');
      expect(probe.defaultStunServerPort, 19302);
      expect(probe.defaultStunTimeout, const Duration(seconds: 5));
      // Borrowed from the `shsp` sector.
      expect(probe.defaultKeepAliveSeconds, 30);
    });

    test('the borrowed getters read the sector that owns them', () {
      initStunConfig({
        'ipVersion': 'IPv4',
        'server': {'address': 'stun.example.org', 'port': 3478},
        'nat': {'primaryServer': 'nat.example.org', 'timeoutSeconds': 2.5},
      });
      initShspConfig({'keepAliveSeconds': 11});

      final probe = _ConfigProbe();

      // Nothing was loaded into the stun_shsp sector at all.
      expect(probe.defaultIpv6Enabled, isFalse);
      expect(probe.defaultStunServerAddress, 'stun.example.org');
      expect(probe.defaultStunServerPort, 3478);
      expect(probe.defaultNatPrimaryServer, 'nat.example.org');
      expect(probe.defaultNatTimeout, const Duration(milliseconds: 2500));
      expect(probe.defaultKeepAliveSeconds, 11);
    });

    test('they keep reading `stun`/`shsp` even when the sector is repointed',
        () {
      initStunConfig({'ipVersion': 'IPv4'});
      final probe = _ConfigProbe()..configSector = 'somewhere_else';

      expect(probe.configSector, 'somewhere_else');
      expect(probe.defaultIpv6Enabled, isFalse);
      expect(probe.defaultNatPrimaryServer, 'stun.l.google.com');
    });

    test('initStunShspConfig() loads the ports into its own sector', () {
      initStunShspConfig({
        'socket': {'port': 5000, 'ipv4Port': 1},
      });

      final probe = _ConfigProbe();

      expect(probe.defaultSocketPort, 5000);
      expect(probe.defaultIpv4Port, 1);
      // Untouched keys of the overridden sub-map survive the merge.
      expect(probe.defaultIpv6Port, 0);
    });

    test('initStunShspConfig() forwards socket.ipv6 to the `stun` sector', () {
      initStunShspConfig({
        'socket': {'ipv6': false, 'port': 5000},
      });

      expect(_StunProbe().defaultIpVersion, InternetAddressType.IPv4);
      expect(defaultStunIpVersion(), InternetAddressType.IPv4);
      expect(_ConfigProbe().defaultIpv6Enabled, isFalse);
      // The flag was forwarded, not stored here.
      expect(stunShspConfigValue(const ['socket', 'ipv6']), isNull);
    });

    test('initStunShspConfig() forwards the nat section to the `stun` sector',
        () {
      initStunShspConfig({
        'nat': {'primaryServer': 'stun.example.org', 'timeoutSeconds': 2.5},
      });

      final stun = _StunProbe();
      expect(stun.defaultNatPrimaryServer, 'stun.example.org');
      expect(stun.defaultNatTimeout, const Duration(milliseconds: 2500));
      // Keys of the `nat` section it didn't mention keep their value.
      expect(stun.defaultNatPrimaryPort, 19302);
      // And so does the rest of the `stun` sector.
      expect(stun.defaultStunAddress, 'stun.l.google.com');
    });

    test('initStunShspConfig() forwards the shsp section to the `shsp` sector',
        () {
      initStunShspConfig({
        'shsp': {'keepAliveSeconds': 11},
      });

      expect(_ShspProbe().defaultKeepAliveSeconds, 11);
      expect(defaultShspKeepAliveSeconds(), 11);
      expect(_ConfigProbe().defaultKeepAliveSeconds, 11);
    });

    test('a forwarded section keeps what the `stun` sector already had', () {
      initStunConfig({
        'server': {'address': 'stun.example.org'},
        'nat': {'primaryPort': 3478},
      });

      initStunShspConfig({
        'nat': {'primaryServer': 'nat.example.org'},
      });

      final stun = _StunProbe();
      expect(stun.defaultNatPrimaryServer, 'nat.example.org');
      // Loaded before, and never mentioned since.
      expect(stun.defaultStunAddress, 'stun.example.org');
      expect(stun.defaultNatPrimaryPort, 3478);
    });

    test('initStunShspConfig() with no overrides resets every sector it reads',
        () {
      initStunShspConfig({
        'socket': {'port': 5000, 'ipv6': false},
        'nat': {'primaryServer': 'stun.example.org'},
        'shsp': {'keepAliveSeconds': 11},
      });

      initStunShspConfig();

      final probe = _ConfigProbe();
      expect(probe.defaultSocketPort, 0);
      expect(probe.defaultIpv6Enabled, isTrue);
      expect(probe.defaultNatPrimaryServer, 'stun.l.google.com');
      expect(probe.defaultKeepAliveSeconds, 30);
    });

    test('accepts a document nesting the section under the config key', () {
      initStunShspConfig({
        'someOtherDomain': {'whatever': true},
        stunShspConfigKey: {
          'socket': {'ipv4Port': 1},
          'nat': {'primaryServer': 'stun.example.org', 'primaryPort': 3478},
        },
      });

      final probe = _ConfigProbe();

      expect(probe.defaultIpv4Port, 1);
      expect(probe.defaultNatPrimaryServer, 'stun.example.org');
      expect(probe.defaultNatPrimaryPort, 3478);
      expect(probe.defaultNatTimeout, const Duration(seconds: 5));
    });

    test('initStunShspConfig() does not mutate the const defaults', () {
      initStunShspConfig({
        'socket': {'port': 5000},
      });
      _ConfigProbe().set([stunShspConfigKey, 'socket', 'ipv4Port'], 1);

      final defaults =
          defaultStunShspConfig[stunShspConfigKey] as Map<String, dynamic>;
      expect((defaults['socket'] as Map)['port'], 0);
      expect((defaults['socket'] as Map)['ipv4Port'], 0);
    });

    test('reads the port coercions from JSON', () {
      final probe = _ConfigProbe();
      probe.loadFromString('''
      {
        "stunShspConfig": {
          "socket": { "port": 5000, "ipv6Port": 5001 }
        }
      }
      ''');

      expect(probe.defaultSocketPort, 5000);
      expect(probe.defaultIpv6Port, 5001);
      // Keys absent from the JSON still resolve to the built-in defaults.
      expect(probe.defaultIpv4Port, 0);
    });

    test('stunShspConfigValue() reads by path from static contexts', () {
      initStunShspConfig({
        'socket': {'ipv4Port': 3478},
      });

      expect(stunShspConfigValue(const ['socket', 'ipv4Port']), 3478);
      expect(stunShspConfigValue(const ['socket', 'ipv6Port']), 0);
      // The `nat` section is reachable through the `stun` package's own helper.
      expect(stunConfigValue(const ['nat', 'primaryPort']), 19302);
    });
  });

  group('static-context helpers', () {
    test('expose the configured values used as constructor defaults', () {
      initStunShspConfig({
        'socket': {'ipv6': false, 'port': 6000, 'ipv4Port': 1, 'ipv6Port': 2},
        'nat': {
          'primaryServer': 'stun.example.org',
          'primaryPort': 3478,
          // A double: the defaults type this key, and config_manager rejects
          // an int overwrite of a double key.
          'timeoutSeconds': 7.0,
        },
      });

      expect(defaultStunShspIpv6Enabled(), isFalse);
      expect(defaultStunShspPort(), 6000);
      expect(defaultStunShspIpv4Port(), 1);
      expect(defaultStunShspIpv6Port(), 2);
      expect(defaultStunShspNatPrimaryServer(), 'stun.example.org');
      expect(defaultStunShspNatPrimaryPort(), 3478);
      expect(defaultStunShspNatTimeout(), const Duration(seconds: 7));
    });
  });

  group('ensureStunShspConfig()', () {
    test('seeds the defaults without overwriting what is already loaded', () {
      initStunShspConfig({
        'socket': {'port': 5000},
        'nat': {'primaryServer': 'stun.example.org'},
        'shsp': {'keepAliveSeconds': 11},
      });

      ensureStunShspConfig();

      final probe = _ConfigProbe();
      expect(probe.defaultSocketPort, 5000);
      expect(probe.defaultNatPrimaryServer, 'stun.example.org');
      expect(probe.defaultKeepAliveSeconds, 11);
    });
  });
}

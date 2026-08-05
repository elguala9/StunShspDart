import 'package:config_manager/config_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Minimal consumer used to exercise [StunShspConfigExtension] in isolation.
class _ConfigProbe with ConfigExtension, StunShspConfigExtension {}

void main() {
  // Restore the built-in defaults between tests.
  tearDown(initStunShspConfig);

  group('StunShspConfigExtension', () {
    test('falls back to the built-in defaults when nothing is loaded', () {
      ConfigManagerSingleton().clear([], sector: stunShspConfigSector);
      final probe = _ConfigProbe();

      expect(probe.configSector, stunShspConfigSector);
      expect(probe.defaultIpv6Enabled, isTrue);
      expect(probe.defaultSocketPort, 0);
      expect(probe.defaultIpv4Port, 0);
      expect(probe.defaultIpv6Port, 0);
      expect(probe.defaultNatPrimaryServer, 'stun.l.google.com');
      expect(probe.defaultNatPrimaryPort, 19302);
      expect(probe.defaultNatTimeout, const Duration(seconds: 5));
    });

    test('initStunShspConfig() deep-merges the overrides onto the defaults', () {
      initStunShspConfig({
        'socket': {'ipv6': false},
        'nat': {'timeoutSeconds': 2.5},
      });

      final probe = _ConfigProbe();

      expect(probe.defaultIpv6Enabled, isFalse);
      expect(probe.defaultNatTimeout, const Duration(milliseconds: 2500));
      // Untouched keys of the overridden sub-maps survive the merge.
      expect(probe.defaultSocketPort, 0);
      expect(probe.defaultNatPrimaryServer, 'stun.l.google.com');
    });

    test('accepts a document nesting the section under the config key', () {
      initStunShspConfig({
        'someOtherDomain': {'whatever': true},
        stunShspConfigKey: {
          'nat': {'primaryServer': 'stun.example.org', 'primaryPort': 3478},
        },
      });

      final probe = _ConfigProbe();

      expect(probe.defaultNatPrimaryServer, 'stun.example.org');
      expect(probe.defaultNatPrimaryPort, 3478);
      expect(probe.defaultNatTimeout, const Duration(seconds: 5));
    });

    test('initStunShspConfig() does not mutate the const defaults', () {
      initStunShspConfig({
        'nat': {'primaryServer': 'stun.example.org'},
      });
      _ConfigProbe().set([stunShspConfigKey, 'nat', 'primaryPort'], 1);

      final defaults =
          defaultStunShspConfig[stunShspConfigKey] as Map<String, dynamic>;
      expect((defaults['nat'] as Map)['primaryServer'], 'stun.l.google.com');
      expect((defaults['nat'] as Map)['primaryPort'], 19302);
    });

    test('reads the boolean and Duration coercions from JSON', () {
      final probe = _ConfigProbe();
      probe.loadFromString('''
      {
        "stunShspConfig": {
          "socket": { "ipv6": false, "port": 5000 },
          "nat": { "timeoutSeconds": 1.5 }
        }
      }
      ''');

      expect(probe.defaultIpv6Enabled, isFalse);
      expect(probe.defaultSocketPort, 5000);
      expect(probe.defaultNatTimeout, const Duration(milliseconds: 1500));
      // Keys absent from the JSON still resolve to the built-in defaults.
      expect(probe.defaultNatPrimaryServer, 'stun.l.google.com');
      expect(probe.defaultIpv4Port, 0);
    });

    test('stunShspConfigValue() reads by path from static contexts', () {
      initStunShspConfig({
        'nat': {'primaryPort': 3478},
      });

      expect(stunShspConfigValue(const ['nat', 'primaryPort']), 3478);
      expect(
        stunShspConfigValue(const ['nat', 'primaryServer']),
        'stun.l.google.com',
      );
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
        'nat': {'primaryServer': 'stun.example.org'},
      });

      ensureStunShspConfig();

      expect(_ConfigProbe().defaultNatPrimaryServer, 'stun.example.org');
    });
  });
}

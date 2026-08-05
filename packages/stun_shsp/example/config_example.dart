// ignore_for_file: avoid_print
import 'package:config_manager/config_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';

// ============================================================================
// Configuration (`stun_shsp` sector of config_manager)
// ============================================================================

/// Nothing has to be loaded before reading a value: every getter falls back to
/// [defaultStunShspConfig].
void defaultConfigExample() {
  print('defaults: ipv6=${defaultStunShspIpv6Enabled()} '
      'port=${defaultStunShspPort()} '
      'natServer=${defaultStunShspNatPrimaryServer()}:'
      '${defaultStunShspNatPrimaryPort()} '
      'natTimeout=${defaultStunShspNatTimeout()}');
}

/// [initStunShspConfig] deep-merges the overrides onto the defaults, so a
/// partial map only changes what it mentions.
void initConfigExample() {
  initStunShspConfig({
    'socket': {'ipv6': false},
    'nat': {'primaryServer': 'stun.cloudflare.com', 'primaryPort': 3478},
  });

  print('after init: ipv6=${defaultStunShspIpv6Enabled()} '
      'port=${defaultStunShspPort()} (untouched) '
      'natServer=${defaultStunShspNatPrimaryServer()}:'
      '${defaultStunShspNatPrimaryPort()}');

  initStunShspConfig();
}

/// A bigger multi-domain document can be handed over as-is: only the
/// [stunShspConfigKey] section is used.
void nestedDocumentExample() {
  initStunShspConfig({
    'database': {'host': 'localhost'},
    stunShspConfigKey: {
      'nat': {'timeoutSeconds': 9.0},
    },
  });

  print('from a nested document: natTimeout=${defaultStunShspNatTimeout()}');
  initStunShspConfig();
}

/// Loading the same section from JSON, e.g. a file shipped with the app.
void jsonConfigExample() {
  final access = _ConfigProbe()
    ..loadFromString('''
    {
      "stunShspConfig": {
        "socket": { "ipv6": false, "port": 5000 },
        "nat": { "timeoutSeconds": 2.5 }
      }
    }
    ''');

  print('from JSON: ipv6=${access.defaultIpv6Enabled} '
      'port=${access.defaultSocketPort} '
      'natTimeout=${access.defaultNatTimeout}');

  initStunShspConfig();
}

/// Reading the configuration from your own class: mix
/// [StunShspConfigExtension] on top of [ConfigExtension] and use the typed
/// getters instead of the top-level helpers.
void configExtensionExample() {
  final probe = _ConfigProbe();
  print('via the mixin: ipv4Port=${probe.defaultIpv4Port} '
      'ipv6Port=${probe.defaultIpv6Port} '
      "configValue(['nat','primaryPort'])="
      '${probe.configValue(const ['nat', 'primaryPort'])}');
}

class _ConfigProbe with ConfigExtension, StunShspConfigExtension {}

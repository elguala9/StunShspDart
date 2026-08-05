// ignore_for_file: avoid_print
import 'package:config_manager/config_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';

// ============================================================================
// Configuration — the `stun_shsp` sector, plus the `stun`/`shsp` ones it reads
// ============================================================================

/// Only the bind ports live in the `stun_shsp` sector. Everything else is read
/// from the package that owns it: the STUN server, the NAT servers and the
/// address family from the `stun` sector, keep-alive and handshake from the
/// `shsp` one — so there is never a second copy to keep in sync.
///
/// Nothing has to be loaded before reading a value: every getter falls back to
/// the defaults of the owning sector.
void defaultConfigExample() {
  print('own sector: port=${defaultStunShspPort()} '
      'ipv4Port=${defaultStunShspIpv4Port()} '
      'ipv6Port=${defaultStunShspIpv6Port()}');
  print('from the `stun` sector: ipv6=${defaultStunShspIpv6Enabled()} '
      'natServer=${defaultStunShspNatPrimaryServer()}:'
      '${defaultStunShspNatPrimaryPort()} '
      'natTimeout=${defaultStunShspNatTimeout()}');
}

/// Configuring `stun`/`shsp` configures this package too, since it reads their
/// sectors instead of copying them.
void ownerSectorsExample() {
  initStunConfig({
    'ipVersion': 'IPv4',
    'nat': {'primaryServer': 'stun.cloudflare.com', 'primaryPort': 3478},
  });
  initShspConfig({'keepAliveSeconds': 11});

  final probe = _ConfigProbe();
  print('after initStunConfig/initShspConfig: ipv6=${probe.defaultIpv6Enabled} '
      'natServer=${probe.defaultNatPrimaryServer}:${probe.defaultNatPrimaryPort} '
      'keepAlive=${probe.defaultKeepAliveSeconds}s');

  initStunShspConfig();
}

/// [initStunShspConfig] is the single entry point when you'd rather not call
/// three: the ports go to this sector, `socket.ipv6` and `nat` are forwarded to
/// the `stun` sector, a `shsp` section to the `shsp` one. Everything is
/// deep-merged, so a partial map only changes what it mentions.
void initConfigExample() {
  initStunShspConfig({
    'socket': {'ipv6': false, 'ipv4Port': 5000},
    'nat': {'primaryServer': 'stun.cloudflare.com', 'primaryPort': 3478},
    'shsp': {'keepAliveSeconds': 11},
  });

  print('after init: ipv6=${defaultStunShspIpv6Enabled()} '
      'ipv4Port=${defaultStunShspIpv4Port()} '
      'port=${defaultStunShspPort()} (untouched) '
      'natServer=${defaultStunShspNatPrimaryServer()}:'
      '${defaultStunShspNatPrimaryPort()}');
  // The forwarded values really landed in the other sectors.
  print('forwarded: stun.ipVersion=${defaultStunIpVersion()} '
      'shsp.keepAlive=${defaultShspKeepAliveSeconds()}s');

  // With no arguments it resets every sector it reads back to its defaults.
  initStunShspConfig();
}

/// A bigger multi-domain document can be handed over as-is: only the
/// [stunShspConfigKey] section is used.
void nestedDocumentExample() {
  initStunShspConfig({
    'database': {'host': 'localhost'},
    stunShspConfigKey: {
      'socket': {'port': 5000},
      'nat': {'timeoutSeconds': 9.0},
    },
  });

  print('from a nested document: port=${defaultStunShspPort()} '
      'natTimeout=${defaultStunShspNatTimeout()}');
  initStunShspConfig();
}

/// Loading this sector from JSON, e.g. a file shipped with the app. It carries
/// the ports; the `stun`/`shsp` sections go through their own package's loader
/// (or through [initStunShspConfig] with the decoded map).
void jsonConfigExample() {
  final access = _ConfigProbe()
    ..loadFromString('''
    {
      "stunShspConfig": {
        "socket": { "port": 5000, "ipv6Port": 5001 }
      }
    }
    ''');

  print('from JSON: port=${access.defaultSocketPort} '
      'ipv6Port=${access.defaultIpv6Port}');

  initStunShspConfig();
}

/// Reading the configuration from your own class: mix
/// [StunShspConfigExtension] on top of [ConfigExtension] and use the typed
/// getters instead of the top-level helpers. The borrowed ones always read the
/// sector that owns the value, whatever `configSector` points at.
void configExtensionExample() {
  final probe = _ConfigProbe();
  print('via the mixin: ipv4Port=${probe.defaultIpv4Port} '
      'ipv6Port=${probe.defaultIpv6Port} '
      'stunServer=${probe.defaultStunServerAddress}:'
      '${probe.defaultStunServerPort} '
      "configValue(['socket','port'])="
      '${probe.configValue(const ['socket', 'port'])}');
}

class _ConfigProbe with ConfigExtension, StunShspConfigExtension {}

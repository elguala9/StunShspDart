import 'dart:io';

import 'package:config_manager/config_manager.dart';
import 'package:shsp/shsp.dart';
import 'package:stun/stun.dart';

/// The `config_manager` sector owned by this package.
///
/// Deliberately tiny: everything this package needs that the `stun` or `shsp`
/// packages already configure is *read from their own sector* instead of being
/// duplicated here, so configuring `stun`/`shsp` configures `stun_shsp` too
/// and there is never a second copy of a value to keep in sync.
///
/// | Setting | Sector | Key |
/// |---|---|---|
/// | STUN server, timeout, NAT servers | `stun` | `server`, `timeoutSeconds`, `nat` |
/// | Address family of the sockets | `stun` | `ipVersion` |
/// | Keep-alive, handshake, retry | `shsp` | `shspConfig` |
/// | Ports the sockets bind to | `stun_shsp` | `stunShspConfig.socket` |
///
/// Only that last row lives here: neither package configures a bind port
/// (`stun` always binds an ephemeral one, `shsp` takes the port as an
/// argument), and a dual handler needs one port per family.
const String stunShspConfigSector = 'stun_shsp';

/// Key nesting the actual STUN/SHSP settings, both in
/// [defaultStunShspConfig] and in any overrides handed to
/// [initStunShspConfig] — so a larger multi-domain JSON document can carry
/// this section as-is instead of extracting it first.
const String stunShspConfigKey = 'stunShspConfig';

/// Built-in defaults of the [stunShspConfigSector] settings, also used as the
/// fallback for missing keys and as the source of valid configuration keys.
///
/// `0` means "let the OS pick a port", as everywhere else in `shsp`.
const Map<String, dynamic> defaultStunShspConfig = {
  stunShspConfigKey: {
    'socket': {'port': 0, 'ipv4Port': 0, 'ipv6Port': 0},
  },
};

/// Loads [defaultStunShspConfig] into [stunShspConfigSector], with
/// [overrides] deep-merged on top, and forwards the sections owned by the
/// other two packages to *their* sector.
///
/// [overrides] can be the STUN/SHSP fields directly, or a bigger document
/// nesting them under [stunShspConfigKey] — only that section is used, so
/// foreign JSON can be merged in and handed over as-is. Recognised sections:
///
/// - `socket.port` / `socket.ipv4Port` / `socket.ipv6Port` → this sector.
/// - `socket.ipv6` (a `bool`) → the `stun` sector, as `ipVersion`: the address
///   family is one choice for both halves of a combined handler.
/// - `nat` → the `stun` sector, whose `nat` section this package reads.
/// - `shsp` → the `shsp` sector, i.e. the `shspConfig` section of
///   `defaultShspConfig`.
///
/// Only the keys actually present are forwarded, and they are deep-merged, so
/// a `stun`/`shsp` configuration loaded earlier keeps every value this call
/// doesn't mention. Called with no [overrides] at all it resets every sector
/// it reads back to its defaults, which is what makes it usable as a test
/// tear-down. Not required before reading anything:
/// [StunShspConfigExtension]'s getters fall back to the defaults of the
/// owning sector regardless.
void initStunShspConfig([Map<String, dynamic>? overrides]) {
  if (overrides == null) {
    initStunConfig();
    initShspConfig();
  }

  final section = unwrapStunShspConfig(overrides);
  final socket = _mapAt(section, 'socket');

  _access.loadFromMap({
    stunShspConfigKey: deepMergeMaps(
      defaultStunShspConfig[stunShspConfigKey] as Map<String, dynamic>,
      {
        'socket': <String, dynamic>{
          for (final key in const ['port', 'ipv4Port', 'ipv6Port'])
            if (socket != null && socket.containsKey(key)) key: socket[key],
        },
      },
    ),
  });

  final ipv6 = socket?['ipv6'];
  final nat = _mapAt(section, 'nat');
  if (ipv6 is bool || nat != null) {
    _stun.loadFromMap({
      if (ipv6 is bool) 'ipVersion': ipv6 ? 'IPv6' : 'IPv4',
      if (nat != null) 'nat': nat,
    });
  }

  final shsp = _mapAt(section, 'shsp');
  if (shsp != null) {
    _shsp.loadFromMap({shspConfigKey: unwrapShspConfig(shsp) ?? shsp});
  }
}

/// Seeds the defaults of every sector this package reads — its own,
/// `stunConfigSector` and `shspConfigSector` — but only where nothing is
/// loaded yet.
void ensureStunShspConfig() {
  _access.loadFromMap(defaultStunShspConfig, force: false);
  ensureStunConfig();
  _shsp.loadFromMap(defaultShspConfig, force: false);
}

/// The STUN/SHSP section of [map]: `map[stunShspConfigKey]` when present, or
/// [map] itself otherwise.
Map<String, dynamic>? unwrapStunShspConfig(Map<String, dynamic>? map) =>
    (map?[stunShspConfigKey] as Map<String, dynamic>?) ?? map;

/// Deep-merges [overrides] onto [base], returning a new mutable map.
Map<String, dynamic> mergeStunShspConfig(
  Map<String, dynamic> base, [
  Map<String, dynamic>? overrides,
]) => deepMergeMaps(base, overrides);

/// [StunShspConfigExtension.defaultIpv6Enabled] for static contexts, e.g.
/// factory methods that cannot mix in [StunShspConfigExtension].
bool defaultStunShspIpv6Enabled() => _access.defaultIpv6Enabled;

/// [StunShspConfigExtension.defaultSocketPort] for static contexts.
int defaultStunShspPort() => _access.defaultSocketPort;

/// [StunShspConfigExtension.defaultIpv4Port] for static contexts.
int defaultStunShspIpv4Port() => _access.defaultIpv4Port;

/// [StunShspConfigExtension.defaultIpv6Port] for static contexts.
int defaultStunShspIpv6Port() => _access.defaultIpv6Port;

/// [StunShspConfigExtension.defaultNatPrimaryServer] for static contexts,
/// e.g. constructor default values. Reads the `stun` sector.
String defaultStunShspNatPrimaryServer() => _access.defaultNatPrimaryServer;

/// [StunShspConfigExtension.defaultNatPrimaryPort] for static contexts.
int defaultStunShspNatPrimaryPort() => _access.defaultNatPrimaryPort;

/// [StunShspConfigExtension.defaultNatTimeout] for static contexts.
Duration defaultStunShspNatTimeout() => _access.defaultNatTimeout;

/// Reads a configured value at [path] under [stunShspConfigKey] (e.g.
/// `['socket', 'ipv4Port']`).
///
/// Escape hatch for static contexts that cannot mix in
/// [StunShspConfigExtension]; prefer its typed getters on an instance. Only
/// this package's own sector is reachable this way — use `stunConfigValue`
/// for the `stun` sector, which owns the STUN server and the `nat` section.
dynamic stunShspConfigValue(List<String> path) => _access.configValue(path);

/// The section of [map] at [key], when it is a map.
Map<String, dynamic>? _mapAt(Map<String, dynamic>? map, String key) =>
    map?[key] as Map<String, dynamic>?;

/// Backs the helpers above with real [ConfigExtension] instances — one per
/// sector — instead of talking to [ConfigManagerSingleton] directly.
final _access = _StunShspConfigAccess();
final _stun = _StunSectionAccess();
final _shsp = _ShspSectionAccess();

class _StunShspConfigAccess with ConfigExtension, StunShspConfigExtension {}

class _StunSectionAccess with ConfigExtension, StunConfigExtension {}

class _ShspSectionAccess with ConfigExtension, ShspConfigExtension {}

/// Configuration access for the STUN/SHSP components: pins the sector to
/// [stunShspConfigSector] and exposes every default this package needs
/// already coerced to its Dart type — including the ones owned by the `stun`
/// and `shsp` sectors, so a consumer has one place to look. Mix in on top of
/// [ConfigExtension].
///
/// Those borrowed getters deliberately ignore [configSector]: they always
/// read the sector of the package that owns the value. Sectors are what
/// `stun`/`shsp` key their own configuration on, so pointing this mixin
/// elsewhere must not silently change where *their* values come from.
mixin StunShspConfigExtension on ConfigExtension {
  String _sector = stunShspConfigSector;

  @override
  String get configSector => _sector;

  @override
  set configSector(String value) => _sector = value;

  /// Whether the sockets bind IPv6 — the `ipVersion` of the `stun` sector,
  /// which is the same choice for both halves of a combined handler.
  bool get defaultIpv6Enabled =>
      _stun.defaultIpVersion == InternetAddressType.IPv6;

  int get defaultSocketPort => getOrDefault<int>(
    const [stunShspConfigKey, 'socket', 'port'],
    defaultStunShspConfig,
  );

  int get defaultIpv4Port => getOrDefault<int>(
    const [stunShspConfigKey, 'socket', 'ipv4Port'],
    defaultStunShspConfig,
  );

  int get defaultIpv6Port => getOrDefault<int>(
    const [stunShspConfigKey, 'socket', 'ipv6Port'],
    defaultStunShspConfig,
  );

  /// The `nat` section of the `stun` sector, which owns it.
  String get defaultNatPrimaryServer => _stun.defaultNatPrimaryServer;

  int get defaultNatPrimaryPort => _stun.defaultNatPrimaryPort;

  Duration get defaultNatTimeout => _stun.defaultNatTimeout;

  /// The STUN server the handlers fall back to — `server` of the `stun`
  /// sector, so `StunShspHandler(socket)` and `StunHandler(socket)` agree.
  String get defaultStunServerAddress => _stun.defaultStunAddress;

  int get defaultStunServerPort => _stun.defaultStunPort;

  Duration get defaultStunTimeout => _stun.defaultTimeout;

  /// Keep-alive of the `shsp` sector, which owns it — the value SHSP peers
  /// built on a combined handler use.
  int get defaultKeepAliveSeconds => _shsp.defaultKeepAliveSeconds;

  /// Configured value at [path] under [stunShspConfigKey], falling back to
  /// its [defaultStunShspConfig] entry when the loaded configuration doesn't
  /// define it; see [ConfigExtension.getOrDefault].
  dynamic configValue(List<String> path) => getOrDefault<dynamic>(
    [stunShspConfigKey, ...path],
    defaultStunShspConfig,
  );
}

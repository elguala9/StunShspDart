import 'package:config_manager/config_manager.dart';

/// The `config_manager` sector owned by this package.
///
/// Separate from the `stun` and `shsp` sectors: those stay owned by their own
/// packages, and configuring one never silently rewires the others.
const String stunShspConfigSector = 'stun_shsp';

/// Key nesting the actual STUN/SHSP settings, both in
/// [defaultStunShspConfig] and in any overrides handed to
/// [initStunShspConfig] — so a larger multi-domain JSON document can carry
/// this section as-is instead of extracting it first.
const String stunShspConfigKey = 'stunShspConfig';

/// Built-in STUN/SHSP defaults, also used as the fallback for missing keys
/// and as the source of valid configuration keys.
const Map<String, dynamic> defaultStunShspConfig = {
  stunShspConfigKey: {
    'socket': {'ipv6': true, 'port': 0, 'ipv4Port': 0, 'ipv6Port': 0},
    'nat': {
      'primaryServer': 'stun.l.google.com',
      'primaryPort': 19302,
      'timeoutSeconds': 5.0,
    },
  },
};

/// Loads [defaultStunShspConfig] into [stunShspConfigSector], with
/// [overrides] deep-merged on top. [overrides] can be the STUN/SHSP fields
/// directly, or a bigger document nesting them under [stunShspConfigKey] —
/// only that section is used, so foreign JSON can be merged in and handed
/// over as-is. Always replaces whatever was loaded before; use
/// [ensureStunShspConfig] to seed the sector only if it's still empty. Not
/// required before reading values: [StunShspConfigExtension]'s getters fall
/// back to [defaultStunShspConfig] via `getOrDefault` regardless.
void initStunShspConfig([Map<String, dynamic>? overrides]) {
  final section = unwrapStunShspConfig(overrides);
  _access.loadFromMap({
    stunShspConfigKey: deepMergeMaps(
      defaultStunShspConfig[stunShspConfigKey] as Map<String, dynamic>,
      section,
    ),
  });
}

/// Seeds [defaultStunShspConfig] into [stunShspConfigSector], but only if it
/// isn't already loaded.
void ensureStunShspConfig() {
  _access.loadFromMap(defaultStunShspConfig, force: false);
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
/// e.g. constructor default values.
String defaultStunShspNatPrimaryServer() => _access.defaultNatPrimaryServer;

/// [StunShspConfigExtension.defaultNatPrimaryPort] for static contexts.
int defaultStunShspNatPrimaryPort() => _access.defaultNatPrimaryPort;

/// [StunShspConfigExtension.defaultNatTimeout] for static contexts.
Duration defaultStunShspNatTimeout() => _access.defaultNatTimeout;

/// Reads a configured value at [path] (e.g. `['nat', 'primaryServer']`).
///
/// Escape hatch for static contexts that cannot mix in
/// [StunShspConfigExtension]; prefer its typed getters on an instance.
dynamic stunShspConfigValue(List<String> path) => _access.configValue(path);

/// Backs the static-context helpers above with a real [ConfigExtension]
/// instance, instead of talking to [ConfigManagerSingleton] directly.
final _access = _StunShspConfigAccess();

class _StunShspConfigAccess with ConfigExtension, StunShspConfigExtension {}

/// Configuration access for the STUN/SHSP components: pins the sector to
/// [stunShspConfigSector] and exposes the defaults already coerced to their
/// Dart types. Mix in on top of [ConfigExtension].
mixin StunShspConfigExtension on ConfigExtension {
  String _sector = stunShspConfigSector;

  @override
  String get configSector => _sector;

  @override
  set configSector(String value) => _sector = value;

  bool get defaultIpv6Enabled => getOrDefault<bool>(
    const [stunShspConfigKey, 'socket', 'ipv6'],
    defaultStunShspConfig,
  );

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

  String get defaultNatPrimaryServer => getOrDefault<String>(
    const [stunShspConfigKey, 'nat', 'primaryServer'],
    defaultStunShspConfig,
  );

  int get defaultNatPrimaryPort => getOrDefault<int>(
    const [stunShspConfigKey, 'nat', 'primaryPort'],
    defaultStunShspConfig,
  );

  Duration get defaultNatTimeout => getDurationSeconds(
    const [stunShspConfigKey, 'nat', 'timeoutSeconds'],
    defaultStunShspConfig,
  );

  /// Configured value at [path], falling back to its [defaultStunShspConfig]
  /// entry when the loaded configuration doesn't define it; see
  /// [ConfigExtension.getOrDefault].
  dynamic configValue(List<String> path) =>
      getOrDefault<dynamic>([stunShspConfigKey, ...path], defaultStunShspConfig);
}

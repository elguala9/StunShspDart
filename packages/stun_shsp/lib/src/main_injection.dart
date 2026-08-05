// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:singleton_manager/singleton_manager.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND

import 'implementations/dual_stun_shsp_handler.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'implementations/stun_shsp_handler.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'interfaces/i_dual_stun_shsp_handler.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'interfaces/i_stun_shsp_handler.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND

/// Connects every `@dependencyInjectable` class discovered under the scanned
/// input directory to `RegistryManager.instance`, using each generated
/// `dependencyInjectionFactory()` as the connected factory.
/// Each call is independent — registering under a different [key] never
/// overwrites a previous call, so multiple singleton graphs can be set up
/// side by side by calling this with different keys.
///
/// Every method below is a regular, overridable instance method — mix
/// [MainInjectionStunShspMixin] into your own class (or override on [MainInjectionStunShsp])
/// to hook into `beforeRegisterAllSingletonsStunShsp` / `afterRegisterAllSingletonsStunShsp`, or replace
/// `registerAllSingletonsStunShsp` entirely.
mixin MainInjectionStunShspMixin { // GENERATED CODE - DO NOT MODIFY BY HAND
  /// Called by [registerAllSingletonsStunShsp] right before it connects anything.
  /// Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  void beforeRegisterAllSingletonsStunShsp({String key = 'default'}) {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Connects every discovered singleton under [key]. // GENERATED CODE - DO NOT MODIFY BY HAND
  void registerAllSingletonsStunShsp({String key = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    beforeRegisterAllSingletonsStunShsp(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    RegistryManager.instance // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IDualStunShspHandler, DualStunShspHandler>(() => DualStunShspHandler.dependencyInjectionFactory(key: key), key: key) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IStunShspHandler, StunShspHandler>(() => StunShspHandler.dependencyInjectionFactory(key: key), key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    afterRegisterAllSingletonsStunShsp(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsStunShsp] right after it finishes connecting
  /// everything. Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  void afterRegisterAllSingletonsStunShsp({String key = 'default'}) {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsStunShspAsync] right before it connects anything.
  /// Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> beforeRegisterAllSingletonsStunShspAsync({String key = 'default'}) async {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Async twin of [registerAllSingletonsStunShsp] — use this when [beforeRegisterAllSingletonsStunShspAsync]
  /// or [afterRegisterAllSingletonsStunShspAsync] need to await work (e.g. loading remote
  /// config) before or after connecting. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> registerAllSingletonsStunShspAsync({String key = 'default'}) async { // GENERATED CODE - DO NOT MODIFY BY HAND
    await beforeRegisterAllSingletonsStunShspAsync(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    registerAllSingletonsStunShsp(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    await afterRegisterAllSingletonsStunShspAsync(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsStunShspAsync] right after it finishes connecting
  /// everything. Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> afterRegisterAllSingletonsStunShspAsync({String key = 'default'}) async {} // GENERATED CODE - DO NOT MODIFY BY HAND
} // GENERATED CODE - DO NOT MODIFY BY HAND

/// Ready-to-use [MainInjectionStunShspMixin] host — instantiate this directly, or
/// extend it (or mix [MainInjectionStunShspMixin] into your own class) to override
/// the before/register/after hooks. // GENERATED CODE - DO NOT MODIFY BY HAND
class MainInjectionStunShsp with MainInjectionStunShspMixin { // GENERATED CODE - DO NOT MODIFY BY HAND
  const MainInjectionStunShsp(); // GENERATED CODE - DO NOT MODIFY BY HAND
} // GENERATED CODE - DO NOT MODIFY BY HAND

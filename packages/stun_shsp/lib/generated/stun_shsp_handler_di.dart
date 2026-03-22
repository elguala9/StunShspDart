// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import

import 'package:singleton_manager/singleton_manager.dart';
import '../src/stun_shsp_handler.dart';
import 'dart:io';
import 'package:stun/stun.dart';
import 'package:shsp/shsp.dart';
import '../src/i_stun_shsp_handler.dart';

class StunShspHandlerDI extends StunShspHandler implements ISingletonStandardDI {
  StunShspHandlerDI._() : super();

  factory StunShspHandlerDI.initializeDI() {
    final instance = StunShspHandlerDI._();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    injectDependencies(
      stunHandler: SingletonDIAccess.get<StunHandlerBase>(),
      dualShspSocket: SingletonDIAccess.get<IDualShspSocketMigratable>(),
    );
  }
}

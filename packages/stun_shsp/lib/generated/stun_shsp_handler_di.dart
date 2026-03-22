// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import

import 'package:singleton_manager/singleton_manager.dart';
import '../src/stun_shsp_handler.dart';
import 'dart:io';
import 'package:stun/stun.dart';
import 'package:shsp/shsp.dart';
import '../src/i_stun_shsp_handler.dart';

class StunShspHandlerDI extends StunShspHandler implements ISingletonStandardDI {
  factory StunShspHandlerDI.initializeDI() {
    final instance = StunShspHandler();
    instance.initializeDI();
    return instance as StunShspHandlerDI;
  }

  @override
  void initializeDI() {
    _stunHandler = SingletonDIAccess.get<StunHandlerBase>();
    _dualShspSocket = SingletonDIAccess.get<IDualShspSocketMigratable>();
  }
}

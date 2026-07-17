import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';
import 'package:shsp/shsp.dart';

abstract interface class IStunShspHandler implements IValueForRegistry, IStunHandler, IShspSocketWrapper {
  IStunHandler get stunHandler;
  IShspSocketWrapper get shspSocket;
}

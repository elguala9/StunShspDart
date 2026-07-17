import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';
import 'package:shsp/shsp.dart';
import 'package:stun_shsp/src/imlementations/stun_shsp_handler.dart';

/// Interface for a handler combining STUN protocol with SHSP Socket
abstract interface class IDualStunShspHandler implements IValueForRegistry, IDualStunHandler, IDualShspSocketAuto {
  StunShspHandler get ipv4StunShspHandler;
  StunShspHandler get ipv6StunShspHandler;
  IShspSocketWrapper get ipv4ShspSocket;
  IShspSocketWrapper get ipv6ShspSocket;
}

import 'package:stun_shsp/stun_shsp.dart';

class MainInjectionStunShspPersonalized extends MainInjectionStunShsp {


  @override
  Future<void> beforeRegisterAllSingletonsStunShspAsync({String key = 'default'}) async {
    await connectDualShspSockets(key: key);
    const MainInjectionShsp().registerAllSingletonsShsp(key: key);
    const MainInjectionStun().registerAllSingletonsStun(key: key);
    connectStunShspHandlerSubkeys(key: key);
  }
      
}

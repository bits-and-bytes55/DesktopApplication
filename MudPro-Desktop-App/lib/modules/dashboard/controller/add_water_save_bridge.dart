import 'package:get/get.dart';

typedef AddWaterSaveCallback = Future<Map<String, dynamic>> Function();

class AddWaterSaveBridge extends GetxController {
  final Map<String, AddWaterSaveCallback> _savers = {};

  void register(String instanceKey, AddWaterSaveCallback saver) {
    final key = instanceKey.trim();
    if (key.isEmpty) return;
    _savers[key] = saver;
  }

  void unregister(String instanceKey) {
    final key = instanceKey.trim();
    if (key.isEmpty) return;
    _savers.remove(key);
  }

  Future<Map<String, dynamic>> save(String instanceKey) async {
    final saver = _savers[instanceKey.trim()];
    if (saver == null) {
      return {'success': false, 'message': 'Add Water view is not ready'};
    }
    return saver();
  }
}

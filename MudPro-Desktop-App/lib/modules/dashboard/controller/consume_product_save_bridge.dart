import 'package:get/get.dart';

class ConsumeProductSaveBridge extends GetxService {
  Future<Map<String, dynamic>> Function()? _saveHandler;

  bool get canSave => _saveHandler != null;

  void register(Future<Map<String, dynamic>> Function() handler) {
    _saveHandler = handler;
  }

  void unregister() {
    _saveHandler = null;
  }

  Future<Map<String, dynamic>> saveAll() async {
    final handler = _saveHandler;
    if (handler == null) {
      return {
        'success': false,
        'message': 'Consume Product view is not ready',
      };
    }

    return handler();
  }
}

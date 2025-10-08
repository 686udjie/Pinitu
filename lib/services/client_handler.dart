import '../services/pinterest_client.dart';

mixin ClientHandler {
  late PinterestClient _client;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initializeClient() async {
    final client = await PinterestClient.create();
    if (client == null) {
      _initialized = true;
      return;
    }
    _client = client;
    _initialized = true;
  }

  PinterestClient get client => _client;
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'api.dart';

class CustomerSession extends ChangeNotifier {
  final Api api = Api();

  PublicCard? card;
  bool loading = false;
  String? error;
  String? walletMode;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('sella_card');
    if (code != null && code.isNotEmpty) {
      await load(code, persist: false);
    }
  }

  Future<bool> load(String code, {bool persist = true}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final data = await api.get(
        '/api/public/cards/${Uri.encodeComponent(code.trim().toUpperCase())}',
      );
      card = PublicCard.fromJson(data);

      if (persist) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sella_card', card!.code);
      }

      loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      card = null;
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshQr() async {
    final current = card;
    if (current == null) return;

    try {
      final data = await api.get('/api/public/cards/${current.code}');
      card = PublicCard.fromJson(data);
      notifyListeners();
    } catch (_) {
      // Si falla, dejamos el QR anterior visible.
    }
  }

  Future<String?> walletLink() async {
    final current = card;
    if (current == null) return null;

    final data = await api.get('/api/wallet/${current.code}');
    walletMode = data['mode'] as String?;
    final url = data['url'] as String?;
    if (url == null) return null;
    return url.startsWith('http') ? url : '${Api.siteUrl}$url';
  }

  Future<String?> join({
    required String slug,
    required String name,
    required String phone,
  }) async {
    try {
      final data = await api.post(
        '/api/public/programs/${Uri.encodeComponent(slug.trim().toLowerCase())}/join',
        body: {'name': name, 'phone': phone, 'consent': true},
      );
      await load(data['code'] as String);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> clear() async {
    card = null;
    error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sella_card');
    notifyListeners();
  }
}

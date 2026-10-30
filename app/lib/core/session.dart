import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'api.dart';

class Session extends ChangeNotifier {
  final Api api = Api();

  Business? business;
  List<Program> programs = const [];
  Stats stats = const Stats();
  bool booting = true;

  Program? get program => programs.isEmpty ? null : programs.first;
  bool get isLoggedIn => api.token != null && business != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sella_token');

    if (token != null && token.isNotEmpty) {
      api.token = token;
      try {
        await refresh();
      } catch (_) {
        api.token = null;
        await prefs.remove('sella_token');
      }
    }

    booting = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await api.post(
      '/api/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    await _applySession(data);
  }

  Future<void> register({
    required String businessName,
    required String name,
    required String email,
    required String password,
    Color? brandColor,
  }) async {
    final data = await api.post(
      '/api/auth/register',
      body: {
        'businessName': businessName.trim(),
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'brandColor': brandColor == null ? null : colorToHex(brandColor),
      },
    );
    await _applySession(data);
  }

  Future<void> _applySession(Map<String, dynamic> data) async {
    api.token = data['token'] as String?;
    business = Business.fromJson(data['business'] as Map<String, dynamic>);
    programs = (data['programs'] as List<dynamic>)
        .map((item) => Program.fromJson(item as Map<String, dynamic>))
        .toList();

    final prefs = await SharedPreferences.getInstance();
    if (api.token != null) await prefs.setString('sella_token', api.token!);

    await loadStats();
    notifyListeners();
  }

  Future<void> refresh() async {
    final data = await api.get('/api/auth/me');
    business = Business.fromJson(data['business'] as Map<String, dynamic>);
    programs = (data['programs'] as List<dynamic>)
        .map((item) => Program.fromJson(item as Map<String, dynamic>))
        .toList();
    await loadStats();
    notifyListeners();
  }

  Future<void> loadStats() async {
    if (api.token == null) return;
    try {
      final data = await api.get('/api/business');
      stats = Stats.fromJson(data['stats'] as Map<String, dynamic>?);
    } catch (_) {
      // Las métricas no bloquean la pantalla.
    }
  }

  Future<void> saveProgram({
    required String name,
    required String rewardText,
    required int stampsRequired,
    required int cooldownMinutes,
    required CardStyle style,
  }) async {
    final current = program;
    if (current == null) return;

    final data = await api.patch(
      '/api/programs/${current.id}',
      body: {
        'name': name,
        'rewardText': rewardText,
        'stampsRequired': stampsRequired,
        'cooldownMinutes': cooldownMinutes,
        'style': style.toJson(),
      },
    );

    final updated = Program.fromJson(data['program'] as Map<String, dynamic>);
    programs = programs.map((p) => p.id == updated.id ? updated : p).toList();
    notifyListeners();
  }

  Future<void> updateBusiness({String? name, Color? brandColor}) async {
    final data = await api.patch(
      '/api/business',
      body: {
        'name': ?name,
        if (brandColor != null) 'brandColor': colorToHex(brandColor),
      },
    );
    business = Business.fromJson(data['business'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> uploadLogo(Uint8List bytes, String mime) async {
    final base64Data = 'data:$mime;base64,${base64Encode(bytes)}';
    final data = await api.post('/api/business/logo', body: {'dataUrl': base64Data});
    final current = business;
    if (current != null) {
      business = Business(
        id: current.id,
        name: current.name,
        slug: current.slug,
        logoUrl: data['logoUrl'] as String?,
        brandColor: current.brandColor,
      );
      notifyListeners();
    }
  }

  Future<List<MerchantCard>> searchCards(String query) async {
    final data = await api.get('/api/business/cards?q=${Uri.encodeQueryComponent(query)}');
    return (data['cards'] as List<dynamic>)
        .map((item) => MerchantCard.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> createCard({required String name, String? phone}) async {
    final current = program;
    if (current == null) {
      throw ApiException(400, 'Primero configurá un programa');
    }

    final data = await api.post(
      '/api/business/cards',
      body: {
        'programId': current.id,
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    await loadStats();
    notifyListeners();
    return data['code'] as String;
  }

  Future<ScanResult> scan(String token) async {
    final data = await api.post('/api/scan', body: {'token': token});
    return ScanResult.fromJson(data);
  }

  Future<void> addStamp(String cardId) async {
    await api.post('/api/cards/$cardId/stamps');
    await loadStats();
    notifyListeners();
  }

  Future<void> redeem(String cardId) async {
    await api.post('/api/cards/$cardId/redeem');
    await loadStats();
    notifyListeners();
  }

  Future<void> logout() async {
    api.token = null;
    business = null;
    programs = const [];
    stats = const Stats();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sella_token');
    notifyListeners();
  }
}

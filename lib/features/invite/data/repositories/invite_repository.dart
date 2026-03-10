import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../domain/entities/invite.dart';

class InviteRepository {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  InviteRepository({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => Env.backendUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch pending invites for the current user.
  Future<List<Invite>> fetchMyInvites() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/oc/invites/mine'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch invites: ${response.body}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Invite.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Accept an invite by ID.
  Future<void> acceptInvite(String inviteId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/oc/invites/$inviteId/accept'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to accept invite: ${response.body}');
    }
  }

  /// Decline an invite by ID.
  Future<void> declineInvite(String inviteId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/oc/invites/$inviteId/decline'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to decline invite: ${response.body}');
    }
  }
}

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/network/authenticated_client.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';

class UserLookup {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;

  const UserLookup({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory UserLookup.fromJson(Map<String, dynamic> json) {
    return UserLookup(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  String get label =>
      displayName?.trim().isNotEmpty == true ? displayName! : email;
}

final userLookupProvider = FutureProvider.family<UserLookup?, String>((
  ref,
  userId,
) async {
  if (userId.isEmpty) return null;

  // Auto-invalidate on offline → online so a stale "null" from a prior offline
  // build gets re-fetched. ref.read (not watch) on the gate below means going
  // online → offline does NOT rebuild and wipe a previously-cached lookup.
  ref.listen<bool>(syncNotifierProvider.select((s) => s.isOnline), (
    prev,
    next,
  ) {
    if (next && prev == false) ref.invalidateSelf();
  });

  if (!ref.read(syncNotifierProvider).isOnline) return null;

  final client = ref.read(authenticatedClientProvider);
  final response = await client.get('/api/users/$userId');
  guardResponse(response);
  if (response.statusCode == 404) return null;
  if (response.statusCode != 200) return null;
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return UserLookup.fromJson(data);
});

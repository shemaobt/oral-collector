// ignore_for_file: use_null_aware_elements

import 'dart:convert';

import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../domain/entities/storyteller.dart';
import '../../domain/repositories/storyteller_repository.dart';

class StorytellerApiRepositoryImpl implements StorytellerRepository {
  final AuthenticatedClient _client;

  StorytellerApiRepositoryImpl({required AuthenticatedClient client})
    : _client = client;

  @override
  Future<List<Storyteller>> listByProject(String projectId) async {
    final response = await _client.get(
      '/api/oc/projects/$projectId/storytellers',
    );
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to list storytellers: ${response.body}');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Storyteller.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Storyteller> get(String storytellerId) async {
    final response = await _client.get('/api/oc/storytellers/$storytellerId');
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to load storyteller: ${response.body}');
    }
    return Storyteller.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<Storyteller> create({
    required String projectId,
    required String name,
    required StorytellerSex sex,
    int? age,
    String? location,
    String? dialect,
    required bool externalAcceptanceConfirmed,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'sex': sex.toJson(),
      'external_acceptance_confirmed': externalAcceptanceConfirmed,
      if (age != null) 'age': age,
      if (location != null && location.isNotEmpty) 'location': location,
      if (dialect != null && dialect.isNotEmpty) 'dialect': dialect,
    };
    final response = await _client.post(
      '/api/oc/projects/$projectId/storytellers',
      body: body,
    );
    guardResponse(response);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create storyteller: ${response.body}');
    }
    return Storyteller.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<Storyteller> update(
    String storytellerId, {
    String? name,
    StorytellerSex? sex,
    int? age,
    String? location,
    String? dialect,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (sex != null) 'sex': sex.toJson(),
      if (age != null) 'age': age,
      if (location != null) 'location': location,
      if (dialect != null) 'dialect': dialect,
    };
    final response = await _client.patch(
      '/api/oc/storytellers/$storytellerId',
      body: body,
    );
    guardResponse(response);
    if (response.statusCode != 200) {
      throw Exception('Failed to update storyteller: ${response.body}');
    }
    return Storyteller.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> delete(String storytellerId) async {
    final response = await _client.delete(
      '/api/oc/storytellers/$storytellerId',
    );
    guardResponse(response);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete storyteller: ${response.body}');
    }
  }
}

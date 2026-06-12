// ignore_for_file: use_null_aware_elements

import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/authenticated_client.dart';
import '../../../../core/network/response_decoder.dart';
import '../../../../core/serialization/parse_list.dart';
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
    return parseList(
      decodeList(response),
      Storyteller.fromJson,
      context: 'listByProject',
    );
  }

  @override
  Future<Storyteller> get(String storytellerId) async {
    final response = await _client.get('/api/oc/storytellers/$storytellerId');
    return Storyteller.fromJson(decodeObject(response));
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
    return Storyteller.fromJson(decodeObject(response));
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
    return Storyteller.fromJson(decodeObject(response));
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

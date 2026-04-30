import '../entities/storyteller.dart';

abstract class StorytellerRepository {
  Future<List<Storyteller>> listByProject(String projectId);

  Future<Storyteller> get(String storytellerId);

  Future<Storyteller> create({
    required String projectId,
    required String name,
    required StorytellerSex sex,
    int? age,
    String? location,
    String? dialect,
    required bool externalAcceptanceConfirmed,
  });

  Future<Storyteller> update(
    String storytellerId, {
    String? name,
    StorytellerSex? sex,
    int? age,
    String? location,
    String? dialect,
  });

  Future<void> delete(String storytellerId);
}

import '../entities/language.dart';
import '../entities/project.dart';
import '../entities/project_member.dart';

abstract class ProjectRepository {
  Future<List<Project>> listProjects();
  Future<Project> getProject(String id);
  Future<Map<String, dynamic>> getProjectStats(String projectId);
  Future<Project> createProject({
    required String name,
    required String languageId,
    String? description,
  });
  Future<Project> updateProject(String id, Map<String, dynamic> data);
  Future<List<Language>> listLanguages();
  Future<Language> createLanguage({required String name, required String code});
  Future<List<ProjectMember>> listMembers(String projectId);
  Future<void> removeMember(String projectId, String userId);
  Future<void> inviteMember({
    required String projectId,
    required String email,
    required String role,
  });
}

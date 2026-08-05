/// Partial-update body for PATCH /api/projects/{id}. A null field is omitted
/// from the wire (left untouched); [clearDescription] sends an explicit null to
/// clear the description.
class ProjectUpdate {
  final String? name;
  final String? description;
  final bool clearDescription;

  const ProjectUpdate({
    this.name,
    this.description,
    this.clearDescription = false,
  });

  bool get isEmpty => name == null && description == null && !clearDescription;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (clearDescription) {
      json['description'] = null;
    } else if (description != null) {
      json['description'] = description;
    }
    return json;
  }
}

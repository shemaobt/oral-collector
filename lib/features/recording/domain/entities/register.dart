class Register {
  final String id;
  final String name;
  final int sortOrder;

  const Register({
    required this.id,
    required this.name,
    required this.sortOrder,
  });
}

const kRegisters = [
  Register(id: 'intimate', name: 'Intimate', sortOrder: 1),
  Register(id: 'casual', name: 'Informal / Casual', sortOrder: 2),
  Register(id: 'consultative', name: 'Consultative', sortOrder: 3),
  Register(id: 'formal', name: 'Formal / Official', sortOrder: 4),
  Register(id: 'ceremonial', name: 'Ceremonial', sortOrder: 5),
  Register(id: 'elder_authority', name: 'Elder / Authority', sortOrder: 6),
  Register(id: 'religious_worship', name: 'Religious / Worship', sortOrder: 7),
];

String? getRegisterName(String? registerId) {
  if (registerId == null || registerId.isEmpty) return null;
  return kRegisters.where((r) => r.id == registerId).firstOrNull?.name;
}

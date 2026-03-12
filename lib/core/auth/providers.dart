import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepositoryImpl(),
);

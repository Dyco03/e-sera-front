import 'package:e_sera/core/config/app_config.dart';
import 'package:e_sera/core/config/backend_type.dart';

// repos
import 'package:e_sera/features/auth/data/firebase_auth_repo.dart';
import 'package:e_sera/features/auth/data/api_auth_repo.dart';
import 'package:e_sera/features/auth/domain/repos/auth_repo.dart';
import 'package:e_sera/features/post/domain/repos/post_repo.dart';

import 'package:e_sera/features/message/data/api_message_repo.dart';
import 'package:e_sera/features/message/data/firebase_message_repo.dart';
import 'package:e_sera/features/message/domain/repos/message_repo.dart';
import 'package:e_sera/features/profile/data/firebase_profile_repo.dart';
import 'package:e_sera/features/profile/data/api_profile_repo.dart';

import 'package:e_sera/features/post/data/firebase_post_repo.dart';
import 'package:e_sera/features/post/data/api_post_repo.dart';
import 'package:e_sera/features/profile/domain/repos/profile_repo.dart';
import 'package:e_sera/features/search/data/api_search_repo.dart';
import 'package:e_sera/features/search/data/firebase_search_repo.dart';
import 'package:e_sera/features/search/domain/search_repo.dart';
import 'package:e_sera/features/storage/data/api_storage_repo.dart';
import 'package:e_sera/features/storage/data/supabase_storage_repo.dart';
import 'package:e_sera/features/storage/domain/storage_repo.dart';

// client
import 'package:http/http.dart' as http;

class RepoFactory {
  static final backend = AppConfig.backend;

  static final http.Client _client = http.Client();

  static AuthRepo authRepo() {
    switch (backend) {
      case BackendType.firebase:
        return FirebaseAuthRepo();
      case BackendType.api:
        return ApiAuthRepo(_client);
    }
  }

  static ProfileRepo profileRepo() {
    switch (backend) {
      case BackendType.firebase:
        return FirebaseProfileRepo();
      case BackendType.api:
        return ApiProfileRepo(_client);
    }
  }

  static PostRepo postRepo() {
    switch (backend) {
      case BackendType.firebase:
        return FirebasePostRepo();
      case BackendType.api:
        return ApiPostRepo(_client);
    }
  }

  static SearchRepo searchRepo() {
    switch (backend) {
      case BackendType.firebase:
        return FirebaseSearchRepo();
      case BackendType.api:
        return ApiSearchRepo(_client);
    }
  }

  static MessageRepo messageRepo() {
    switch (backend) {
      case BackendType.firebase:
        return FirebaseMessageRepo();
      case BackendType.api:
        return ApiMessageRepo(_client);
    }
  }

  static StorageRepo storageRepo() {
    switch (backend) {
      case BackendType.firebase:
        return SupabaseStorageRepo();
      case BackendType.api:
        return ApiStorageRepo(_client);
    }
  }
}

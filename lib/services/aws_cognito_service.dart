// Deprecated: AWS Cognito service removed for offline mode.
// Keeping a minimal stub to satisfy legacy references if any remain.
class AWSCognitoService {
  static final AWSCognitoService _instance = AWSCognitoService._internal();
  factory AWSCognitoService() => _instance;
  AWSCognitoService._internal();

  Future<bool> signIn({required String email, required String password}) async {
    return false; // always fail; not used in offline mode
  }

  Future<void> signOut() async {}
}

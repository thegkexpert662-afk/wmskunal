enum AppRole {
  masterAdmin,
  admin,
  client,
}

extension AppRoleLabel on AppRole {
  String get label {
    switch (this) {
      case AppRole.masterAdmin:
        return 'Master Admin';
      case AppRole.admin:
        return 'Administrator';
      case AppRole.client:
        return 'Client';
    }
  }
}

AppRole roleFromUsername(String username) {
  final value = username.trim().toLowerCase();
  if (value.contains('master')) return AppRole.masterAdmin;
  if (value.contains('client')) return AppRole.client;
  return AppRole.admin;
}

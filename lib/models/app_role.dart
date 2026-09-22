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

AppRole appRoleFromBackend(String role) {
  switch (role.trim().toLowerCase()) {
    case 'master_admin': return AppRole.masterAdmin;
    case 'client': return AppRole.client;
    case 'admin':
    default: return AppRole.admin;
  }
}

AppRole roleFromUsername(String username) {
  final value = username.trim().toLowerCase();
  if (value.contains('master')) return AppRole.masterAdmin;
  if (value.contains('client')) return AppRole.client;
  return AppRole.admin;
}

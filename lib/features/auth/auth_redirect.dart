import '../../data/models/auth_user.dart';

class AuthRedirect {
  const AuthRedirect({
    required this.routeName,
    this.signUpRole = AccountRole.individualBuyer,
  });

  final String routeName;
  final AccountRole signUpRole;
}

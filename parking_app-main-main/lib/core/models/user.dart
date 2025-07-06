// lib/core/models/user_model.dart

class UserModel {
  final String emausernameil;
  final String password;

  UserModel({required this.username, required this.password});
}

// A simple mock database to store the registered user
UserModel? registeredUser;

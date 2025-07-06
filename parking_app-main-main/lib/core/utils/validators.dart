class Validators {
  static String? validateEmail(String value) {
    if (value.isEmpty) {
      return 'Email cannot be empty';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String value) {
    if (value.isEmpty) {
      return 'Name cannot be empty';
    }
    return null;
  }

  static String? validatePlateNumber(String value) {
    if (value.isEmpty) {
      return 'Plate number cannot be empty';
    }
    return null;
  }
}

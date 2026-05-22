class Validators {
  static String? required(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? integerMin(String? v, {required int min, String field = 'Value'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final n = int.tryParse(v.trim());
    if (n == null) return '$field must be a number';
    if (n < min) return '$field must be at least $min';
    return null;
  }

  static String? numberPositive(String? v, {String field = 'Value'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final n = double.tryParse(v.trim());
    if (n == null) return '$field must be a number';
    if (n < 0) return '$field cannot be negative';
    return null;
  }
}

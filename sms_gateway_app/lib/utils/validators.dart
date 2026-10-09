class Validators {
  static String? validateServerUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Server URL is required';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid URL starting with http:// or https://';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  static String? validateDeviceId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Device ID is required';
    }
    if (value.trim().length < 3) {
      return 'Device ID must be at least 3 characters';
    }
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 7) {
      return 'Enter a valid mobile number';
    }
    return null;
  }
}

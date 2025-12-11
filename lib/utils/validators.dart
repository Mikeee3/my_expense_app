class Validators {
  // Amount Validators
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 1000000) {
      return 'Amount is too large';
    }

    final parts = value.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Maximum 2 decimal places allowed';
    }

    return null;
  }

  // Date Validators
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }

    if (date.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }

    if (date.isBefore(DateTime(2000, 1, 1))) {
      return 'Date is too far in the past';
    }

    return null;
  }

  // Category Validators
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category is required';
    }

    if (value.length > 50) {
      return 'Category name is too long';
    }

    return null;
  }

  // Description Validators
  static String? validateDescription(String? value) {
    if (value == null) return null;

    if (value.length > 500) {
      return 'Description is too long (max 500 characters)';
    }

    return null;
  }

  // Budget Validators
  static String? validateBudget(String? value) {
    if (value == null || value.isEmpty) {
      return 'Budget is required';
    }

    final budget = double.tryParse(value);
    if (budget == null) {
      return 'Please enter a valid number';
    }

    if (budget <= 0) {
      return 'Budget must be greater than 0';
    }

    if (budget > 1000000) {
      return 'Budget is too large';
    }

    return null;
  }

  // Email Validators
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password Validators
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Name Validators
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name is too long';
    }

    final nameRegex = RegExp(r'^[a-zA-Z ]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  // Phone Number Validators
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // URL Validators
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) return null;

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Credit Card Validators
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final cardRegex = RegExp(r'^[0-9]{16}$');
    if (!cardRegex.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
      return 'Please enter a valid card number';
    }

    return null;
  }

  // Expiry Date Validators
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    final expiryRegex = RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$');
    if (!expiryRegex.hasMatch(value)) {
      return 'Please enter a valid expiry date (MM/YY)';
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');

    if (month == null || year == null) {
      return 'Invalid date format';
    }

    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0);

    if (expiryDate.isBefore(now)) {
      return 'Card has expired';
    }

    return null;
  }

  // CVV Validators
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    final cvvRegex = RegExp(r'^[0-9]{3,4}$');
    if (!cvvRegex.hasMatch(value)) {
      return 'Please enter a valid CVV';
    }

    return null;
  }

  // File Validators
  static String? validateFileSize(int bytes, int maxSizeInMB) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;

    if (bytes > maxSizeInBytes) {
      return 'File size must be less than $maxSizeInMB MB';
    }

    return null;
  }

  // Range Validators
  static String? validateRange(double value, double min, double max) {
    if (value < min || value > max) {
      return 'Value must be between $min and $max';
    }

    return null;
  }

  // Custom Validator
  static String? Function(String?) combineValidators(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

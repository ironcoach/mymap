class FormValidationService {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.trim().length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  static String? validateSnippet(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 100) {
        return 'Snippet must be less than 100 characters';
      }
    }
    return null;
  }

  static String? validateStartPoint(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Starting point description is required';
    }
    if (value.trim().length < 3) {
      return 'Starting point must be at least 3 characters';
    }
    if (value.trim().length > 200) {
      return 'Starting point must be less than 200 characters';
    }
    return null;
  }

  static String? validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact name is required';
    }
    if (value.trim().length < 2) {
      return 'Contact name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Contact name must be less than 50 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must have at least 10 digits';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number must have less than 15 digits';
    }
    return null;
  }

  static String? validateDistance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Distance is required';
    }
    
    final distance = int.tryParse(value.trim());
    if (distance == null) {
      return 'Distance must be a valid number';
    }
    if (distance <= 0) {
      return 'Distance must be greater than 0';
    }
    if (distance > 500) {
      return 'Distance must be less than 500 miles/km';
    }
    return null;
  }

  static Map<String, String?> validateRideForm({
    required String? title,
    required String? description,
    String? snippet,
    required String? startPoint,
    required String? contact,
    String? phone,
    required String? distance,
  }) {
    return {
      'title': validateTitle(title),
      'description': validateDescription(description),
      'snippet': validateSnippet(snippet),
      'startPoint': validateStartPoint(startPoint),
      'contact': validateContact(contact),
      'phone': validatePhone(phone),
      'distance': validateDistance(distance),
    };
  }

  static bool isFormValid(Map<String, String?> validationResults) {
    return validationResults.values.every((error) => error == null);
  }

  static String getFirstError(Map<String, String?> validationResults) {
    for (final error in validationResults.values) {
      if (error != null) {
        return error;
      }
    }
    return '';
  }
}
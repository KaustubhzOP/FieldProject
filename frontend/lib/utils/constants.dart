class AppConstants {
  // App Info
  static const String appName = 'Smart Waste Collection';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String driversCollection = 'drivers';
  static const String complaintsCollection = 'complaints';
  static const String routesCollection = 'routes';
  static const String vehiclesCollection = 'vehicles';
  static const String collectionsCollection = 'collections';
  
  // User Roles
  static const String roleResident = 'resident';
  static const String roleDriver = 'driver';
  static const String roleAdmin = 'admin';
  
  // Complaint Types
  static const String complaintMissedCollection = 'Missed Collection';
  static const String complaintLateArrival = 'Late Arrival';
  static const String complaintBehavior = 'Staff Behavior';
  static const String complaintIncomplete = 'Incomplete Collection';
  static const String complaintOther = 'Other';
  
  // Complaint Status
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved = 'resolved';
  static const String statusRejected = 'rejected';
  
  // Driver Status
  static const String driverOnDuty = 'on_duty';
  static const String driverOffDuty = 'off_duty';
  static const String driverBreak = 'on_break';
  
  // Route Status
  static const String routeAssigned = 'assigned';
  static const String routeInProgress = 'in_progress';
  static const String routeCompleted = 'completed';
  static const String routeCancelled = 'cancelled';
  
  // Location Update Interval (seconds)
  static const int locationUpdateInterval = 10;
  
  // ETA Threshold (minutes)
  static const int etaThresholdMinutes = 15;
  
  // Default Location (Mumbai)
  static const double defaultLatitude = 19.0760;
  static const double defaultLongitude = 72.8777;
  
  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyLanguage = 'language';
  static const String keyDarkMode = 'dark_mode';
  
  // Languages
  static const String langEnglish = 'en';
  static const String langHindi = 'hi';
  static const String langMarathi = 'mr';
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network.';
  static const String errorAuth = 'Authentication failed. Please check your credentials.';
  static const String errorLocation = 'Unable to get location. Please enable location services.';
  
  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successSignup = 'Account created successfully!';
  static const String successComplaint = 'Complaint registered successfully!';
  static const String successLogout = 'Logged out successfully!';
}

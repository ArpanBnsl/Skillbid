/// App-wide constants
class AppConstants {
  // Roles
  static const String roleClient = 'client';
  static const String roleProvider = 'provider';

  // Job Status
  static const String jobStatusOpen = 'open';
  static const String jobStatusInProgress = 'in_progress';
  static const String jobStatusCompleted = 'completed';
  static const String jobStatusCancelled = 'cancelled';

  // Bid Status
  static const String bidStatusPending = 'pending';
  static const String bidStatusAccepted = 'accepted';
  static const String bidStatusRejected = 'rejected';
  static const String bidStatusWithdrawn = 'withdrawn';

  // Contract Status
  static const String contractStatusActive = 'active';
  static const String contractStatusCompleted = 'completed';
  static const String contractStatusCancelled = 'cancelled';

  // Message Type
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';

  // Pagination
  static const int pageSize = 20;

  // Supabase Storage
  static const String storageBucketJobs = 'job-images';
  static const String storageBucketPortfolio = 'portfolio-images';
  static const String storageBucketAvatars = 'avatars';
}

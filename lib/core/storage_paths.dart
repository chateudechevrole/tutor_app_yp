/// Centralized Firebase Storage path definitions.
///
/// All storage paths should be defined here to avoid hard-coded strings
/// throughout the codebase.

library;

/// Returns the storage path for a user's avatar
/// Path format: avatars/{uid}/profile.jpg
String avatarPath(String uid) => 'avatars/$uid/profile.jpg';

/// Returns the storage path for tutor verification documents
/// Path format: verifications/{uid}/{fileName}
String verificationPath(String uid, String fileName) =>
    'verifications/$uid/$fileName';

/// Returns the storage path for booking-related files
/// Path format: bookings/{bookingId}/{fileName}
String bookingFilePath(String bookingId, String fileName) =>
    'bookings/$bookingId/$fileName';

/// Returns the storage path for chat attachments
/// Path format: chat_attachments/{threadId}/{fileName}
String chatAttachmentPath(String threadId, String fileName) =>
    'chat_attachments/$threadId/$fileName';

/// Returns the storage path for tutor avatars (legacy path)
/// Path format: tutor_avatars/{uid}.jpg
String tutorAvatarPath(String uid) => 'tutor_avatars/$uid.jpg';

/// Returns the storage path for profile photos
/// Path format: profilePhotos/{uid}/avatar.jpg
String profilePhotoPath(String uid) => 'profilePhotos/$uid/avatar.jpg';

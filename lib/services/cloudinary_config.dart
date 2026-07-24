/// Cloudinary configuration.
///
/// Get these from your Cloudinary dashboard (free tier, no card required):
///   1. Sign up at https://cloudinary.com
///   2. cloudName: shown at the top of your Dashboard
///   3. uploadPreset: Settings → Upload → Upload presets → Add upload preset
///      → Signing Mode: "Unsigned" → save, then copy its name here.
///
/// Unsigned presets are safe to ship in the client — they can only upload,
/// never delete or modify existing assets, and you can restrict them
/// further (folder, file size, formats) from the Cloudinary dashboard.
class CloudinaryConfig {
  static const String cloudName = 'iihl2ued';
  static const String uploadPreset = 'goodness';
}

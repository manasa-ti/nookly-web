import 'package:nookly/core/utils/logger.dart';

/// Utility class for version comparison
/// Handles version format "1.0.7+17" (version+build number)
class VersionUtils {
  /// Compare two version strings in format "1.0.7+17"
  /// Returns true if current >= minimum, false otherwise
  /// 
  /// [current] - Current app version (e.g., "1.0.7+17")
  /// [minimum] - Minimum required version (e.g., "1.0.7+17")
  /// Returns true if current version meets or exceeds minimum version
  static bool isVersionSufficient(String current, String minimum) {
    if (current.isEmpty || minimum.isEmpty) {
      AppLogger.warning('Version comparison: Empty version string provided');
      return true; // If we can't compare, allow app to continue
    }

    try {
      // Split version and build number
      final currentParts = current.split('+');
      final minimumParts = minimum.split('+');

      final currentVersion = currentParts[0].trim();
      final minimumVersion = minimumParts[0].trim();

      // Compare semantic version (major.minor.patch)
      final versionComparison = _compareSemanticVersion(currentVersion, minimumVersion);
      
      if (versionComparison != 0) {
        // Versions are different, return comparison result
        return versionComparison > 0;
      }

      // Versions are equal, compare build numbers
      if (currentParts.length > 1 && minimumParts.length > 1) {
        final currentBuild = int.tryParse(currentParts[1].trim()) ?? 0;
        final minimumBuild = int.tryParse(minimumParts[1].trim()) ?? 0;
        return currentBuild >= minimumBuild;
      } else if (currentParts.length > 1) {
        // Current has build number, minimum doesn't - current is sufficient
        return true;
      } else if (minimumParts.length > 1) {
        // Minimum has build number, current doesn't - need to check
        // If minimum build is 0, current is sufficient
        final minimumBuild = int.tryParse(minimumParts[1].trim()) ?? 0;
        return minimumBuild == 0;
      }

      // Both versions are equal and no build numbers - sufficient
      return true;
    } catch (e) {
      AppLogger.error('Error comparing versions: $current vs $minimum', e);
      return true; // On error, allow app to continue
    }
  }

  /// Compare two semantic versions (e.g., "1.0.7")
  /// Returns: negative if v1 < v2, zero if v1 == v2, positive if v1 > v2
  static int _compareSemanticVersion(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();

    // Normalize to same length by padding with zeros
    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    while (v1Parts.length < maxLength) v1Parts.add(0);
    while (v2Parts.length < maxLength) v2Parts.add(0);

    // Compare each part
    for (int i = 0; i < maxLength; i++) {
      final comparison = v1Parts[i].compareTo(v2Parts[i]);
      if (comparison != 0) {
        return comparison;
      }
    }

    return 0; // Versions are equal
  }
}


import 'package:flutter/material.dart';

class ResponsiveText {
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    // Get screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Define breakpoints
    const double mobileBreakpoint = 360.0; // Small phones
    const double tabletBreakpoint = 768.0; // Tablets
    const double desktopBreakpoint = 1024.0; // Desktop

    // Calculate scale factor based on screen width
    double scaleFactor;

    if (screenWidth <= mobileBreakpoint) {
      // Very small screens - scale down significantly
      scaleFactor = 0.85;
    } else if (screenWidth <= 414.0) {
      // Small phones (iPhone SE, etc.) - scale down moderately
      scaleFactor = 0.9;
    } else if (screenWidth <= 480.0) {
      // Medium phones - slight scale down
      scaleFactor = 0.95;
    } else if (screenWidth <= tabletBreakpoint) {
      // Large phones/small tablets - normal size
      scaleFactor = 1.0;
    } else if (screenWidth <= desktopBreakpoint) {
      // Tablets - slightly larger
      scaleFactor = 1.05;
    } else {
      // Desktop - larger
      scaleFactor = 1.1;
    }

    // Apply minimum font size constraints
    double responsiveSize = baseSize * scaleFactor;

    // Ensure text doesn't get too small to read
    if (baseSize >= 20) {
      // Large text (titles, headers)
      responsiveSize = responsiveSize.clamp(16.0, 36.0);
    } else if (baseSize >= 16) {
      // Medium text (body, labels)
      responsiveSize = responsiveSize.clamp(14.0, 20.0);
    } else {
      // Small text (captions, hints)
      responsiveSize = responsiveSize.clamp(12.0, 16.0);
    }

    return responsiveSize;
  }

  // Helper method for getting responsive padding
  static EdgeInsets getResponsivePadding(
    BuildContext context,
    EdgeInsets basePadding,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth <= 360
        ? 0.8
        : screenWidth <= 414
        ? 0.9
        : 1.0;

    return EdgeInsets.fromLTRB(
      basePadding.left * scaleFactor,
      basePadding.top * scaleFactor,
      basePadding.right * scaleFactor,
      basePadding.bottom * scaleFactor,
    );
  }

  // Helper method for getting responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth <= 360
        ? 0.85
        : screenWidth <= 414
        ? 0.9
        : 1.0;

    return (baseSize * scaleFactor).clamp(16.0, 32.0);
  }
}

// Extension method for easier use
extension ResponsiveTextStyle on TextStyle {
  TextStyle responsive(BuildContext context) {
    return copyWith(
      fontSize: ResponsiveText.getResponsiveFontSize(context, fontSize ?? 14),
    );
  }
}

import 'package:flutter/material.dart';

class AppTheme {
  // Light Pastel Color Palette
  static const Color primaryColor = Color(0xff6C9BCF);
  static const Color secondaryColor = Color(0xffA8D5BA);
  static const Color accentColor = Color(0xffFFB6C1);
  static const Color backgroundColor = Color(0xffFAF9F6);
  static const Color surfaceColor = Color(0xffFFFFFF);
  static const Color cardColor = Color(0xffF8F9FA);
  static const Color textPrimary = Color(0xff2D3748);
  static const Color textSecondary = Color(0xff718096);
  static const Color successColor = Color(0xff38B2AC);
  static const Color warningColor = Color(0xffED8936);
  static const Color errorColor = Color(0xffFC8181);
  static const Color infoColor = Color(0xff4299E1);
  static const Color tableHeadColor = Color(0xff0d9488);
  
  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xff5D8BCF);
  static const Color darkSecondaryColor = Color(0xff88C0A8);
  static const Color darkBackgroundColor = Color(0xff1A202C);
  static const Color darkSurfaceColor = Color(0xff2D3748);
  static const Color darkCardColor = Color(0xff4A5568);
  static const Color darkTextPrimary = Color(0xffF7FAFC);
  static const Color darkTextSecondary = Color(0xffCBD5E0);
  
  // Gradient Presets
  static LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xff6C9BCF), Color(0xff8BB8E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xffA8D5BA), Color(0xffC6E6D5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xffFFB6C1), Color(0xffFFD6DC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xff1E4E79), Color(0xff2C5A8B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text Styles
  static TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.5,
  );
  
  static TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.3,
  );
  
  static TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  
  static TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  
  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [surfaceColor, cardColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration tableHeaderDecoration = BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(8),
      topRight: Radius.circular(8),
    ),
  );
  
  // Input Field Decoration
  static InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xffE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xffE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: errorColor),
    ),
  );
  
  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 2,
    shadowColor: primaryColor.withOpacity(0.3),
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: primaryColor, width: 1),
    ),
    elevation: 0,
  );

  
}

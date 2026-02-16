import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class LanguageTab extends StatefulWidget {
  const LanguageTab({super.key});

  @override
  _LanguageTabState createState() => _LanguageTabState();
}

class _LanguageTabState extends State<LanguageTab> {
  String _selectedLanguage = 'English';

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Hindi',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Text(
              'Select Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        _languages[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      value: _languages[index],
                      groupValue: _selectedLanguage,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedLanguage = value!;
                        });
                      },
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.primaryColor;
                          }
                          return Colors.grey.shade400;
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

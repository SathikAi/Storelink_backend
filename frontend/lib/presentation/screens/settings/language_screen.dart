import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/modern_scaffold.dart';
import '../../widgets/modern_card.dart';
import '../../../core/localization/app_localizations.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  final List<String> _languages = const [
    'English',
    'Tamil',
    'Hindi',
    'Bengali',
    'Marathi',
    'Telugu',
    'Kannada',
    'Malayalam'
  ];

  String t(BuildContext context, String key) {
    final lang = Provider.of<LocaleProvider>(context).currentLanguage;
    return AppLocalizations.translate(lang, key);
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      title: t(context, 'settings'),
      body: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final isSelected = lang == localeProvider.currentLanguage;

              return ModernCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.zero,
                onTap: () {
                  localeProvider.setLanguage(lang);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.cardDark,
                      content: Text(
                        ' ',
                        style: TextStyle(color: Colors.white),
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.2) : Colors.white10),
                        ),
                        child: Center(
                          child: Text(
                            lang[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? AppColors.accentBlue : Colors.white38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          lang,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.accentBlue, size: 24)
                      else
                        const Icon(Icons.circle_outlined, color: Colors.white12, size: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

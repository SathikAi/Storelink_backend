import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../../core/localization/app_localizations.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  String t(BuildContext context, String key) {
    final lang = Provider.of<LocaleProvider>(context).currentLanguage;
    return AppLocalizations.translate(lang, key);
  }

  @override
  Widget build(BuildContext context) {
    // Premium Dark Theme
    const Color bgDark = Color(0xFF09090E);
    const Color cardDark = Color(0xFF16161F);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          t(context, 'customer_feedback'),
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Placeholder for actual reviews
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer #${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          color: i < (5 - index % 2) ? Colors.amber : Colors.white10,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  index % 2 == 0 
                    ? 'Excellent service! The delivery was very fast and the product quality is top-notch. Highly recommended!' 
                    : 'Good product but delivery took slightly longer than expected. Overall satisfied.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  '2 hours ago',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

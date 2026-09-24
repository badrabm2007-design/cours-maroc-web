import 'package:flutter/material.dart';
import '../services/app_language_service.dart';
import '../services/smart_banner_service.dart';

class SmartBannerCardWidget extends StatelessWidget {
  final SmartBannerItem item;
  final bool isDark;
  final AppLanguageService langService;

  const SmartBannerCardWidget({
    super.key,
    required this.item,
    required this.isDark,
    required this.langService,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = langService.isArabic;
    final title = isAr ? item.titleAr : item.title;
    final subtitle = isAr ? item.subtitleAr : item.subtitle;
    final description = isAr ? item.descriptionAr : item.description;
    final buttonLabel = isAr ? item.buttonLabelAr : item.buttonLabel;
    final badgeText = isAr ? item.badgeTextAr : item.badgeText;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.primaryColor.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header (Icon / Image + Title + Badge)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon or Image
              if (item.assetImagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    item.assetImagePath!,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildFallbackIcon(),
                  ),
                )
              else
                _buildFallbackIcon(),

              const SizedBox(width: 8),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.badgeColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? item.primaryColor.withValues(alpha: 0.9)
                            : item.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Short Description (Concise, up to 2 lines)
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.3,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),

          const SizedBox(height: 10),

          // 3. Action Button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              icon: Icon(
                item.icon ?? Icons.arrow_forward_rounded,
                size: 15,
              ),
              label: Text(
                buttonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: item.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1.2,
              ),
              onPressed: item.onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: item.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        item.icon ?? Icons.star_rounded,
        color: item.primaryColor,
        size: 20,
      ),
    );
  }
}

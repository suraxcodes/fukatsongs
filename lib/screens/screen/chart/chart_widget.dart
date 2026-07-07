// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:fukatsongs/core/theme/app_theme.dart';
import 'package:fukatsongs/src/rust/api/plugin/models.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:fukatsongs/utils/load_image.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ChartWidget extends StatelessWidget {
  final ChartSummary chart;
  final String pluginId;

  const ChartWidget({
    super.key,
    required this.chart,
    required this.pluginId,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    final artwork = chart.thumbnail;
    final thumbnailUrl = artwork?.urlHigh ?? artwork?.url ?? artwork?.urlLow;

    return Container(
      width: isMobile
          ? MediaQuery.of(context).size.height * 0.3
          : isTablet
              ? MediaQuery.of(context).size.width * 0.3
              : MediaQuery.of(context).size.width * 0.25,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 234, 220, 234).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Default_Theme.primaryColor2.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                    ? LoadImageCached(
                        imageUrl: thumbnailUrl,
                        fallbackUrl: artwork?.url ?? thumbnailUrl,
                        fit: BoxFit.cover,
                      )
                    : const _ChartPlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Top Chart:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Default_Theme.secondoryTextStyle.merge(
              TextStyle(
                color: Default_Theme.primaryColor2.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chart.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Default_Theme.primaryTextStyle.merge(
              const TextStyle(
                color: Default_Theme.primaryColor1,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Global Charts',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Default_Theme.secondoryTextStyle.merge(
              TextStyle(
                color: Default_Theme.primaryColor2.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Default_Theme.primaryColor2.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          MingCute.music_2_fill,
          size: 48,
          color: Default_Theme.primaryColor1.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tajweed_rules/tajweed_rules.dart';
import 'package:tajweed_rules/tajweed_rules.dart' as TajweedRules;

/// Strongly-typed Enum representing Tajweed rule categories based on standard Tajweed color coding
/// (matching Dar Al-Ma'rifah / مصحف التجويد دار المعرفة).
enum TajweedRuleType {
  /// 1. مد 6 حركات لزوماً (Compulsory Madd - 6 counts) - Crimson / Dark Red (#A81268)
  maddLazim,

  /// 2. مد واجب 4 أو 5 حركات (Obligatory Connected/Separated Madd - 4 or 5 counts) - Vivid Pink / Magenta (#E6007A)
  maddWajib,

  /// 3. مد 2 أو 4 أو 6 جوازاً (Permissible Madd: Arid, Lin, Badal - 2, 4, 6 counts) - Warm Orange (#F58220)
  maddJaiz,

  /// 4. مد حركتان (Natural / Normal Madd - 2 counts) - Amber / Ochre (#D4881C)
  maddTabeei,

  /// 5. إخفاء، ومواقع الغنة (Ikhfaa, Ghunnah, Idgham with Ghunnah, Iqlab - 2 counts) - Emerald Green (#00965E)
  ikhfaaAndGhunnah,

  /// 6. إدغام، وما لا يُلفظ (Idgham without Ghunnah, Unpronounced letters, Lam Shamsiyyah) - Grey (#9E9E9E)
  idghamAndUnpronounced,

  /// 7. تفخيم (Tafkhim / Heavy letters) - Deep Navy Blue (#0B4F8A)
  tafkhim,

  /// 8. قلقلة (Qalqalah / Echoing sound) - Sky Blue / Cyan (#00AEEF)
  qalqalah,

  /// 9. إظهار (Izhar / Clarity) - Soft Teal (#00838F)
  izhar,

  /// 10. ترقيق (Tarqeeq / Light letters) - Warm Gold (#E6A100)
  tarqeeq,

  /// 11. وقوف وسكت (Waqf & Sakt) - Slate Grey (#757575)
  waqfAndSakt,

  /// Other / Unclassified
  other;

  /// Map any English rule identifier string to its corresponding strongly-typed [TajweedRuleType]
  static TajweedRuleType fromRuleName(String ruleEnglishName) {
    final key = ruleEnglishName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (key.startsWith('madd_lazim')) {
      return TajweedRuleType.maddLazim;
    } else if (key == 'madd_muttasil' ||
        key == 'madd_munfasil' ||
        key == 'madd_silah' ||
        key == 'madd_silah_kubra') {
      return TajweedRuleType.maddWajib;
    } else if (key == 'madd_arid' ||
        key == 'madd_arid_lissukoon' ||
        key == 'madd_lin' ||
        key == 'madd_badal') {
      return TajweedRuleType.maddJaiz;
    } else if (key == 'madd_tabeei' ||
        key == 'madd_iwad' ||
        key == 'madd_tamkeen' ||
        key == 'madd_silah_sughra') {
      return TajweedRuleType.maddTabeei;
    } else if (key == 'al_ikhfaa_al_haqiqi' ||
        key == 'al_ikhfaa_al_shafawi' ||
        key == 'idgham_with_ghunnah' ||
        key == 'idgham_naqis_incomplete' ||
        key == 'al_idgham_al_shafawi' ||
        key == 'al_iqlab' ||
        key == 'ghunnah') {
      return TajweedRuleType.ikhfaaAndGhunnah;
    } else if (key == 'idgham_without_ghunnah' ||
        key == 'idgham_kamil_complete' ||
        key == 'al_idgham_al_shamsi' ||
        key == 'hamzat_wasl_saqitah' ||
        key == 'naql') {
      return TajweedRuleType.idghamAndUnpronounced;
    } else if (key == 'tafkhim_ra' ||
        key == 'tafkhim_lafz_al_jalalah' ||
        key == 'tafkhim') {
      return TajweedRuleType.tafkhim;
    } else if (key.startsWith('qalqalah')) {
      return TajweedRuleType.qalqalah;
    } else if (key.startsWith('al_izhar') || key == 'izhar') {
      return TajweedRuleType.izhar;
    } else if (key.startsWith('tarqeeq')) {
      return TajweedRuleType.tarqeeq;
    } else if (key.startsWith('waqf') || key == 'sakt' || key == 'wasl_awla') {
      return TajweedRuleType.waqfAndSakt;
    }

    return TajweedRuleType.other;
  }
}

/// Extension for convenient access on [TajweedRuleMatch]
extension TajweedRuleMatchExtension on TajweedRuleMatch {
  TajweedRuleType get ruleType => TajweedRuleType.fromRuleName(ruleEnglishName);
}

class InteractiveTajweedText extends StatefulWidget {
  final String originalVerse;
  final RecitationStyleType style;
  final double fontSize;
  final double lineHeight;
  final String fontFamily;

  /// Dynamic color map override using strongly-typed [TajweedRuleType] enums
  final Map<TajweedRuleType, Color>? colorMap;

  /// Optional rule-specific string color map override (e.g. 'al_iqlab': Colors.amber)
  final Map<String, Color>? customRuleColorMap;

  /// Optional default non-tajweed text color (defaults to non-black/non-white slate)
  final Color? defaultTextColor;

  const InteractiveTajweedText({
    super.key,
    required this.originalVerse,
    this.style = RecitationStyleType.warsh,
    this.fontSize = 32,
    this.lineHeight = 2.0,
    this.fontFamily = 'Amiri',
    this.colorMap,
    this.customRuleColorMap,
    this.defaultTextColor,
  });

  @override
  State<InteractiveTajweedText> createState() => _InteractiveTajweedTextState();
}

class _InteractiveTajweedTextState extends State<InteractiveTajweedText> {
  List<TajweedRuleMatch> matches = [];
  String displayVerse = '';

  @override
  void initState() {
    super.initState();
    _updateMatches();
  }

  @override
  void didUpdateWidget(covariant InteractiveTajweedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalVerse != widget.originalVerse ||
        oldWidget.style != widget.style) {
      _updateMatches();
    }
  }

  void _updateMatches() {
    final processor = TajweedRules.tajweedRulesInit();
    matches = TajweedRules.processVerse(
      verse: widget.originalVerse,
      style: widget.style,
      processorWarsh: processor,
    );

    displayVerse = TajweedRules.processVerseWithZwj(
      verse: widget.originalVerse,
      processor: processor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor =
        widget.defaultTextColor ??
        (isDark
            ? TajweedColors.defaultDarkTextColor
            : TajweedColors.defaultLightTextColor);

    if (matches.isEmpty) {
      return Text(
        displayVerse,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontFamily: widget.fontFamily,
          height: widget.lineHeight,
          color: fallbackColor,
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(
          fontSize: widget.fontSize,
          height: widget.lineHeight,
          fontFamily: widget.fontFamily,
          color: fallbackColor,
        ),
        children: _buildTajweedSpans(context),
      ),
    );
  }

  List<TextSpan> _buildTajweedSpans(BuildContext context) {
    final charRuleMatches = <int, TajweedRuleMatch>{};

    for (final match in matches) {
      final startIdx = match.startIndex.toInt();
      int endIdx = match.endIndex.toInt();

      if (startIdx < 0 || endIdx > widget.originalVerse.length) {
        if (kDebugMode) {
          print(
            '❌ Match indices out of bounds: '
            'start=$startIdx, end=$endIdx, length=${widget.originalVerse.length}',
          );
        }
        continue;
      }

      if (startIdx >= endIdx) {
        endIdx++;
      }

      for (int i = startIdx; i < endIdx; i++) {
        if (charRuleMatches.containsKey(i) && kDebugMode) {
          print(
            '⚠️ Overlapping rules at index $i: '
            '${charRuleMatches[i]?.ruleEnglishName} -> ${match.ruleEnglishName}',
          );
        }
        charRuleMatches[i] = match;
      }
    }

    final spans = <TextSpan>[];
    int originalIdx = 0;
    int displayIdx = 0;

    while (displayIdx < displayVerse.length &&
        originalIdx < widget.originalVerse.length) {
      final spanStart = displayIdx;
      final spanRuleMatch = charRuleMatches[originalIdx];

      while (displayIdx < displayVerse.length &&
          originalIdx < widget.originalVerse.length) {
        final charAtDisplay = displayVerse[displayIdx];

        if (charAtDisplay == '\u200D') {
          displayIdx++;
          continue;
        }

        final nextRuleMatch = charRuleMatches[originalIdx];
        if (_hasRuleChanged(nextRuleMatch, spanRuleMatch)) {
          break;
        }

        displayIdx++;
        originalIdx++;
      }

      if (displayIdx > spanStart) {
        spans.add(
          _createTextSpan(
            context,
            displayVerse.substring(spanStart, displayIdx),
            spanRuleMatch,
          ),
        );
      }
    }

    if (displayIdx < displayVerse.length) {
      spans.add(
        _createTextSpan(context, displayVerse.substring(displayIdx), null),
      );
    }

    return spans;
  }

  bool _hasRuleChanged(TajweedRuleMatch? next, TajweedRuleMatch? current) {
    if (next == current) return false;
    if (next == null || current == null) return next != current;

    return next.ruleEnglishName != current.ruleEnglishName ||
        next.isWarshSpecific != current.isWarshSpecific;
  }

  TextSpan _createTextSpan(
    BuildContext context,
    String text,
    TajweedRuleMatch? ruleMatch,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor =
        widget.defaultTextColor ??
        (isDark
            ? TajweedColors.defaultDarkTextColor
            : TajweedColors.defaultLightTextColor);

    final color = ruleMatch != null
        ? TajweedColors.getColorForRule(
            ruleMatch.ruleEnglishName,
            ruleMatch.isWarshSpecific,
            isDark,
            colorMap: widget.colorMap,
            customStringColorMap: widget.customRuleColorMap,
          )
        : fallbackColor;

    final baseStyle = TextStyle(
      color: color,
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      fontWeight: FontWeight.normal,
    );

    if (ruleMatch != null) {
      return TextSpan(
        text: text,
        style: baseStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _showRuleTooltip(context, ruleMatch, widget.originalVerse);
          },
      );
    } else {
      return TextSpan(text: text, style: baseStyle);
    }
  }

  void _showRuleTooltip(
    BuildContext context,
    TajweedRuleMatch ruleMatch,
    String originalVerse,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ruleMatch.ruleArabicName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: colorScheme.onPrimary,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Description Card
                        _buildInfoCard(
                          context: context,
                          icon: Icons.description_outlined,
                          title: 'الوصف',
                          child: Text(
                            ruleMatch.description,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Details Card
                        _buildInfoCard(
                          context: context,
                          icon: Icons.info_outline,
                          title: 'تفاصيل الحكم',
                          child: Column(
                            children: [
                              _buildDetailRow(
                                context,
                                'اسم الحكم',
                                ruleMatch.ruleArabicName,
                                isArabic: true,
                              ),
                              if (ruleMatch.ruleEnglishName.isNotEmpty)
                                _buildDetailRow(
                                  context,
                                  'المعرّف التقني',
                                  ruleMatch.ruleEnglishName,
                                ),
                              _buildDetailRow(
                                context,
                                'نوع الحكم (Enum)',
                                ruleMatch.ruleType.name,
                              ),
                              _buildDetailRow(
                                context,
                                'المقطع',
                                _extractWordFromVerse(
                                  originalVerse,
                                  ruleMatch.startIndex.toInt(),
                                  ruleMatch.endIndex.toInt(),
                                ),
                                isArabic: true,
                              ),
                              _buildDetailRow(
                                context,
                                'الحرف المستهدف',
                                ruleMatch.targetLetter,
                                isArabic: true,
                              ),
                              if (ruleMatch.followingLetter != null)
                                _buildDetailRow(
                                  context,
                                  'الحرف التالي',
                                  ruleMatch.followingLetter!,
                                  isArabic: true,
                                ),
                              _buildDetailRow(
                                context,
                                'الموضع',
                                '${ruleMatch.startIndex} - ${ruleMatch.endIndex}',
                              ),
                              if (ruleMatch.maddLength != null)
                                _buildDetailRow(
                                  context,
                                  'طول المد',
                                  '${ruleMatch.maddLength!.$1} - ${ruleMatch.maddLength!.$2} حركات',
                                ),
                            ],
                          ),
                        ),

                        // Warsh Specific Badge
                        if (ruleMatch.isWarshSpecific) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade100,
                                  Colors.purple.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.purple.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 20,
                                  color: Colors.purple.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'حكم خاص بورش',
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('حسناً'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isArabic = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: isArabic ? 18 : 14,
                fontWeight: isArabic ? FontWeight.w500 : FontWeight.normal,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractWordFromVerse(String verse, int startIndex, int endIndex) {
    if (verse.isEmpty ||
        startIndex < 0 ||
        endIndex > verse.length ||
        startIndex >= endIndex) {
      return '';
    }

    int wordStart = startIndex;
    int wordEnd = endIndex;

    while (wordStart > 0 && !RegExp(r'\s').hasMatch(verse[wordStart - 1])) {
      wordStart--;
    }

    while (wordEnd < verse.length && !RegExp(r'\s').hasMatch(verse[wordEnd])) {
      wordEnd++;
    }

    return verse.substring(wordStart, wordEnd).trim();
  }
}

// ColoredTajweedText with enum-based colorMap and dynamic theme support
class ColoredTajweedText extends StatelessWidget {
  final String originalVerse;
  final String displayVerse;
  final List<TajweedRuleMatch> matches;
  final double fontSize;
  final double lineHeight;

  /// Dynamic color map override using strongly-typed [TajweedRuleType] enums
  final Map<TajweedRuleType, Color>? colorMap;

  /// Optional rule-specific string color map override
  final Map<String, Color>? customRuleColorMap;

  /// Optional default non-tajweed text color (defaults to non-black/non-white slate)
  final Color? defaultTextColor;

  const ColoredTajweedText({
    super.key,
    required this.originalVerse,
    required this.displayVerse,
    required this.matches,
    this.fontSize = 32,
    this.lineHeight = 2.0,
    this.colorMap,
    this.customRuleColorMap,
    this.defaultTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor =
        defaultTextColor ??
        (isDark
            ? TajweedColors.defaultDarkTextColor
            : TajweedColors.defaultLightTextColor);

    if (matches.isEmpty) {
      return Text(
        displayVerse,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: fontSize,
          height: lineHeight,
          color: fallbackColor,
        ),
      );
    }

    final Map<int, Color> charColors = {};

    for (final match in matches) {
      final color = TajweedColors.getColorForRule(
        match.ruleEnglishName,
        match.isWarshSpecific,
        isDark,
        colorMap: colorMap,
        customStringColorMap: customRuleColorMap,
      );

      final startIdx = match.startIndex.toInt();
      final endIdx = match.endIndex.toInt();

      for (int i = startIdx; i < endIdx && i < originalVerse.length; i++) {
        charColors[i] = color;
      }
    }

    final spans = <TextSpan>[];
    int originalIdx = 0;
    int displayIdx = 0;

    while (displayIdx < displayVerse.length &&
        originalIdx < originalVerse.length) {
      final currentColor = charColors[originalIdx];
      int spanStart = displayIdx;
      Color? spanColor = currentColor;

      while (displayIdx < displayVerse.length &&
          originalIdx < originalVerse.length) {
        final charAtDisplay = displayVerse[displayIdx];

        if (charAtDisplay == '\u200D') {
          displayIdx++;
          continue;
        }

        final nextColor = charColors[originalIdx];
        if (nextColor != spanColor) {
          break;
        }

        displayIdx++;
        originalIdx++;
      }

      if (displayIdx > spanStart) {
        spans.add(
          TextSpan(
            text: displayVerse.substring(spanStart, displayIdx),
            style: TextStyle(
              color: spanColor ?? fallbackColor,
              fontWeight: FontWeight.normal,
            ),
          ),
        );
      }
    }

    if (displayIdx < displayVerse.length) {
      spans.add(
        TextSpan(
          text: displayVerse.substring(displayIdx),
          style: TextStyle(color: fallbackColor, fontWeight: FontWeight.normal),
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, height: lineHeight),
        children: spans,
      ),
    );
  }
}

class TajweedRuleCard extends StatelessWidget {
  final TajweedRuleMatch match;
  final int index;
  final void Function(TajweedRuleMatch match)? onReport;

  const TajweedRuleCard({
    super.key,
    required this.match,
    required this.index,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: match.isWarshSpecific
                    ? [Colors.purple.shade400, Colors.purple.shade600]
                    : [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            match.ruleArabicName,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          subtitle: match.ruleEnglishName.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    match.ruleEnglishName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              : null,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    'الحرف المستهدف',
                    match.targetLetter,
                    isArabic: true,
                  ),
                  if (match.followingLetter != null)
                    _buildInfoRow(
                      context,
                      'الحرف التالي',
                      match.followingLetter!,
                      isArabic: true,
                    ),
                  _buildInfoRow(
                    context,
                    'الموضع',
                    '${match.startIndex} - ${match.endIndex}',
                  ),
                  _buildInfoRow(
                    context,
                    'السياق',
                    match.context,
                    isArabic: true,
                  ),
                  if (match.maddLength != null)
                    _buildInfoRow(
                      context,
                      'طول المد',
                      '${match.maddLength!.$1} - ${match.maddLength!.$2} حركات',
                    ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الوصف',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    match.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  if (match.isWarshSpecific) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade100,
                            Colors.purple.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'حكم خاص بورش',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (onReport != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          side: BorderSide(color: Colors.orange.shade300),
                          foregroundColor: Colors.orange.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.report_problem_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'إبلاغ عن خطأ في هذا الحكم',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => onReport!(match),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isArabic = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: isArabic ? 18 : 14,
                fontWeight: isArabic ? FontWeight.w500 : FontWeight.normal,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard Tajweed Colors matching Dar Al-Ma'rifah (مصحف التجويد دار المعرفة)
/// with strongly-typed [TajweedRuleType] enum customization and non-black/non-white text defaults.
class TajweedColors {
  // --- Core Dar Al-Ma'rifah Color Palette (from reference 293.jpg) ---

  /// 1. مد 6 حركات لزوماً (Compulsory Madd - 6 counts) - Deep Crimson / Dark Red (#A81268)
  static const Color madd6CountsLazim = Color(0xFFA81268);

  /// 2. مد واجب 4 أو 5 حركات (Obligatory Madd - 4 or 5 counts) - Vivid Pink / Magenta (#E6007A)
  static const Color maddWajib = Color(0xFFE6007A);

  /// 3. مد 2 أو 4 أو 6 جوازاً (Permissible Madd - 2, 4, 6 counts) - Warm Orange (#F58220)
  static const Color maddJaiz = Color(0xFFF58220);

  /// 4. مد حركتان (Natural Madd - 2 counts) - Amber / Ochre (#D4881C)
  static const Color maddTabeei2Counts = Color(0xFFD4881C);

  /// 5. إخفاء، ومواقع الغنة (Ikhfaa & Ghunnah - 2 counts) - Emerald Green (#00965E)
  static const Color ikhfaaAndGhunnah = Color(0xFF00965E);

  /// 6. إدغام، وما لا يُلفظ (Idgham without Ghunnah & Unpronounced letters) - Neutral Slate Grey (#9E9E9E)
  static const Color idghamAndUnpronounced = Color(0xFF9E9E9E);

  /// 7. تفخيم (Tafkhim - Emphatic / Heavy) - Deep Navy Blue (#0B4F8A)
  static const Color tafkhim = Color(0xFF0B4F8A);

  /// 8. قلقلة (Qalqalah - Echoing / Bouncing) - Sky Blue / Cyan (#00AEEF)
  static const Color qalqalah = Color(0xFF00AEEF);

  /// 9. إظهار (Izhar - Clarity) - Soft Teal (#00838F)
  static const Color izhar = Color(0xFF00838F);

  /// 10. ترقيق (Tarqeeq) - Warm Gold (#E6A100)
  static const Color tarqeeq = Color(0xFFE6A100);

  /// 11. وقوف وسكت (Waqf & Sakt) - Slate Grey (#757575)
  static const Color waqfAndSakt = Color(0xFF757575);

  /// Non-black / Non-white default Quran text colors
  static const Color defaultLightTextColor = Color(
    0xFF1E293B,
  ); // Dark Slate Charcoal
  static const Color defaultDarkTextColor = Color(
    0xFFE2E8F0,
  ); // Light Platinum Slate

  static String _normalizeRuleKey(String ruleName) {
    return ruleName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Global runtime custom enum overrides
  static final Map<TajweedRuleType, Color> _globalCustomTypeColors = {};

  /// Global runtime custom string overrides
  static final Map<String, Color> _globalCustomStringColors = {};

  /// Set or override a color for a specific [TajweedRuleType] enum dynamically
  static void setRuleTypeColor(TajweedRuleType type, Color color) {
    _globalCustomTypeColors[type] = color;
  }

  /// Set multiple rule type colors dynamically using enums
  static void setCustomTypeColors(Map<TajweedRuleType, Color> colors) {
    _globalCustomTypeColors.addAll(colors);
  }

  /// Set or override a color for a specific rule string key dynamically
  static void setRuleColor(String ruleName, Color color) {
    _globalCustomStringColors[_normalizeRuleKey(ruleName)] = color;
  }

  /// Remove custom overrides and reset to Dar Al-Ma'rifah standard palette
  static void resetToDefault() {
    _globalCustomTypeColors.clear();
    _globalCustomStringColors.clear();
  }

  /// Standard Dar Al-Ma'rifah Light palette mapping for each [TajweedRuleType]
  static const Map<TajweedRuleType, Color> defaultLightTypeColorMap = {
    TajweedRuleType.maddLazim: madd6CountsLazim,
    TajweedRuleType.maddWajib: maddWajib,
    TajweedRuleType.maddJaiz: maddJaiz,
    TajweedRuleType.maddTabeei: maddTabeei2Counts,
    TajweedRuleType.ikhfaaAndGhunnah: ikhfaaAndGhunnah,
    TajweedRuleType.idghamAndUnpronounced: idghamAndUnpronounced,
    TajweedRuleType.tafkhim: tafkhim,
    TajweedRuleType.qalqalah: qalqalah,
    TajweedRuleType.izhar: izhar,
    TajweedRuleType.tarqeeq: tarqeeq,
    TajweedRuleType.waqfAndSakt: waqfAndSakt,
    TajweedRuleType.other: defaultLightTextColor,
  };

  /// High contrast dark mode variant mapping for each [TajweedRuleType]
  static const Map<TajweedRuleType, Color> defaultDarkTypeColorMap = {
    TajweedRuleType.maddLazim: Color(0xFFD81B60),
    TajweedRuleType.maddWajib: Color(0xFFFF4081),
    TajweedRuleType.maddJaiz: Color(0xFFFF9800),
    TajweedRuleType.maddTabeei: Color(0xFFFFB74D),
    TajweedRuleType.ikhfaaAndGhunnah: Color(0xFF00E676),
    TajweedRuleType.idghamAndUnpronounced: Color(0xFFB0BEC5),
    TajweedRuleType.tafkhim: Color(0xFF42A5F5),
    TajweedRuleType.qalqalah: Color(0xFF29B6F6),
    TajweedRuleType.izhar: Color(0xFF26C6DA),
    TajweedRuleType.tarqeeq: Color(0xFFFFD54F),
    TajweedRuleType.waqfAndSakt: Color(0xFF90A4AE),
    TajweedRuleType.other: defaultDarkTextColor,
  };

  /// Returns the color for a given [TajweedRuleType] enum with cascading overrides
  static Color getColorForType(
    TajweedRuleType type, {
    bool isDarkMode = false,
    Map<TajweedRuleType, Color>? colorMap,
  }) {
    // 1. Instance-level enum map override
    if (colorMap != null && colorMap.containsKey(type)) {
      return colorMap[type]!;
    }

    // 2. Global runtime enum override
    if (_globalCustomTypeColors.containsKey(type)) {
      return _globalCustomTypeColors[type]!;
    }

    // 3. Dar Al-Ma'rifah standard palette
    final baseMap = isDarkMode
        ? defaultDarkTypeColorMap
        : defaultLightTypeColorMap;
    return baseMap[type] ??
        (isDarkMode ? defaultDarkTextColor : defaultLightTextColor);
  }

  /// Returns the appropriate color for any given rule with cascading overrides:
  /// 1. Widget custom string map (if provided)
  /// 2. Widget enum colorMap (if provided)
  /// 3. Global custom string & enum overrides
  /// 4. Dar Al-Ma'rifah standard palette
  /// 5. Fallback non-black/non-white text color
  static Color getColorForRule(
    String ruleEnglishName,
    bool isWarshSpecific,
    bool isDarkMode, {
    Map<TajweedRuleType, Color>? colorMap,
    Map<String, Color>? customStringColorMap,
  }) {
    final normalized = _normalizeRuleKey(ruleEnglishName);

    // 1. Instance-level custom string override
    if (customStringColorMap != null &&
        customStringColorMap.containsKey(normalized)) {
      return customStringColorMap[normalized]!;
    }

    // 2. Global runtime custom string override
    if (_globalCustomStringColors.containsKey(normalized)) {
      return _globalCustomStringColors[normalized]!;
    }

    // 3. Enum-based resolution
    final type = TajweedRuleType.fromRuleName(ruleEnglishName);
    return getColorForType(type, isDarkMode: isDarkMode, colorMap: colorMap);
  }

  /// Returns a full map of [TajweedRuleType] -> [Color] for the active theme
  static Map<TajweedRuleType, Color> getActiveTypeColorMap({
    bool isDarkMode = false,
  }) {
    final map = Map<TajweedRuleType, Color>.from(
      isDarkMode ? defaultDarkTypeColorMap : defaultLightTypeColorMap,
    );
    map.addAll(_globalCustomTypeColors);
    return map;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tajweed_rules/tajweed_rules.dart';

class InteractiveTajweedText extends StatefulWidget {
  final String originalVerse;
  final RecitationStyleType style;

  const InteractiveTajweedText({
    super.key,
    required this.originalVerse,
    this.style = RecitationStyleType.both,
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
    final processor = TajweedRules.tajweedRulesInit();
    // First process the verse to get matches (based on original verse)
    matches = TajweedRules.processVerse(
      verse: widget.originalVerse,
      style: widget.style,
      processorWarsh: processor,
    );

    // Then apply ZWJ for display rendering
    displayVerse = TajweedRules.processVerseWithZwj(
      verse: widget.originalVerse,
      processor: processor,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Early return for empty matches
    if (matches.isEmpty) {
      return Text(
        displayVerse,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 32, height: 2.0),
      );
    }

    // Build the rich text with Tajweed rules
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(fontSize: 32, height: 2.0),
        children: _buildTajweedSpans(context),
      ),
    );
  }

  /// Builds text spans with Tajweed rule highlighting
  List<TextSpan> _buildTajweedSpans(BuildContext context) {
    // Create a map to track which characters in original verse have rules applied
    final charRuleMatches = <int, TajweedRuleMatch>{};

    for (final match in matches) {
      final startIdx = match.startIndex.toInt();
      int endIdx = match.endIndex.toInt();

      // Comprehensive validation
      if (startIdx < 0 || endIdx > widget.originalVerse.length) {
        if (kDebugMode) {
          print(
            '❌ Match indices out of bounds: '
            'start=$startIdx, end=$endIdx, length=${widget.originalVerse.length}',
          );
        }
        continue;
      }

      // ✅ CRITICAL: Skip empty matches (indicates Rust detection bug)
      if (startIdx >= endIdx) {
        endIdx++;
      }

      // Mark all characters in this range with the rule match
      for (int i = startIdx; i < endIdx; i++) {
        // Optional: Warn about overlapping rules
        if (charRuleMatches.containsKey(i) && kDebugMode) {
          print(
            '⚠️ Overlapping rules at index $i: '
            '${charRuleMatches[i]?.ruleEnglishName} -> ${match.ruleEnglishName}',
          );
        }
        charRuleMatches[i] = match;
      }
    }

    // Build text spans for the display verse (with ZWJ)
    final spans = <TextSpan>[];
    int originalIdx = 0;
    int displayIdx = 0;

    while (displayIdx < displayVerse.length &&
        originalIdx < widget.originalVerse.length) {
      final spanStart = displayIdx;
      final spanRuleMatch = charRuleMatches[originalIdx];

      // Find the extent of this rule span
      while (displayIdx < displayVerse.length &&
          originalIdx < widget.originalVerse.length) {
        final charAtDisplay = displayVerse[displayIdx];

        // Skip ZWJ characters (which don't exist in original)
        if (charAtDisplay == '\u200D') {
          displayIdx++;
          continue;
        }

        // Check if rule changed
        final nextRuleMatch = charRuleMatches[originalIdx];
        if (_hasRuleChanged(nextRuleMatch, spanRuleMatch)) {
          break;
        }

        displayIdx++;
        originalIdx++;
      }

      // Add the span
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

    // Add any remaining display text
    if (displayIdx < displayVerse.length) {
      spans.add(
        _createTextSpan(context, displayVerse.substring(displayIdx), null),
      );
    }

    return spans;
  }

  /// Checks if the Tajweed rule has changed between two matches
  bool _hasRuleChanged(TajweedRuleMatch? next, TajweedRuleMatch? current) {
    if (next == current) return false;
    if (next == null || current == null) return next != current;

    return next.ruleEnglishName != current.ruleEnglishName ||
        next.isWarshSpecific != current.isWarshSpecific;
  }

  /// Creates a text span with optional Tajweed rule highlighting and interaction
  TextSpan _createTextSpan(
    BuildContext context,
    String text,
    TajweedRuleMatch? ruleMatch,
  ) {
    final color = ruleMatch != null
        ? TajweedColors.getColorForRule(
            ruleMatch.ruleEnglishName,
            ruleMatch.isWarshSpecific,
          )
        : TajweedColors.defaultColor;

    final baseStyle = TextStyle(
      color: color,
      fontSize: 32,
      height: 2.0,
      fontWeight: FontWeight.normal,
    );

    if (ruleMatch != null) {
      // Create interactive span with gesture detection
      return TextSpan(
        text: text,
        style: baseStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _showRuleTooltip(context, ruleMatch, widget.originalVerse);
          },
      );
    } else {
      // Regular span without interaction
      return TextSpan(text: text, style: baseStyle);
    }
  }

  /// Safely extracts substring with bounds checking
  String _safeSubstring(String text, int start, int end) {
    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(safeStart, text.length);
    return text.substring(safeStart, safeEnd);
  }

  void _showRuleTooltip(
    BuildContext context,
    TajweedRuleMatch ruleMatch,
    String originalVerse,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ruleMatch.ruleArabicName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (ruleMatch.ruleArabicName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        ruleMatch.ruleArabicName,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'الوصف',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ruleMatch.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.blue.shade900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.list_alt,
                              color: Colors.grey.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تفاصيل الحكم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Extract the word where the rule applies
                        _buildInfoRow(
                          'االمقطع',
                          _extractWordFromVerse(
                            originalVerse,
                            ruleMatch.startIndex.toInt(),
                            ruleMatch.endIndex.toInt(),
                          ),
                          isArabic: true,
                        ),
                        _buildInfoRow(
                          'الحرف المستهدف',
                          ruleMatch.targetLetter,
                          isArabic: true,
                        ),
                        if (ruleMatch.followingLetter != null)
                          _buildInfoRow(
                            'الحرف التالي',
                            ruleMatch.followingLetter!,
                            isArabic: true,
                          ),
                        _buildInfoRow(
                          'الموضع',
                          '${ruleMatch.startIndex} - ${ruleMatch.endIndex}',
                        ),
                        if (ruleMatch.maddLength != null)
                          _buildInfoRow(
                            'طول المد',
                            '${ruleMatch.maddLength!.$1} - ${ruleMatch.maddLength!.$2} حرف',
                          ),
                      ],
                    ),
                  ),
                  if (ruleMatch.isWarshSpecific)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 18, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            'حكم خاص بورش',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  String _extractWordFromVerse(String verse, int startIndex, int endIndex) {
    if (verse.isEmpty ||
        startIndex < 0 ||
        endIndex > verse.length ||
        startIndex >= endIndex) {
      return '';
    }

    // Extract the substring containing the rule application
    String targetSubstring = verse.substring(startIndex, endIndex);

    // Find the boundaries of the word containing this substring
    int wordStart = startIndex;
    int wordEnd = endIndex;

    // Expand backwards to find the start of the word (stop at space or beginning)
    while (wordStart > 0 && !RegExp(r'\s').hasMatch(verse[wordStart - 1])) {
      wordStart--;
    }

    // Expand forwards to find the end of the word (stop at space or end)
    while (wordEnd < verse.length && !RegExp(r'\s').hasMatch(verse[wordEnd])) {
      wordEnd++;
    }

    // Extract the full word
    String word = verse.substring(wordStart, wordEnd);

    // Return the word containing the rule application
    return word.trim();
  }

  Widget _buildInfoRow(String label, String value, {bool isArabic = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: isArabic ? 16 : 14,
                fontWeight: isArabic ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the original ColoredTajweedText for backward compatibility if needed
class ColoredTajweedText extends StatelessWidget {
  final String originalVerse;
  final String displayVerse;
  final List<TajweedRuleMatch> matches;

  const ColoredTajweedText({
    super.key,
    required this.originalVerse,
    required this.displayVerse,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Text(
        displayVerse,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 32, height: 2.0),
      );
    }

    // Create a map to track which characters in original verse have rules applied
    final Map<int, Color> charColors = {};

    for (final match in matches) {
      final color = TajweedColors.getColorForRule(
        match.ruleEnglishName,
        match.isWarshSpecific,
      );

      // Use the indices which refer to the original verse
      final startIdx = match.startIndex.toInt();
      final endIdx = match.endIndex.toInt();

      // Mark all characters in this range with the rule color
      for (int i = startIdx; i < endIdx && i < originalVerse.length; i++) {
        charColors[i] = color;
      }
    }

    // Build text spans for the display verse (with ZWJ)
    // We need to map the colors from original verse positions to display verse
    final spans = <TextSpan>[];
    int originalIdx = 0;
    int displayIdx = 0;

    while (displayIdx < displayVerse.length &&
        originalIdx < originalVerse.length) {
      final currentColor = charColors[originalIdx];
      int spanStart = displayIdx;
      Color? spanColor = currentColor;

      // Find the extent of this color span
      while (displayIdx < displayVerse.length &&
          originalIdx < originalVerse.length) {
        final charAtDisplay = displayVerse[displayIdx];

        // Check if we've hit a ZWJ character (which doesn't exist in original)
        if (charAtDisplay == '\u200D') {
          displayIdx++;
          continue;
        }

        // Check if color changed
        final nextColor = charColors[originalIdx];
        if (nextColor != spanColor) {
          break;
        }

        displayIdx++;
        originalIdx++;
      }

      // Add the span
      if (displayIdx > spanStart) {
        spans.add(
          TextSpan(
            text: displayVerse.substring(spanStart, displayIdx),
            style: TextStyle(
              color: spanColor ?? TajweedColors.defaultColor,
              fontWeight: FontWeight.normal,
            ),
          ),
        );
      }
    }

    // Add any remaining display text
    if (displayIdx < displayVerse.length) {
      spans.add(
        TextSpan(
          text: displayVerse.substring(displayIdx),
          style: const TextStyle(
            color: TajweedColors.defaultColor,
            fontWeight: FontWeight.normal,
          ),
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(fontSize: 32, height: 2.0),
        children: spans,
      ),
    );
  }
}

class TajweedRuleCard extends StatelessWidget {
  final TajweedRuleMatch match;
  final int index;

  const TajweedRuleCard({super.key, required this.match, required this.index});

  Color _getRuleColor(bool isWarshSpecific) {
    return isWarshSpecific ? Colors.purple : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRuleColor(match.isWarshSpecific),
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          match.ruleEnglishName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          match.ruleArabicName,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'الحرف المستهدف',
                  match.targetLetter,
                  isArabic: true,
                ),
                if (match.followingLetter != null)
                  _buildInfoRow(
                    'الحرف التالي',
                    match.followingLetter!,
                    isArabic: true,
                  ),
                _buildInfoRow(
                  'الموضع',
                  '${match.startIndex} - ${match.endIndex}',
                ),
                _buildInfoRow('السياق', match.context, isArabic: true),
                if (match.maddLength != null)
                  _buildInfoRow(
                    'طول المد',
                    '${match.maddLength!.$1} - ${match.maddLength!.$2} حرف',
                  ),
                const Divider(height: 24),
                const Text(
                  'الوصف',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(match.description, style: const TextStyle(fontSize: 14)),
                if (match.isWarshSpecific) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'حكم خاص بورش',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isArabic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TajweedColors {
  static const Color defaultColor = Colors.black;

  static String _normalizeRuleKey(String ruleName) {
    return ruleName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static final tajweedColorMap = <String, Color>{
    // Noon Saakinah Rules - Izhar (Clarity)
    'al_izhar_al_halqi': Color(0xFF00BCD4),
    'al_izhar_al_mutlaq': Color(0xFF00BCD4),

    // Noon Saakinah Rules - Idgham (Assimilation)
    'idgham_with_ghunnah': Color(0xFF2196F3),
    'idgham_naqis_incomplete': Color(0xFF1976D2),
    'idgham_kamil_complete': Color(0xFF1565C0),
    'idgham_without_ghunnah': Color(0xFF0D47A1),

    // Noon Saakinah Rules - Iqlab (Conversion)
    'al_iqlab': Color(0xFFFF9800),

    // Noon Saakinah Rules - Ikhfaa (Concealment)
    'al_ikhfaa_al_haqiqi': Color(0xFFE91E63),
    'al_ikhfaa_al_shafawi': Color(0xFFC2185B),

    // Meem Saakinah Rules
    'al_idgham_al_shafawi': Color(0xFF42A5F5),
    'al_izhar_al_shafawi': Color(0xFF4DD0E1),

    // Definite Article (AL) Rules
    'al_izhar_al_qamari': Color(0xFF29B6F6),
    'al_idgham_al_shamsi': Color(0xFF1E88E5),

    // Madd (Elongation) Rules - Natural Madd
    'madd_tabeei': Color(0xFF4CAF50),

    // Madd Rules - Connected
    'madd_muttasil': Color(0xFF43A047),

    // Madd Rules - Separated
    'madd_munfasil': Color(0xFF388E3C),

    // Madd Rules - Badal
    'madd_badal': Color(0xFF2E7D32),

    // Madd Rules - Obligatory/Emphatic
    'madd_lazim': Color(0xFF1B5E20),

    // Madd Rules - Accidental
    'madd_arid': Color(0xFF558B2F),

    // Madd Rules - Soft
    'madd_lin': Color(0xFF689F38),

    // Special Rules - Silah (Soft connection)
    'madd_silah': Color(0xFF9C27B0),

    // Ra Rules - Thinness (Tarqeeq)
    'tarqeeq_ra': Color(0xFFFBC02D),

    // Ra Rules - Emphasis (Tafkhim)
    'tafkhim_ra': Color(0xFFF44336),
    'tafkhim_lafz_al_jalalah': Color(0xFFD32F2F),

    // Qalqalah (Shaking/Echo) Rules
    'qalqalah_kubra_major': Color(0xFFFF6F00),
    'qalqalah_sughra_minor': Color(0xFFE65100),

    // Waqf (Stop) Rules
    'waqf_jaiz': Color(0xFF9E9E9E),
    'waqf_awla': Color(0xFF757575),
    'wasl_awla': Color(0xFF616161),
    'waqf_muanaqah': Color(0xFF424242),
    'sakt': Color(0xFF212121),
  };

  static Color getColorForRule(String ruleEnglishName, bool isWarshSpecific) {
    final textColor =
        tajweedColorMap[_normalizeRuleKey(ruleEnglishName)] ?? defaultColor;
    return textColor;
  }
}

import 'package:flutter/material.dart';
import 'package:tajweed_rules/tajweed_rules.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const TajweedApp());
}

class TajweedApp extends StatelessWidget {
  const TajweedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tajweed Rules',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const TajweedHomePage(),
    );
  }
}

class TajweedHomePage extends StatefulWidget {
  const TajweedHomePage({super.key});

  @override
  State<TajweedHomePage> createState() => _TajweedHomePageState();
}

class _TajweedHomePageState extends State<TajweedHomePage> {
  final TextEditingController _verseController = TextEditingController();
  TajweedRulesProcessor? _processor;
  List<TajweedRuleMatch> _matches = [];
  RecitationStyleType _selectedStyle = RecitationStyleType.hafs;
  bool _isLoading = false;
  String? _version;
  int _currentPageIndex = 0;
  String _originalVerse = '';
  String _displayVerse = '';

  @override
  void initState() {
    super.initState();
    _initializeProcessor();
    _loadVersion();
  }

  Future<void> _initializeProcessor() async {
    try {
      _processor = TajweedRules.tajweedRulesInit();
      setState(() {});
    } catch (e) {
      _showError('Failed to initialize processor: $e');
    }
  }

  Future<void> _loadVersion() async {
    try {
      final version = TajweedRules.getVersion();
      setState(() {
        _version = version;
      });
    } catch (e) {
      print('Failed to load version: $e');
    }
  }

  Future<void> _processVerse() async {
    if (_verseController.text.isEmpty) {
      _showError('Please enter a verse');
      return;
    }

    if (_processor == null) {
      _showError('Processor not initialized');
      return;
    }

    setState(() {
      _isLoading = true;
      _matches = [];
    });

    try {
      final originalVerse = _verseController.text;

      // First process the verse to get matches (based on original verse)
      final matches = TajweedRules.processVerse(
        verse: originalVerse,
        style: _selectedStyle,
        processorWarsh: _processor!,
      );

      // Then apply ZWJ for display rendering
      final zwjVerse = TajweedRules.processVerseWithZwj(
        verse: originalVerse,
        processor: _processor!,
      );

      setState(() {
        _originalVerse = originalVerse;
        _displayVerse = zwjVerse;
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to process verse: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _verseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tajweed Rules Analyzer'),
        actions: [
          if (_version != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('v$_version', style: const TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
      body: _currentPageIndex == 0
          ? _buildAnalyzerPage()
          : _buildColoredTextPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Rules List'),
          NavigationDestination(
            icon: Icon(Icons.palette),
            label: 'Colored Text',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzerPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Quranic Verse',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _verseController,
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 24),
                    decoration: const InputDecoration(
                      hintText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      hintTextDirection: TextDirection.rtl,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recitation Style',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<RecitationStyleType>(
                    segments: const [
                      ButtonSegment(
                        value: RecitationStyleType.hafs,
                        label: Text('Hafs'),
                      ),
                      ButtonSegment(
                        value: RecitationStyleType.warsh,
                        label: Text('Warsh'),
                      ),
                      ButtonSegment(
                        value: RecitationStyleType.both,
                        label: Text('Both'),
                      ),
                    ],
                    selected: {_selectedStyle},
                    onSelectionChanged: (Set<RecitationStyleType> selected) {
                      setState(() {
                        _selectedStyle = selected.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _processVerse,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(_isLoading ? 'Processing...' : 'Analyze'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_matches.isNotEmpty) ...[
            Text(
              'Found ${_matches.length} Tajweed Rule${_matches.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return TajweedRuleCard(match: match, index: index);
              },
            ),
          ] else if (!_isLoading && _verseController.text.isNotEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No Tajweed rules found in this verse',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColoredTextPage() {
    if (_verseController.text.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.text_fields, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Enter a verse in the Rules List tab\nto see colored Tajweed text',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ColoredTajweedText(
                originalVerse: _originalVerse,
                displayVerse: _displayVerse,
                matches: _matches,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Legend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...TajweedColors.tajweedColorMap.entries.map((entry) {
                    return _buildLegendItem(entry.value, entry.key);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class TajweedColors {
  static const Color ghunna = Color(0xFFAACCFF);
  static const Color ikhfa = Color(0xFF9BE89B);
  static const Color idghaam = Color(0xFFFFAAAA);
  static const Color iqlab = Color(0xFFFFCC99);
  static const Color qalqalah = Color(0xFFDD99FF);
  static const Color madd = Color(0xFFFF9999);
  static const Color laamShamsiyah = Color(0xFFFFEE99);
  static const Color warshSpecific = Color(0xFFDDA0DD);
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
                  'Target Letter',
                  match.targetLetter,
                  isArabic: true,
                ),
                if (match.followingLetter != null)
                  _buildInfoRow(
                    'Following Letter',
                    match.followingLetter!,
                    isArabic: true,
                  ),
                _buildInfoRow(
                  'Position',
                  '${match.startIndex} - ${match.endIndex}',
                ),
                _buildInfoRow('Context', match.context, isArabic: true),
                if (match.maddLength != null)
                  _buildInfoRow(
                    'Madd Length',
                    '${match.maddLength!.$1} - ${match.maddLength!.$2} counts',
                  ),
                const Divider(height: 24),
                const Text(
                  'Description',
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
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'Warsh-Specific Rule',
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
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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

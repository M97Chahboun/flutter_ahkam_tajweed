import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tajweed_rules/tajweed_rules.dart';
import 'package:tajweed_rules/tajweed_rules.dart' as tajweed_lib;
import 'package:url_launcher/url_launcher.dart';
import 'services/issue_reporting_service.dart';
import 'services/quranpedia_service.dart';

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
      title: 'محلل وتلوين أحكام التجويد',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F766E),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
        fontFamily: GoogleFonts.cairo().fontFamily,
      ),
      home: const TajweedHomePage(),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
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
  bool _isFetchingAyah = false;
  String? _version;
  int _currentPageIndex = 0;
  String _originalVerse = '';
  double _quranFontSize = 32.0;

  // Quranpedia selection state
  List<QuranSurah> _surahs = [];
  int _selectedSurahId = 1;
  int _selectedAyahNumber = 1;

  static const String contactPhone = '+212708569068';
  static const String contactPhoneRaw = '212708569068';

  @override
  void initState() {
    super.initState();
    _initializeProcessor();
    _loadVersion();
    _loadSurahs();
    _verseController.text = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
  }

  Future<void> _initializeProcessor() async {
    try {
      _processor = tajweed_lib.tajweedRulesInit();
      setState(() {});
      _processVerse();
    } catch (e) {
      _showError('فشل تهيئة المعالج: $e');
    }
  }

  Future<void> _loadVersion() async {
    try {
      final version = tajweed_lib.getVersion();
      setState(() {
        _version = version;
      });
    } catch (_) {}
  }

  Future<void> _loadSurahs() async {
    try {
      final list = await QuranpediaService.getSurahs();
      setState(() {
        _surahs = list;
      });
    } catch (_) {}
  }

  QuranSurah get _currentSurah {
    if (_surahs.isEmpty) {
      return const QuranSurah(id: 1, name: 'سورة الفاتحة', numberOfAyahs: 7);
    }
    return _surahs.firstWhere(
      (s) => s.id == _selectedSurahId,
      orElse: () => _surahs.first,
    );
  }

  String get _styleName {
    switch (_selectedStyle) {
      case RecitationStyleType.hafs:
        return 'حفص عن عاصم';
      case RecitationStyleType.warsh:
        return 'ورش عن نافع';
      case RecitationStyleType.both:
        return 'حفص وورش (كلاهما)';
    }
  }

  Future<void> _openWhatsAppFeedback({String? specificRuleName}) async {
    final surahName = _currentSurah.name;
    final currentText = _verseController.text.trim();

    String message = '''السلام عليكم ورحمة الله وبركاته،
بخصوص مشروع أحكام التجويد (Ahkam Tajweed):

📖 السورة: $surahName (الآية: $_selectedAyahNumber)
📜 الرواية: $_styleName
📝 النص القرآني:
"$currentText"
''';

    if (specificRuleName != null && specificRuleName.isNotEmpty) {
      message += '\n⚠️ ملاحظة بخصوص حكم: $specificRuleName\nالملاحظة: ';
    } else {
      message += '\n⚠️ ملاحظتي بخصوص الأحكام المطبقة في هذه الآية:\n';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$contactPhoneRaw?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      _showError('تعذر فتح تطبيق واتساب. يمكنك التواصل مباشرة على $contactPhone');
    }
  }

  void _showFeedbackDialog({String? specificRuleName, String? specificRuleEnglishName}) {
    final noteController = TextEditingController();
    final contactController = TextEditingController();
    TajweedIssueType selectedType = TajweedIssueType.incorrectRule;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.bug_report, color: Color(0xFF0F766E), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'الإبلاغ عن ملاحظة أو خطأ تجويدي',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• السورة: ${_currentSurah.name} (الآية: $_selectedAyahNumber)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text('• الرواية: $_styleName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (specificRuleName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '• الحكم المعني: $specificRuleName',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'نوع الملاحظة:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TajweedIssueType.values.map((type) {
                          final isSelected = selectedType == type;
                          return ChoiceChip(
                            label: Text(
                              type.arabicLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F766E),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedType = type;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'تفاصيل الملاحظة والنتيجة المتوقعة *',
                          hintText: 'مثال: في كلمة (كَمِثْلِهِ) يجب استخراج حكم كذا لأن...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contactController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم أو وسيلة التواصل (اختياري)',
                          hintText: 'اسمك أو رقمك/بريدك للمتابعة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final report = TajweedIssueReport(
                            surahNumber: _selectedSurahId,
                            surahName: _currentSurah.name,
                            ayahNumber: _selectedAyahNumber,
                            riwaya: _selectedStyle,
                            verseText: _verseController.text.trim(),
                            ruleArabicName: specificRuleName,
                            ruleEnglishName: specificRuleEnglishName,
                            issueType: selectedType,
                            description: noteController.text.trim(),
                            reporterContact: contactController.text.trim(),
                          );
                          await IssueReportingService.copyReportToClipboard(report);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('تم نسخ تقرير الملاحظة بصيغة Markdown بنجاح!'),
                                  ],
                                ),
                                backgroundColor: Color(0xFF0F766E),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('نسخ'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final noteText = noteController.text.trim();
                          if (noteText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('الرجاء كتابة وصف الملاحظة قبل الإرسال'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final report = TajweedIssueReport(
                            surahNumber: _selectedSurahId,
                            surahName: _currentSurah.name,
                            ayahNumber: _selectedAyahNumber,
                            riwaya: _selectedStyle,
                            verseText: _verseController.text.trim(),
                            ruleArabicName: specificRuleName,
                            ruleEnglishName: specificRuleEnglishName,
                            issueType: selectedType,
                            description: noteText,
                            reporterContact: contactController.text.trim(),
                          );

                          final result = await IssueReportingService.submitViaBackendProxy(report);

                          if (context.mounted) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            Navigator.of(context).pop();

                            if (result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text('تم إرسال الملاحظة بنجاح وإنشاء التذكرة على GitHub!'),
                                      ),
                                    ],
                                  ),
                                  action: result.issueUrl != null
                                      ? SnackBarAction(
                                          label: 'عرض التذكرة',
                                          textColor: Colors.amberAccent,
                                          onPressed: () {
                                            launchUrl(Uri.parse(result.issueUrl!), mode: LaunchMode.externalApplication);
                                          },
                                        )
                                      : null,
                                  backgroundColor: const Color(0xFF0F766E),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            } else {
                              // If proxy failed, offer direct fallback
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تعذر الإرسال التلقائي: ${result.errorMessage ?? ""}'),
                                  action: SnackBarAction(
                                    label: 'فتح GitHub يدوياً',
                                    textColor: Colors.white,
                                    onPressed: () => IssueReportingService.openGitHubIssue(report),
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 6),
                                ),
                              );
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    isSubmitting ? 'جاري الإرسال...' : 'إرسال الملاحظة مباشرة',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchAyahFromQuranpedia({
    int? surahId,
    int? ayahNumber,
    RecitationStyleType? style,
  }) async {
    final sId = surahId ?? _selectedSurahId;
    final aNum = ayahNumber ?? _selectedAyahNumber;
    final st = style ?? _selectedStyle;

    setState(() {
      _isFetchingAyah = true;
    });

    try {
      final result = await QuranpediaService.getAyah(
        surahNumber: sId,
        ayahNumber: aNum,
        style: st,
      );

      setState(() {
        _selectedSurahId = sId;
        _selectedAyahNumber = aNum;
        _verseController.text = result.text;
        _isFetchingAyah = false;
      });

      _processVerse();
    } catch (e) {
      setState(() {
        _isFetchingAyah = false;
      });
      _showError('فشل جلب الآية من Quranpedia: $e');
    }
  }

  Future<void> _nextAyah() async {
    final maxAyahs = _currentSurah.numberOfAyahs;
    if (_selectedAyahNumber < maxAyahs) {
      await _fetchAyahFromQuranpedia(
        surahId: _selectedSurahId,
        ayahNumber: _selectedAyahNumber + 1,
      );
    } else if (_selectedSurahId < 114) {
      await _fetchAyahFromQuranpedia(
        surahId: _selectedSurahId + 1,
        ayahNumber: 1,
      );
    }
  }

  Future<void> _previousAyah() async {
    if (_selectedAyahNumber > 1) {
      await _fetchAyahFromQuranpedia(
        surahId: _selectedSurahId,
        ayahNumber: _selectedAyahNumber - 1,
      );
    } else if (_selectedSurahId > 1) {
      final prevSurah = _surahs.firstWhere(
        (s) => s.id == _selectedSurahId - 1,
        orElse: () => const QuranSurah(id: 1, name: '', numberOfAyahs: 1),
      );
      await _fetchAyahFromQuranpedia(
        surahId: _selectedSurahId - 1,
        ayahNumber: prevSurah.numberOfAyahs,
      );
    }
  }

  Future<void> _processVerse() async {
    if (_verseController.text.trim().isEmpty) {
      _showError('الرجاء إدخال آية');
      return;
    }

    if (_processor == null) {
      _showError('لم يتم تهيئة المعالج بعد');
      return;
    }

    setState(() {
      _isLoading = true;
      _matches = [];
    });

    try {
      final originalVerse = _verseController.text.trim();

      final matches = tajweed_lib.processVerse(
        verse: originalVerse,
        style: _selectedStyle,
        processorWarsh: _processor!,
      );

      setState(() {
        _originalVerse = originalVerse;
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('فشل معالجة الآية: $e');
    }
  }

  void _copyVerseToClipboard() {
    if (_verseController.text.trim().isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _verseController.text.trim()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('تم نسخ النص القرآني بنجاح'),
            ],
          ),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
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
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: Color(0xFF0F766E), size: 26),
            SizedBox(width: 10),
            Text(
              'محلل أحكام التجويد',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'إبلاغ عن ملاحظة عبر واتساب',
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFF1E7E34),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showFeedbackDialog(),
              icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
              label: const Text(
                'إبلاغ عن ملاحظة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_sync, size: 16, color: Color(0xFF0F766E)),
                const SizedBox(width: 4),
                const Text(
                  'Quranpedia API',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F766E),
                  ),
                ),
                if (_version != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'v$_version',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ],
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
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'تحليل الآية والأحكام',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'النص الملون ومفتاح الألوان',
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
          _buildQuranpediaSelectorCard(),
          const SizedBox(height: 16),
          _buildInputAndControlsCard(),
          const SizedBox(height: 20),
          if (_matches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تم استخراج ${_matches.length} أحكام تجويدية',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      _currentPageIndex = 1;
                    });
                  },
                  icon: const Icon(Icons.palette, size: 18),
                  label: const Text('عرض النص الملون'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return TajweedRuleCard(
                  match: match,
                  index: index,
                  onReport: (m) => _showFeedbackDialog(specificRuleName: m.ruleArabicName),
                );
              },
            ),
          ] else if (!_isLoading && _verseController.text.isNotEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'لم يتم العثور على أي أحكام تجويدية في هذا النص',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildFeedbackContactBanner(),
        ],
      ),
    );
  }

  Widget _buildQuranpediaSelectorCard() {
    final currentSurah = _currentSurah;
    final maxAyahs = currentSurah.numberOfAyahs;

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories, color: Color(0xFF0F766E), size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'جلب الآيات من المصحف (Quranpedia API)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isFetchingAyah)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 500;
                return isCompact
                    ? Column(
                        children: [
                          _buildSurahDropdown(),
                          const SizedBox(height: 10),
                          _buildAyahSelector(maxAyahs),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: _buildSurahDropdown()),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _buildAyahSelector(maxAyahs)),
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isFetchingAyah
                        ? null
                        : () => _fetchAyahFromQuranpedia(),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(
                      _selectedStyle == RecitationStyleType.warsh
                          ? 'جلب برواية ورش'
                          : 'جلب برواية حفص',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'الآية السابقة',
                  onPressed: _isFetchingAyah ? null : _previousAyah,
                  icon: const Icon(Icons.chevron_right),
                ),
                IconButton.outlined(
                  tooltip: 'الآية التالية',
                  onPressed: _isFetchingAyah ? null : _nextAyah,
                  icon: const Icon(Icons.chevron_left),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('نماذج سريعة: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  _buildPresetChip('الفاتحة 1', 1, 1),
                  _buildPresetChip('الفاتحة 7', 1, 7),
                  _buildPresetChip('البقرة 1', 2, 1),
                  _buildPresetChip('آية الكرسي', 2, 255),
                  _buildPresetChip('الإخلاص 1', 112, 1),
                  _buildPresetChip('الناس 1', 114, 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahDropdown() {
    return DropdownButtonFormField<int>(
      key: ValueKey('surah_$_selectedSurahId'),
      initialValue: _selectedSurahId,
      decoration: InputDecoration(
        labelText: 'السورة',
        prefixIcon: const Icon(Icons.format_list_numbered),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: _surahs.map((surah) {
        return DropdownMenuItem<int>(
          value: surah.id,
          child: Text(
            '${surah.id}. ${surah.name} (${surah.numberOfAyahs} آية)',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (newSurahId) {
        if (newSurahId != null) {
          setState(() {
            _selectedSurahId = newSurahId;
            _selectedAyahNumber = 1;
          });
          _fetchAyahFromQuranpedia(surahId: newSurahId, ayahNumber: 1);
        }
      },
    );
  }

  Widget _buildAyahSelector(int maxAyahs) {
    final List<int> ayahs = List.generate(maxAyahs, (i) => i + 1);
    final safeAyahNumber = _selectedAyahNumber <= maxAyahs ? _selectedAyahNumber : 1;

    return DropdownButtonFormField<int>(
      key: ValueKey('ayah_${_selectedSurahId}_$safeAyahNumber'),
      initialValue: safeAyahNumber,
      decoration: InputDecoration(
        labelText: 'رقم الآية',
        prefixIcon: const Icon(Icons.tag),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: ayahs.map((ayah) {
        return DropdownMenuItem<int>(
          value: ayah,
          child: Text('الآية $ayah'),
        );
      }).toList(),
      onChanged: (newAyah) {
        if (newAyah != null) {
          setState(() {
            _selectedAyahNumber = newAyah;
          });
          _fetchAyahFromQuranpedia(ayahNumber: newAyah);
        }
      },
    );
  }

  Widget _buildPresetChip(String title, int surahId, int ayahNumber) {
    final isSelected = _selectedSurahId == surahId && _selectedAyahNumber == ayahNumber;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(title, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {
          _fetchAyahFromQuranpedia(surahId: surahId, ayahNumber: ayahNumber);
        },
      ),
    );
  }

  Widget _buildInputAndControlsCard() {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'النص القرآني المراد تحليله',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'نسخ النص',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyVerseToClipboard,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _verseController,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 24,
                height: 1.8,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل نص الآية أو اختر من الأعلى...',
                hintTextDirection: TextDirection.rtl,
                hintStyle: GoogleFonts.amiri(fontSize: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  tooltip: 'مسح النص',
                  icon: const Icon(Icons.clear),
                  onPressed: () => _verseController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'رواية وأسلوب القراءة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<RecitationStyleType>(
              segments: const [
                ButtonSegment(
                  value: RecitationStyleType.hafs,
                  label: Text('حفص عن عاصم'),
                  icon: Icon(Icons.menu_book),
                ),
                ButtonSegment(
                  value: RecitationStyleType.warsh,
                  label: Text('ورش عن نافع'),
                  icon: Icon(Icons.menu_book_outlined),
                ),
                ButtonSegment(
                  value: RecitationStyleType.both,
                  label: Text('كلاهما'),
                  icon: Icon(Icons.compare_arrows),
                ),
              ],
              selected: {_selectedStyle},
              onSelectionChanged: (Set<RecitationStyleType> selected) {
                final newStyle = selected.first;
                setState(() {
                  _selectedStyle = newStyle;
                });
                if (newStyle == RecitationStyleType.hafs || newStyle == RecitationStyleType.warsh) {
                  _fetchAyahFromQuranpedia(style: newStyle);
                } else {
                  _processVerse();
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
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
                    : const Icon(Icons.analytics_outlined),
                label: Text(
                  _isLoading ? 'جاري استخراج الأحكام...' : 'تحليل أحكام التجويد',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredTextPage() {
    if (_verseController.text.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.text_fields, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'الرجاء اختيار أو إدخال آية لتلوين أحكام التجويد',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, ({TajweedRuleMatch match, int count})> activeRules = {};
    for (final match in _matches) {
      final key = match.ruleEnglishName;
      if (activeRules.containsKey(key)) {
        activeRules[key] = (
          match: match,
          count: activeRules[key]!.count + 1,
        );
      } else {
        activeRules[key] = (
          match: match,
          count: 1,
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_currentSurah.name} : الآية $_selectedAyahNumber ($_styleName)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'تصغير الخط',
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () {
                              if (_quranFontSize > 22) {
                                setState(() {
                                  _quranFontSize -= 3;
                                });
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'تكبير الخط',
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () {
                              if (_quranFontSize < 50) {
                                setState(() {
                                  _quranFontSize += 3;
                                });
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'نسخ النص',
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: _copyVerseToClipboard,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  InteractiveTajweedText(
                    originalVerse: _originalVerse,
                    style: _selectedStyle,
                    fontSize: _quranFontSize,
                    lineHeight: 2.2,
                    fontFamily: GoogleFonts.amiri().fontFamily ?? 'Amiri',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '💡 انقر على الحرف الملون لعرض تفاصيل الحكم التجويدي',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined, color: Color(0xFF0F766E)),
                      const SizedBox(width: 8),
                      Text(
                        'مفتاح الأحكام النشطة في هذه الآية (${activeRules.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (activeRules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'لا توجد أحكام تجويدية ملونة في هذا النص',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...activeRules.values.map((item) {
                      final match = item.match;
                      return _buildLegendItem(
                        color: TajweedColors.getColorForRule(
                          match.ruleEnglishName,
                          match.isWarshSpecific,
                          false,
                        ),
                        arabicTitle: match.ruleArabicName,
                        englishTitle: match.ruleEnglishName,
                        count: item.count,
                        isWarshSpecific: match.isWarshSpecific,
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeedbackContactBanner(),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String arabicTitle,
    required String englishTitle,
    required int count,
    required bool isWarshSpecific,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arabicTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (englishTitle.isNotEmpty)
                    Text(
                      englishTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),
            if (isWarshSpecific)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'خاص بورش',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count == 1 ? 'موضع واحد' : '$count مواضع',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                side: BorderSide(color: Colors.orange.shade300),
                foregroundColor: Colors.orange.shade900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.report_problem_outlined, size: 14, color: Colors.orange),
              label: const Text('إبلاغ عن خطأ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _showFeedbackDialog(specificRuleName: arabicTitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackContactBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F766E).withValues(alpha: 0.08),
            const Color(0xFF24292F).withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report_outlined, color: Color(0xFF0F766E), size: 22),
              SizedBox(width: 8),
              Text(
                'مركز الإبلاغ وتتبع الملاحظات (GitHub Issues)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'مشروع أحكام التجويد مفتوح المصدر ومستمر في التطوير. لضمان عدم ضياع أي ملاحظة وتتبعها كمرجع موحد، يمكنكم فتح تذكرة مباشرة على GitHub مع تعبئة التفاصيل والآية والرواية آلياً.',
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF24292F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showFeedbackDialog(),
                icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                label: const Text(
                  'فتح تذكرة على GitHub Issues',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openWhatsAppFeedback(),
                icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                label: const Text('تواصل عبر واتساب'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

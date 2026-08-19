import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tajweed_rules/tajweed_rules.dart';

class QuranSurah {
  final int id;
  final String name;
  final int numberOfAyahs;

  const QuranSurah({
    required this.id,
    required this.name,
    required this.numberOfAyahs,
  });

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    return QuranSurah(
      id: json['id'] as int? ?? 1,
      name: (json['name'] as String? ?? 'سورة ${json['id']}').trim(),
      numberOfAyahs: json['number_of_ayahs'] as int? ?? 7,
    );
  }
}

class QuranAyahResult {
  final int surahNumber;
  final int ayahNumber;
  final String text;
  final String? marker;
  final int mushafId;

  const QuranAyahResult({
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    this.marker,
    required this.mushafId,
  });
}

class QuranpediaService {
  static const String baseUrl = 'https://api.quranpedia.net/v1';

  // Mushaf IDs in Quranpedia
  static const int hafsMushafId = 1;  // مصحف حفص
  static const int warshMushafId = 4; // مصحف ورش

  static int getMushafIdForStyle(RecitationStyleType style) {
    switch (style) {
      case RecitationStyleType.warsh:
        return warshMushafId;
      case RecitationStyleType.hafs:
      case RecitationStyleType.both:
        return hafsMushafId;
    }
  }

  static List<QuranSurah>? _cachedSurahs;

  /// Fetches the list of all 114 Surahs from Quranpedia with local fallback
  static Future<List<QuranSurah>> getSurahs() async {
    if (_cachedSurahs != null && _cachedSurahs!.isNotEmpty) {
      return _cachedSurahs!;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/surahs'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final surahs = data.map((item) => QuranSurah.fromJson(item as Map<String, dynamic>)).toList();
        if (surahs.isNotEmpty) {
          _cachedSurahs = surahs;
          return surahs;
        }
      }
    } catch (e) {
      // Return fallback if network fails
    }

    _cachedSurahs = _fallbackSurahs;
    return _fallbackSurahs;
  }

  /// Fetches an ayah text for a given surah, ayah, and recitation style (Riwaya)
  static Future<QuranAyahResult> getAyah({
    required int surahNumber,
    required int ayahNumber,
    required RecitationStyleType style,
  }) async {
    final mushafId = getMushafIdForStyle(style);
    final url = '$baseUrl/mushafs/$mushafId/$surahNumber/$ayahNumber';

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      String rawText = (data['text'] as String? ?? '').trim();

      // Clean leading Unicode BOM or zero-width spaces
      rawText = rawText.replaceAll(RegExp(r'^[\uFEFF\u200B\u200C\u200D]+'), '').trim();

      return QuranAyahResult(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        text: rawText,
        marker: data['marker'] as String?,
        mushafId: mushafId,
      );
    } else {
      throw Exception('فشل جلب الآية من خادم Quranpedia (${response.statusCode})');
    }
  }

  // Fallback 114 Surahs
  static final List<QuranSurah> _fallbackSurahs = [
    const QuranSurah(id: 1, name: 'سورة الفاتحة', numberOfAyahs: 7),
    const QuranSurah(id: 2, name: 'سورة البقرة', numberOfAyahs: 286),
    const QuranSurah(id: 3, name: 'سورة آل عمران', numberOfAyahs: 200),
    const QuranSurah(id: 4, name: 'سورة النساء', numberOfAyahs: 176),
    const QuranSurah(id: 5, name: 'سورة المائدة', numberOfAyahs: 120),
    const QuranSurah(id: 6, name: 'سورة الأنعام', numberOfAyahs: 165),
    const QuranSurah(id: 7, name: 'سورة الأعراف', numberOfAyahs: 206),
    const QuranSurah(id: 8, name: 'سورة الأنفال', numberOfAyahs: 75),
    const QuranSurah(id: 9, name: 'سورة التوبة', numberOfAyahs: 129),
    const QuranSurah(id: 10, name: 'سورة يونس', numberOfAyahs: 109),
    const QuranSurah(id: 11, name: 'سورة هود', numberOfAyahs: 123),
    const QuranSurah(id: 12, name: 'سورة يوسف', numberOfAyahs: 111),
    const QuranSurah(id: 13, name: 'سورة الرعد', numberOfAyahs: 43),
    const QuranSurah(id: 14, name: 'سورة إبراهيم', numberOfAyahs: 52),
    const QuranSurah(id: 15, name: 'سورة الحجر', numberOfAyahs: 99),
    const QuranSurah(id: 16, name: 'سورة النحل', numberOfAyahs: 128),
    const QuranSurah(id: 17, name: 'سورة الإسراء', numberOfAyahs: 111),
    const QuranSurah(id: 18, name: 'سورة الكهف', numberOfAyahs: 110),
    const QuranSurah(id: 19, name: 'سورة مريم', numberOfAyahs: 98),
    const QuranSurah(id: 20, name: 'سورة طه', numberOfAyahs: 135),
    const QuranSurah(id: 21, name: 'سورة الأنبياء', numberOfAyahs: 112),
    const QuranSurah(id: 22, name: 'سورة الحج', numberOfAyahs: 78),
    const QuranSurah(id: 23, name: 'سورة المؤمنون', numberOfAyahs: 118),
    const QuranSurah(id: 24, name: 'سورة النور', numberOfAyahs: 64),
    const QuranSurah(id: 25, name: 'سورة الفرقان', numberOfAyahs: 77),
    const QuranSurah(id: 26, name: 'سورة الشعراء', numberOfAyahs: 227),
    const QuranSurah(id: 27, name: 'سورة النمل', numberOfAyahs: 93),
    const QuranSurah(id: 28, name: 'سورة القصص', numberOfAyahs: 88),
    const QuranSurah(id: 29, name: 'سورة العنكبوت', numberOfAyahs: 69),
    const QuranSurah(id: 30, name: 'سورة الروم', numberOfAyahs: 60),
    const QuranSurah(id: 31, name: 'سورة لقمان', numberOfAyahs: 34),
    const QuranSurah(id: 32, name: 'سورة السجدة', numberOfAyahs: 30),
    const QuranSurah(id: 33, name: 'سورة الأحزاب', numberOfAyahs: 73),
    const QuranSurah(id: 34, name: 'سورة سبأ', numberOfAyahs: 54),
    const QuranSurah(id: 35, name: 'سورة فاطر', numberOfAyahs: 45),
    const QuranSurah(id: 36, name: 'سورة يس', numberOfAyahs: 83),
    const QuranSurah(id: 37, name: 'سورة الصافات', numberOfAyahs: 182),
    const QuranSurah(id: 38, name: 'سورة ص', numberOfAyahs: 88),
    const QuranSurah(id: 39, name: 'سورة الزمر', numberOfAyahs: 75),
    const QuranSurah(id: 40, name: 'سورة غافر', numberOfAyahs: 85),
    const QuranSurah(id: 41, name: 'سورة فصلت', numberOfAyahs: 54),
    const QuranSurah(id: 42, name: 'سورة الشورى', numberOfAyahs: 53),
    const QuranSurah(id: 43, name: 'سورة الزخرف', numberOfAyahs: 89),
    const QuranSurah(id: 44, name: 'سورة الدخان', numberOfAyahs: 59),
    const QuranSurah(id: 45, name: 'سورة الجاثية', numberOfAyahs: 37),
    const QuranSurah(id: 46, name: 'سورة الأحقاف', numberOfAyahs: 35),
    const QuranSurah(id: 47, name: 'سورة محمد', numberOfAyahs: 38),
    const QuranSurah(id: 48, name: 'سورة الفتح', numberOfAyahs: 29),
    const QuranSurah(id: 49, name: 'سورة الحجرات', numberOfAyahs: 18),
    const QuranSurah(id: 50, name: 'سورة ق', numberOfAyahs: 45),
    const QuranSurah(id: 51, name: 'سورة الذاريات', numberOfAyahs: 60),
    const QuranSurah(id: 52, name: 'سورة الطور', numberOfAyahs: 49),
    const QuranSurah(id: 53, name: 'سورة النجم', numberOfAyahs: 62),
    const QuranSurah(id: 54, name: 'سورة القمر', numberOfAyahs: 55),
    const QuranSurah(id: 55, name: 'سورة الرحمن', numberOfAyahs: 78),
    const QuranSurah(id: 56, name: 'سورة الواقعة', numberOfAyahs: 96),
    const QuranSurah(id: 57, name: 'سورة الحديد', numberOfAyahs: 29),
    const QuranSurah(id: 58, name: 'سورة المجادلة', numberOfAyahs: 22),
    const QuranSurah(id: 59, name: 'سورة الحشر', numberOfAyahs: 24),
    const QuranSurah(id: 60, name: 'سورة الممتحنة', numberOfAyahs: 13),
    const QuranSurah(id: 61, name: 'سورة الصف', numberOfAyahs: 14),
    const QuranSurah(id: 62, name: 'سورة الجمعة', numberOfAyahs: 11),
    const QuranSurah(id: 63, name: 'سورة المنافقون', numberOfAyahs: 11),
    const QuranSurah(id: 64, name: 'سورة التغابن', numberOfAyahs: 18),
    const QuranSurah(id: 65, name: 'سورة الطلاق', numberOfAyahs: 12),
    const QuranSurah(id: 66, name: 'سورة التحريم', numberOfAyahs: 12),
    const QuranSurah(id: 67, name: 'سورة الملك', numberOfAyahs: 30),
    const QuranSurah(id: 68, name: 'سورة القلم', numberOfAyahs: 52),
    const QuranSurah(id: 69, name: 'سورة الحاقة', numberOfAyahs: 52),
    const QuranSurah(id: 70, name: 'سورة المعارج', numberOfAyahs: 44),
    const QuranSurah(id: 71, name: 'سورة نوح', numberOfAyahs: 28),
    const QuranSurah(id: 72, name: 'سورة الجن', numberOfAyahs: 28),
    const QuranSurah(id: 73, name: 'سورة المزمل', numberOfAyahs: 20),
    const QuranSurah(id: 74, name: 'سورة المدثر', numberOfAyahs: 56),
    const QuranSurah(id: 75, name: 'سورة القيامة', numberOfAyahs: 40),
    const QuranSurah(id: 76, name: 'سورة الإنسان', numberOfAyahs: 31),
    const QuranSurah(id: 77, name: 'سورة المرسلات', numberOfAyahs: 50),
    const QuranSurah(id: 78, name: 'سورة النبأ', numberOfAyahs: 40),
    const QuranSurah(id: 79, name: 'سورة النازعات', numberOfAyahs: 46),
    const QuranSurah(id: 80, name: 'سورة عبس', numberOfAyahs: 42),
    const QuranSurah(id: 81, name: 'سورة التكوير', numberOfAyahs: 29),
    const QuranSurah(id: 82, name: 'سورة الانفطار', numberOfAyahs: 19),
    const QuranSurah(id: 83, name: 'سورة المطففين', numberOfAyahs: 36),
    const QuranSurah(id: 84, name: 'سورة الانشقاق', numberOfAyahs: 25),
    const QuranSurah(id: 85, name: 'سورة البروج', numberOfAyahs: 22),
    const QuranSurah(id: 86, name: 'سورة الطارق', numberOfAyahs: 17),
    const QuranSurah(id: 87, name: 'سورة الأعلى', numberOfAyahs: 19),
    const QuranSurah(id: 88, name: 'سورة الغاشية', numberOfAyahs: 26),
    const QuranSurah(id: 89, name: 'سورة الفجر', numberOfAyahs: 30),
    const QuranSurah(id: 90, name: 'سورة البلد', numberOfAyahs: 20),
    const QuranSurah(id: 91, name: 'سورة الشمس', numberOfAyahs: 15),
    const QuranSurah(id: 92, name: 'سورة الليل', numberOfAyahs: 21),
    const QuranSurah(id: 93, name: 'سورة الضحى', numberOfAyahs: 11),
    const QuranSurah(id: 94, name: 'سورة الشرح', numberOfAyahs: 8),
    const QuranSurah(id: 95, name: 'سورة التين', numberOfAyahs: 8),
    const QuranSurah(id: 96, name: 'سورة العلق', numberOfAyahs: 19),
    const QuranSurah(id: 97, name: 'سورة القدر', numberOfAyahs: 5),
    const QuranSurah(id: 98, name: 'سورة البينة', numberOfAyahs: 8),
    const QuranSurah(id: 99, name: 'سورة الزلزلة', numberOfAyahs: 8),
    const QuranSurah(id: 100, name: 'سورة العاديات', numberOfAyahs: 11),
    const QuranSurah(id: 101, name: 'سورة القارعة', numberOfAyahs: 11),
    const QuranSurah(id: 102, name: 'سورة التكاثر', numberOfAyahs: 8),
    const QuranSurah(id: 103, name: 'سورة العصر', numberOfAyahs: 3),
    const QuranSurah(id: 104, name: 'سورة الهمزة', numberOfAyahs: 9),
    const QuranSurah(id: 105, name: 'سورة الفيل', numberOfAyahs: 5),
    const QuranSurah(id: 106, name: 'سورة قريش', numberOfAyahs: 4),
    const QuranSurah(id: 107, name: 'سورة الماعون', numberOfAyahs: 7),
    const QuranSurah(id: 108, name: 'سورة الكوثر', numberOfAyahs: 3),
    const QuranSurah(id: 109, name: 'سورة الكافرون', numberOfAyahs: 6),
    const QuranSurah(id: 110, name: 'سورة النصر', numberOfAyahs: 3),
    const QuranSurah(id: 111, name: 'سورة المسد', numberOfAyahs: 5),
    const QuranSurah(id: 112, name: 'سورة الإخلاص', numberOfAyahs: 4),
    const QuranSurah(id: 113, name: 'سورة الفلق', numberOfAyahs: 5),
    const QuranSurah(id: 114, name: 'سورة الناس', numberOfAyahs: 6),
  ];
}

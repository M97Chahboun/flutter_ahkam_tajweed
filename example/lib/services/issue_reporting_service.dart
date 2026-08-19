import 'package:flutter/services.dart';
import 'package:tajweed_rules/tajweed_rules.dart';
import 'package:url_launcher/url_launcher.dart';

/// Classification of reported issues
enum TajweedIssueType {
  missingRule('حكم مفقود لم يتم استخراجه', 'missing-rule'),
  incorrectRule('حكم خاطئ أو موضع غير دقيق', 'incorrect-rule'),
  riwayaException('استثناء خاص بالرواية (ورش / حفص)', 'riwaya-exception'),
  spellingOrVowel('تشكيل أو رسم قرآني غير دقيق', 'text-issue'),
  generalFeedback('ملاحظة أو اقتراح عام', 'enhancement');

  final String arabicLabel;
  final String labelTag;

  const TajweedIssueType(this.arabicLabel, this.labelTag);
}

/// Data model representing a structured Tajweed issue report
class TajweedIssueReport {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final RecitationStyleType riwaya;
  final String verseText;
  final String? ruleArabicName;
  final String? ruleEnglishName;
  final TajweedRuleType? ruleType;
  final String? contextWord;
  final TajweedIssueType issueType;
  final String description;
  final String? reporterContact;
  final DateTime createdAt;

  TajweedIssueReport({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.riwaya,
    required this.verseText,
    this.ruleArabicName,
    this.ruleEnglishName,
    this.ruleType,
    this.contextWord,
    required this.issueType,
    required this.description,
    this.reporterContact,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Formatted title for GitHub Issue
  String get githubIssueTitle {
    final rulePart = ruleArabicName != null && ruleArabicName!.isNotEmpty
        ? ' [$ruleArabicName]'
        : '';
    return '[${issueType.arabicLabel}] $surahName ($surahNumber:$ayahNumber)$rulePart';
  }

  /// Formatted Markdown body for GitHub Issue or Copying
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('### 📋 تفاصيل الملاحظة / الخطأ في حكم التجويد');
    buffer.writeln();
    buffer.writeln('| البند | التفاصيل |');
    buffer.writeln('| :--- | :--- |');
    buffer.writeln('| **نوع الملاحظة** | ${issueType.arabicLabel} |');
    buffer.writeln('| **السورة** | $surahName ($surahNumber) |');
    buffer.writeln('| **الآية** | $ayahNumber |');
    buffer.writeln('| **الرواية** | ${riwaya == RecitationStyleType.warsh ? "ورش عن نافع" : "حفص عن عاصم"} |');
    if (ruleArabicName != null && ruleArabicName!.isNotEmpty) {
      buffer.writeln('| **الحكم المعني** | $ruleArabicName (${ruleEnglishName ?? ""}) |');
    }
    if (ruleType != null) {
      buffer.writeln('| **تصنيف الحكم (Enum)** | `${ruleType!.name}` |');
    }
    if (contextWord != null && contextWord!.isNotEmpty) {
      buffer.writeln('| **الموضع / الكلمة** | `$contextWord` |');
    }
    if (reporterContact != null && reporterContact!.trim().isNotEmpty) {
      buffer.writeln('| **المبلغ** | ${reporterContact!.trim()} |');
    }
    buffer.writeln('| **التاريخ** | ${createdAt.toUtc().toIso8601String().substring(0, 19)} UTC |');
    buffer.writeln();
    buffer.writeln('#### 📖 النص القرآني:');
    buffer.writeln('> $verseText');
    buffer.writeln();
    buffer.writeln('#### 📝 وصف الملاحظة والنتيجة المتوقعة:');
    buffer.writeln(description.isNotEmpty ? description : '_لم يتم إدخال تفاصيل إضافية_');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('_تم الإبلاغ آلياً عبر تطبيق [محلل أحكام التجويد](https://ahkam-tajweed.web.app)_');
    return buffer.toString();
  }

  /// URL to open a new GitHub Issue pre-filled with this report
  Uri toGitHubIssueUri() {
    const repoUrl = 'https://github.com/M97Chahboun/flutter_ahkam_tajweed/issues/new';
    final labels = ['bug', 'tajweed-rule', issueType.labelTag].join(',');

    final params = {
      'title': githubIssueTitle,
      'body': toMarkdown(),
      'labels': labels,
    };

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return Uri.parse('$repoUrl?$query');
  }
}

/// Service to handle issue submission and centralized reporting
class IssueReportingService {
  /// Opens GitHub Issues with pre-filled Markdown report
  static Future<bool> openGitHubIssue(TajweedIssueReport report) async {
    final uri = report.toGitHubIssueUri();
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Copies formatted Markdown report to clipboard
  static Future<void> copyReportToClipboard(TajweedIssueReport report) async {
    await Clipboard.setData(ClipboardData(text: report.toMarkdown()));
  }
}

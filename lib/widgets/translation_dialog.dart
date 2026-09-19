import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translation_service.dart';

class TranslationDialog extends StatefulWidget {
  final String initialText;
  final String subjectName;

  const TranslationDialog({
    super.key,
    required this.initialText,
    required this.subjectName,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialText,
    required String subjectName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => TranslationDialog(
        initialText: initialText,
        subjectName: subjectName,
      ),
    );
  }

  @override
  State<TranslationDialog> createState() => _TranslationDialogState();
}

class _TranslationDialogState extends State<TranslationDialog> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  TranslationResult? _result;
  late String _sourceLang;
  String _targetLang = 'ar';

  @override
  void initState() {
    super.initState();
    _sourceLang =
        TranslationService.detectSourceLangForSubject(widget.subjectName);
    _controller = TextEditingController(text: widget.initialText.trim());
    if (_controller.text.isNotEmpty) {
      _doTranslate(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _doTranslate(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await TranslationService.instance.translate(
        text: text,
        subjectName: widget.subjectName,
        preferredSourceLang: _sourceLang,
        targetLang: _targetLang,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _switchLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
      if (_controller.text.isNotEmpty) {
        _doTranslate(_controller.text);
      }
    });
  }

  String _getLangName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'Anglais';
      case 'ar':
        return 'العربية';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF162032) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.g_translate_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Traduction / ترجمة',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Language selector pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getLangName(_sourceLang),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                      tooltip: 'Inverser les langues',
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      constraints: const BoxConstraints(),
                      onPressed: _switchLanguages,
                    ),
                    Text(
                      _getLangName(_targetLang),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Source text field
              TextField(
                controller: _controller,
                maxLines: 2,
                minLines: 1,
                textDirection: _sourceLang == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Mot ou phrase à traduire...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded, size: 20),
                    onPressed: () => _doTranslate(_controller.text),
                  ),
                ),
                onSubmitted: _doTranslate,
              ),
              const SizedBox(height: 14),

              // Translation Result Card
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                )
              else if (_result != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5132)
                        .withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0F5132).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _result!.source ==
                                          TranslationSource.online
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _result!.source == TranslationSource.online
                                    ? 'Traduction en ligne'
                                    : 'Lexique hors-ligne',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: _result!.translatedText),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Traduction copiée !'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copier',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _result!.translatedText,
                        textDirection: _targetLang == 'ar'
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translation_service.dart';

class CompactTranslationCard extends StatefulWidget {
  final String initialText;
  final String subjectName;
  final VoidCallback onClose;

  const CompactTranslationCard({
    super.key,
    required this.initialText,
    required this.subjectName,
    required this.onClose,
  });

  @override
  State<CompactTranslationCard> createState() => _CompactTranslationCardState();
}

class _CompactTranslationCardState extends State<CompactTranslationCard> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  TranslationResult? _result;
  late String _sourceLang;
  String _targetLang = 'ar';
  Timer? _debounceTimer;

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
  void didUpdateWidget(covariant CompactTranslationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText.trim().isNotEmpty) {
      _controller.text = widget.initialText.trim();
      _doTranslate(_controller.text);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String val) {
    _debounceTimer?.cancel();
    final clean = val.trim();
    if (clean.isEmpty) {
      setState(() {
        _result = null;
        _isLoading = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _doTranslate(clean);
    });
  }

  Future<void> _doTranslate(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await TranslationService.instance.translate(
        text: clean,
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

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 310,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162032) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Languages & Close
            Row(
              children: [
                const Icon(
                  Icons.g_translate_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getLangName(_sourceLang),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        InkWell(
                          onTap: _switchLanguages,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.swap_horiz_rounded, size: 16),
                          ),
                        ),
                        Text(
                          _getLangName(_targetLang),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Original phrase field
            TextField(
              controller: _controller,
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'Texte à traduire...',
                hintStyle: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded, size: 17),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _doTranslate(_controller.text),
                ),
              ),
              onChanged: _onTextChanged,
              onSubmitted: _doTranslate,
            ),

            const SizedBox(height: 8),

            // Translation result area
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              )
            else if (_result != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5132)
                      .withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(10),
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
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _result!.source ==
                                        TranslationSource.online
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _result!.source == TranslationSource.online
                                  ? 'En ligne'
                                  : 'Hors-ligne',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
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
                            padding: EdgeInsets.all(2),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 12),
                                SizedBox(width: 3),
                                Text(
                                  'Copier',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _result!.translatedText,
                      textDirection: _targetLang == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

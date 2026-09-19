import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/curriculum_service.dart';
import '../widgets/document_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _hasSearched = false;

  final List<String> _suggestions = [
    'Ondes mécaniques',
    'Limites et continuité',
    'Dérivation',
    'Lois de newton',
    'Information génétique',
    'Transformations chimiques',
    'Devoir 1',
    'Devoir 2',
    'Corrigé',
  ];

  void _onSearch(String query) {
    final curriculum = context.read<CurriculumService>();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    final res = curriculum.searchAllDocuments(query);
    setState(() {
      _results = res;
      _hasSearched = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher parmi 3 300+ cours, devoirs...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
            border: InputBorder.none,
          ),
          onChanged: _onSearch,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                _onSearch('');
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick suggestions chips when search is empty
          if (!_hasSearched) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Suggestions de recherche :',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((sug) {
                  return ActionChip(
                    label: Text(sug),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    onPressed: () {
                      _controller.text = sug;
                      _onSearch(sug);
                    },
                  );
                }).toList(),
              ),
            ),
          ],

          // Search Results Header
          if (_hasSearched)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                '${_results.length} résultat${_results.length > 1 ? 's' : ''} trouvé${_results.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),

          // Results List
          Expanded(
            child: _hasSearched && _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun document ne correspond à votre recherche',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final doc = item['document'] as DocumentItem;
                      final subj = item['subject'] as SubjectItem;
                      return DocumentCard(
                        document: doc,
                        subjectName: subj.nameFr,
                        accentColor: Color(subj.colorHex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

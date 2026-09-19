import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/favorites_service.dart';
import '../widgets/document_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favService = context.watch<FavoritesService>();
    final favorites = favService.allFavorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_outline_rounded,
                        size: 42,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Aucun favori enregistré',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Appuyez sur l\'étoile sur n\'importe quel cours ou exercice pour le retrouver rapidement ici lors de vos révisions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return DocumentCard(
                  document: item.document,
                  subjectName: item.subjectName,
                );
              },
            ),
    );
  }
}

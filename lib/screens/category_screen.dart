import 'package:flutter/material.dart';
import '../theme.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = ModalRoute.of(context)?.settings.arguments as String? ?? 'tamil';
    final categories = (language == 'telugu')
      ? ['Vowels', 'Consonants', 'Typing Quiz']
      : ['Vowels', 'Consonants', 'Words'];

    return Scaffold(
      appBar: AppBar(
        title: Text(language.toUpperCase()),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choose a category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_,__) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  // Telugu-style premium card
                  if (language == 'telugu') {
                    final gradient = LinearGradient(colors: [const Color(0xFF4361EE), const Color(0xFF6D5DF5)], begin: Alignment.topLeft, end: Alignment.bottomRight);
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/quiz', arguments: {'language': language, 'category': cat}),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,8))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(cat, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text('Practice Telugu $cat', style: const TextStyle(color: Colors.white70)),
                            ]),
                            const Icon(Icons.chevron_right, color: Colors.white)
                          ],
                        ),
                      ),
                    );
                  }

                  // Default simple button for other languages
                  return FilledButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/quiz',
                      arguments: {'language': language, 'category': cat},
                    ),
                    child: Text(cat, style: const TextStyle(fontSize: 18)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

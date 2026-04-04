import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../providers/family_provider.dart';
import '../../providers/recipe_provider.dart';
import 'recipe_list_screen.dart';

class RecipeRequestScreen extends StatefulWidget {
  const RecipeRequestScreen({super.key});

  @override
  State<RecipeRequestScreen> createState() => _RecipeRequestScreenState();
}

class _RecipeRequestScreenState extends State<RecipeRequestScreen> {
  int _cookTime = 30;
  String _mealType = 'dinner';
  final _wishController = TextEditingController();

  // Members selection — empty means "not yet initialized"; after init == all selected
  Set<String> _selectedMemberIds = {};
  bool _membersInitialized = false;

  final _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  static const _localeId = 'ru-RU';

  static const _mealTypes = [
    ('breakfast', 'Завтрак', Icons.free_breakfast),
    ('lunch', 'Обед', Icons.lunch_dining),
    ('dinner', 'Ужин', Icons.dinner_dining),
    ('snack', 'Перекус', Icons.cookie),
  ];

  static const _cookTimes = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize all members as selected on first load
    if (!_membersInitialized) {
      final members = context.read<FamilyProvider>().members;
      if (members.isNotEmpty) {
        _membersInitialized = true;
        _selectedMemberIds = members
            .where((m) => m.id != null)
            .map((m) => m.id!)
            .toSet();
      }
    }
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _wishController.text = result.recognizedWords;
            if (result.finalResult) _isListening = false;
          });
        },
        localeId: _localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  @override
  void dispose() {
    _wishController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    final familyId = context.read<FamilyProvider>().familyId;
    if (familyId == null) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    await context.read<RecipeProvider>().generateRecipes(
          familyId: familyId,
          cookTime: _cookTime,
          mealType: _mealType,
          wishText: _wishController.text.trim(),
          selectedMemberIds: _selectedMemberIds.toList(),
        );

    if (mounted) {
      final provider = context.read<RecipeProvider>();
      if (provider.status == RecipeStatus.success) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecipeListScreen()),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RecipeProvider>().isLoading;
    final members = context.watch<FamilyProvider>().members;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подобрать рецепты'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Family members selection
          if (members.isNotEmpty) ...[
            _SectionTitle('Готовим для'),
            Card(
              child: Column(
                children: members.map((m) {
                  final selected = _selectedMemberIds.contains(m.id);
                  return CheckboxListTile(
                    dense: true,
                    activeColor: Colors.green,
                    value: selected,
                    onChanged: m.id == null
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                _selectedMemberIds.add(m.id!);
                              } else if (_selectedMemberIds.length > 1) {
                                // Keep at least one member selected
                                _selectedMemberIds.remove(m.id!);
                              }
                            });
                          },
                    secondary: CircleAvatar(
                      radius: 14,
                      backgroundColor: selected
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      child: Text(
                        m.name[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(m.name,
                        style: TextStyle(
                            color: selected ? null : Colors.grey)),
                    subtitle: m.dietaryPreferences.isEmpty
                        ? null
                        : Text(m.dietaryPreferences.join(', '),
                            style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Meal type
          _SectionTitle('Тип приёма пищи'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: _mealTypes.map((type) {
              final selected = _mealType == type.$1;
              return InkWell(
                onTap: () => setState(() => _mealType = type.$1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? Colors.green : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected ? Colors.green : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.$3,
                          color: selected ? Colors.white : Colors.grey,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(type.$2,
                          style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Cook time
          _SectionTitle('Время приготовления: $_cookTime мин'),
          Slider(
            value: _cookTime.toDouble(),
            min: 15,
            max: 90,
            divisions: 5,
            activeColor: Colors.green,
            label: '$_cookTime мин',
            onChanged: (v) => setState(() => _cookTime = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _cookTimes
                .map((t) => Text('$t',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: _cookTime == t
                            ? FontWeight.bold
                            : FontWeight.normal)))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Wish field with voice input
          _SectionTitle('Пожелание к рецептам'),
          TextField(
            controller: _wishController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Например: что-нибудь итальянское, без лука...',
              border: const OutlineInputBorder(),
              suffixIcon: _speechAvailable
                  ? IconButton(
                      tooltip: _isListening ? 'Остановить' : 'Говорить',
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.green,
                      ),
                      onPressed: _toggleListening,
                    )
                  : null,
            ),
          ),
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Text('Слушаю...',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(height: 32),

          // Generate button
          ElevatedButton.icon(
            onPressed: isLoading ? null : _generate,
            icon: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(
                isLoading ? 'Генерируем рецепты...' : 'Подобрать рецепты',
                style: const TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.green, fontWeight: FontWeight.bold)),
      );
}

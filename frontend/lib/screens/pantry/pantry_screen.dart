import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/pantry_item.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/pantry_vision_service.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  bool _scanningPhoto = false;

  Future<void> _scanPantryPhoto(String familyId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (image == null || !mounted) return;

    setState(() => _scanningPhoto = true);

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final products = await PantryVisionService().analyzePantryPhoto(base64Image);

      if (!mounted) return;
      setState(() => _scanningPhoto = false);

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Продукты не распознаны. Попробуйте снять чётче.')),
        );
        return;
      }

      _showDetectedProductsDialog(context, familyId, products);
    } catch (e) {
      if (mounted) {
        setState(() => _scanningPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка анализа фото: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetectedProductsDialog(
    BuildContext context,
    String familyId,
    List<Map<String, dynamic>> products,
  ) {
    final selected = List<bool>.filled(products.length, true);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Распознанные продукты'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return CheckboxListTile(
                  dense: true,
                  value: selected[i],
                  title: Text(p['name']?.toString() ?? ''),
                  subtitle: Text(
                      '${p['quantity']} ${p['unit']}',
                      style: const TextStyle(fontSize: 12)),
                  onChanged: (v) => setDialogState(() => selected[i] = v ?? false),
                  activeColor: Colors.green,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final pantry = context.read<PantryProvider>();
                int added = 0;
                for (int i = 0; i < products.length; i++) {
                  if (!selected[i]) continue;
                  final p = products[i];
                  final qty = (p['quantity'] as num?)?.toDouble() ?? 1.0;
                  final success = await pantry.addItem(
                    familyId,
                    name: p['name']?.toString() ?? 'Продукт',
                    quantity: qty,
                    unit: p['unit']?.toString() ?? 'шт',
                  );
                  if (success) added++;
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Добавлено $added продукт(ов)')),
                  );
                }
              },
              child: const Text('Добавить выбранные'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    final familyId = context.watch<FamilyProvider>().familyId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кладовая'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          pantry.items.isEmpty
              ? const _EmptyPantry()
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: pantry.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = pantry.items[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.kitchen, color: Colors.green, size: 20),
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.displayQuantity),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: familyId == null
                                ? null
                                : () => _showItemDialog(context, familyId, item: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            onPressed: familyId == null
                                ? null
                                : () => _confirmDelete(context, familyId, item),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          if (_scanningPhoto)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Анализируем фото...',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: familyId == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'camera_fab',
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  mini: true,
                  tooltip: 'Сфотографировать кладовую',
                  onPressed: _scanningPhoto
                      ? null
                      : () => _scanPantryPhoto(familyId),
                  child: const Icon(Icons.camera_alt),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'add_fab',
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                  onPressed: () => _showItemDialog(context, familyId),
                ),
              ],
            ),
    );
  }

  void _showItemDialog(BuildContext context, String familyId,
      {PantryItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PantryProvider>(),
        child: _ItemForm(familyId: familyId, item: item),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String familyId, PantryItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить продукт?'),
        content: Text('«${item.name}» будет удалён из кладовой.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PantryProvider>().deleteItem(familyId, item.id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Bottom-sheet form ──────────────────────────────────────────────────────────

class _ItemForm extends StatefulWidget {
  final String familyId;
  final PantryItem? item;

  const _ItemForm({required this.familyId, this.item});

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();

  final _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  static const _unitSuggestions = ['г', 'кг', 'мл', 'л', 'шт', 'уп', 'ст.л', 'ч.л'];

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity == widget.item!.quantity.truncateToDouble()
          ? widget.item!.quantity.toInt().toString()
          : widget.item!.quantity.toString();
      _unitController.text = widget.item!.unit;
    }
    _initSpeech();
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
            _nameController.text = result.recognizedWords;
            if (result.finalResult) _isListening = false;
          });
        },
        localeId: 'ru_RU',
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pantry = context.read<PantryProvider>();
    final qty = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1.0;
    bool success;

    if (_isEditing) {
      success = await pantry.updateItem(
        widget.familyId,
        widget.item!.copyWith(
          name: _nameController.text.trim(),
          quantity: qty,
          unit: _unitController.text.trim(),
        ),
      );
    } else {
      success = await pantry.addItem(
        widget.familyId,
        name: _nameController.text.trim(),
        quantity: qty,
        unit: _unitController.text.trim(),
      );
    }

    if (mounted && success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Редактировать продукт' : 'Добавить продукт',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Название',
                border: const OutlineInputBorder(),
                suffixIcon: _speechAvailable
                    ? IconButton(
                        tooltip: _isListening ? 'Остановить' : 'Назвать голосом',
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.green,
                        ),
                        onPressed: _toggleListening,
                      )
                    : null,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите название' : null,
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text('Слушаю...',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Количество',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите количество';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Неверный формат';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Единица',
                      border: OutlineInputBorder(),
                      hintText: 'г, кг, шт...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Unit quick-pick chips
            Wrap(
              spacing: 6,
              children: _unitSuggestions.map((u) => ActionChip(
                label: Text(u),
                onPressed: () => setState(() => _unitController.text = u),
                backgroundColor: _unitController.text == u
                    ? Colors.green.shade100
                    : null,
              )).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_isEditing ? 'Сохранить' : 'Добавить',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPantry extends StatelessWidget {
  const _EmptyPantry();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Кладовая пуста',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Добавьте продукты или сфотографируйте кладовую',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

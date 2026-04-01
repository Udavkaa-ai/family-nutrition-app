import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/firebase_config.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<String?> _getIdToken() async {
    final user = context.read<AuthProvider>().user;
    return user?.getIdToken();
  }

  Future<void> _createFamily() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final token = await _getIdToken();
      final response = await http.post(
        Uri.parse('${FirebaseConfig.backendUrl}/api/families'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': _familyNameController.text.trim()}),
      );

      if (!mounted) return;
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _showInviteCode(data['inviteCode'] as String);
      } else {
        final err = jsonDecode(response.body)['error'] ?? 'Ошибка создания семьи';
        _showError(err);
      }
    } catch (_) {
      _showError('Нет соединения с сервером');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinFamily() async {
    if (!_joinFormKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final token = await _getIdToken();
      final response = await http.post(
        Uri.parse('${FirebaseConfig.backendUrl}/api/families/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'inviteCode': _inviteCodeController.text.trim().toUpperCase()}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        // FamilyProvider will pick up the new familyId via Firestore stream
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы присоединились к семье!'), backgroundColor: Colors.green),
        );
      } else {
        final err = jsonDecode(response.body)['error'] ?? 'Неверный код приглашения';
        _showError(err);
      }
    } catch (_) {
      _showError('Нет соединения с сервером');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInviteCode(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Семья создана!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Код приглашения для других членов семьи:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Скопировать'),
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка семьи'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Создать семью'),
            Tab(text: 'Вступить'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Create family tab ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _createFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Icon(Icons.family_restroom, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'Создайте семью и пригласите близких',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _familyNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Название семьи',
                      prefixIcon: Icon(Icons.home_outlined),
                      border: OutlineInputBorder(),
                      hintText: 'Например: Семья Ивановых',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите название';
                      if (v.trim().length < 2) return 'Минимум 2 символа';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _createFamily,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Создать семью', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),

          // ── Join family tab ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _joinFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Icon(Icons.group_add, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'Введите код приглашения от члена семьи',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _inviteCodeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Код приглашения',
                      prefixIcon: Icon(Icons.key_outlined),
                      border: OutlineInputBorder(),
                      hintText: 'XXXXXX',
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите код';
                      if (v.trim().length != 6) return 'Код состоит из 6 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _joinFamily,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Присоединиться', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

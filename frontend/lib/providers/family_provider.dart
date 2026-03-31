import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/family_member.dart';
import '../services/family_service.dart';

class FamilyProvider extends ChangeNotifier {
  final FamilyService _service;

  String? _familyId;
  String? _familyName;
  String? _inviteCode;
  List<FamilyMember> _members = [];
  bool _loading = false;
  String? _errorMessage;

  StreamSubscription<String?>? _familyIdSub;
  StreamSubscription<List<FamilyMember>>? _membersSub;

  FamilyProvider({FamilyService? service})
      : _service = service ?? FamilyService() {
    _listenToFamilyId();
  }

  String? get familyId => _familyId;
  String? get familyName => _familyName;
  String? get inviteCode => _inviteCode;
  List<FamilyMember> get members => _members;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get hasFamily => _familyId != null;

  void _listenToFamilyId() {
    _familyIdSub = _service.familyIdStream.listen((id) async {
      if (id == _familyId) return;
      _familyId = id;
      _membersSub?.cancel();

      if (id != null) {
        await _loadFamilyData(id);
        _membersSub = _service.membersStream(id).listen((members) {
          _members = members;
          notifyListeners();
        });
      } else {
        _familyName = null;
        _inviteCode = null;
        _members = [];
      }
      notifyListeners();
    });
  }

  Future<void> _loadFamilyData(String familyId) async {
    final data = await _service.getFamily(familyId);
    if (data != null) {
      _familyName = data['name'] as String?;
      _inviteCode = data['inviteCode'] as String?;
    }
  }

  Future<bool> addMember(FamilyMember member) async {
    _setLoading(true);
    try {
      await _service.addMember(member);
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка при добавлении участника';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMember(String memberId, Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      await _service.updateMember(memberId, updates);
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка при обновлении участника';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMember(String memberId) async {
    _setLoading(true);
    try {
      await _service.deleteMember(memberId);
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка при удалении участника';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _familyIdSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }
}

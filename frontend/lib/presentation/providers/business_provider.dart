import 'package:flutter/foundation.dart';
import '../../data/models/business_model.dart';
import '../../data/repositories/business_repository.dart';

class BusinessProvider with ChangeNotifier {
  final BusinessRepository _repository;

  BusinessProvider(this._repository);

  BusinessModel? _business;
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  BusinessModel? get business => _business;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isPro => _business?.plan.toUpperCase() == 'PAID';

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _business = await _repository.getProfile();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(BusinessUpdateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _business = await _repository.updateProfile(request);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadLogo(Uint8List imageBytes, String filename) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _business = await _repository.uploadLogo(imageBytes, filename);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadBanner(Uint8List imageBytes, String filename) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _business = await _repository.uploadBanner(imageBytes, filename);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadImages(List<Uint8List> imagesBytes, List<String> filenames) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _business = await _repository.uploadImages(imagesBytes, filenames);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repository.getStats();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/error_service.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final ErrorService _errorService = ErrorService();

  /// Kamera izni kontrol et ve iste
  Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      // ImagePicker otomatik olarak izin ister
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image == null) {
        if (context.mounted) {
          _errorService.showInfoSnackBar(
            context,
            'Kamera erişimi gerekli. Lütfen izin verin.',
          );
        }
        return false;
      }
      
      return true;
    } catch (e) {
      if (context.mounted) {
        _errorService.showErrorSnackBar(context, e);
      }
      return false;
    }
  }

  /// Galeri izni kontrol et ve iste
  Future<bool> requestGalleryPermission(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image == null) {
        if (context.mounted) {
          _errorService.showInfoSnackBar(
            context,
            'Galeri erişimi gerekli. Lütfen izin verin.',
          );
        }
        return false;
      }
      
      return true;
    } catch (e) {
      if (context.mounted) {
        _errorService.showErrorSnackBar(context, e);
      }
      return false;
    }
  }

  /// İzin reddedildiğinde gösterilecek dialog
  void showPermissionDeniedDialog(BuildContext context, String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin Gerekli'),
        content: Text(
          '$permission izni gerekli. Lütfen ayarlardan izin verin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Kamera kullanımı için gerekli kontroller
  Future<bool> checkCameraAvailability(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      // Test amaçlı kamera erişimi dene
      await picker.pickImage(source: ImageSource.camera);
      return true;
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains('permission')) {
          _errorService.showErrorSnackBar(
            context,
            'Kamera izni gerekli. Lütfen ayarlardan izin verin.',
          );
        } else if (e.toString().contains('camera')) {
          _errorService.showErrorSnackBar(
            context,
            'Kamera bulunamadı veya kullanımda.',
          );
        } else {
          _errorService.showErrorSnackBar(context, e);
        }
      }
      return false;
    }
  }

  /// Dosya erişimi için gerekli kontroller
  Future<bool> checkStorageAvailability(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      // Test amaçlı galeri erişimi dene
      await picker.pickImage(source: ImageSource.gallery);
      return true;
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains('permission')) {
          _errorService.showErrorSnackBar(
            context,
            'Dosya erişim izni gerekli. Lütfen ayarlardan izin verin.',
          );
        } else {
          _errorService.showErrorSnackBar(context, e);
        }
      }
      return false;
    }
  }
}

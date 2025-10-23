import 'package:flutter/material.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  /// Hata mesajlarını kullanıcı dostu hale getir
  String getErrorMessage(dynamic error) {
    if (error.toString().contains('camera')) {
      return 'Kamera erişimi reddedildi. Lütfen kamera iznini verin.';
    }
    if (error.toString().contains('storage')) {
      return 'Dosya erişimi reddedildi. Lütfen depolama iznini verin.';
    }
    if (error.toString().contains('network')) {
      return 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
    }
    if (error.toString().contains('face')) {
      return 'Yüz tespit edilemedi. Lütfen net bir görüntü çekin.';
    }
    if (error.toString().contains('database')) {
      return 'Veritabanı hatası. Lütfen uygulamayı yeniden başlatın.';
    }
    return 'Beklenmeyen bir hata oluştu: ${error.toString()}';
  }

  /// Hata snackbar'ı göster
  void showErrorSnackBar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Başarı snackbar'ı göster
  void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Bilgi snackbar'ı göster
  void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hata dialog'u göster
  void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Onay dialog'u göster
  Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_service.dart';
import '../models/user.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FaceService _faceService = FaceService();
  
  bool _isVerifying = false;
  double? _verificationScore;
  bool? _isVerified;
  String? _verificationMessage;

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _verifyFace() async {
    print('🔍 Yüz doğrulama başlatıldı...');
    
    setState(() {
      _isVerifying = true;
      _verificationScore = null;
      _isVerified = null;
      _verificationMessage = null;
    });

    try {
      print('📸 Kamera ile yüz verisi yakalanıyor...');
      
      // 1. Yeni yüz verisi yakala
      final result = await _faceService.processFullFaceFlow(
        source: ImageSource.camera,
      );

      print('📊 Yüz işleme sonucu: $result');

      if (result['success'] != true || result['embedding'] == null) {
        print('❌ Yüz verisi alınamadı: ${result['message']}');
        setState(() {
          _verificationMessage = result['message'] ?? 'Yüz verisi alınamadı';
          _isVerified = false;
        });
        return;
      }

      final currentEmbedding = List<double>.from(result['embedding']);
      print('✅ Yeni embedding alındı, boyut: ${currentEmbedding.length}');
      
      // 2. Kullanıcının kayıtlı embedding'ini al
      final savedEmbedding = widget.user.embeddingList;
      print('💾 Kayıtlı embedding boyutu: ${savedEmbedding.length}');
      
      if (savedEmbedding.isEmpty) {
        print('❌ Kayıtlı yüz verisi bulunamadı');
        setState(() {
          _verificationMessage = 'Kayıtlı yüz verisi bulunamadı';
          _isVerified = false;
        });
        return;
      }

      // 3. Embedding'leri karşılaştır (Kosinüs benzerliği)
      print('🧮 Benzerlik hesaplanıyor...');
      final similarity = _calculateCosineSimilarity(currentEmbedding, savedEmbedding);
      final score = (similarity * 100); // Yüzde olarak
      print('📈 Benzerlik skoru: $score%');
      
      // 4. Sonuçları değerlendir (Eşik: %60 - daha düşük eşik)
      const threshold = 60.0;
      final verified = score >= threshold;
      print('🎯 Doğrulama sonucu: ${verified ? "BAŞARILI" : "BAŞARISIZ"} (Eşik: $threshold%)');

      setState(() {
        _verificationScore = score;
        _isVerified = verified;
        _verificationMessage = verified 
            ? 'Yüz doğrulaması başarılı!'
            : 'Yüz doğrulaması başarısız. Lütfen tekrar deneyin.';
      });

      // Sonucu göster
      if (mounted) {
        print('📱 SnackBar gösteriliyor: $_verificationMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_verificationMessage!),
            backgroundColor: verified ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('💥 Doğrulama hatası: $e');
      setState(() {
        _verificationMessage = 'Doğrulama hatası: $e';
        _isVerified = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doğrulama hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
      print('🏁 Yüz doğrulama tamamlandı');
    }
  }

  /// Kosinüs benzerliği hesapla
  double _calculateCosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // LoginScreen'e dön
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hoş Geldiniz, ${widget.user.firstName}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kullanıcı Bilgileri Kartı
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        '${widget.user.firstName[0]}${widget.user.lastName[0]}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.user.firstName} ${widget.user.lastName}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.user.email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Yüz Doğrulama Bölümü
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.face_retouching_natural,
                      size: 64,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yüz Doğrulama',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kimliğinizi doğrulamak için yüzünüzü tarayın',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sonuç Gösterimi
                    if (_verificationScore != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isVerified! ? Colors.green.shade50 : Colors.orange.shade50,
                          border: Border.all(
                            color: _isVerified! ? Colors.green.shade200 : Colors.orange.shade200,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isVerified! ? Icons.check_circle : Icons.cancel,
                              size: 48,
                              color: _isVerified! ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _verificationMessage ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isVerified! ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Doğruluk Skoru: ${_verificationScore!.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Doğrulama Butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isVerifying ? null : _verifyFace,
                        icon: _isVerifying 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(_isVerifying ? 'Doğrulanıyor...' : 'Yüzünü Doğrula'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Doğrulama için yüzünüzü kameraya gösterin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bilgi Kartı
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Yüz doğrulama için net bir görüntü gereklidir. İyi aydınlatılmış bir ortamda kullanın.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


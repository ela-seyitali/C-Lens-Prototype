import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_service.dart';
import '../data/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final FaceService _faceService = FaceService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  bool _isLoading = false;
  bool _hasFaceData = false;
  String? _faceErrorMessage;
  List<double>? _faceEmbedding;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _captureFaceData() async {
    setState(() {
      _isLoading = true;
      _faceErrorMessage = null;
    });

    try {
      final result = await _faceService.processFullFaceFlow(
        source: ImageSource.camera,
      );

      if (result['success'] == true && result['embedding'] != null) {
        setState(() {
          _faceEmbedding = List<double>.from(result['embedding']);
          _hasFaceData = true;
          _faceErrorMessage = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yüz verisi başarıyla kaydedildi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _faceErrorMessage = result['message'] ?? 'Yüz verisi alınamadı';
          _hasFaceData = false;
          _faceEmbedding = null;
        });
      }
    } catch (e) {
      setState(() {
        _faceErrorMessage = 'Yüz verisi alınırken hata oluştu: $e';
        _hasFaceData = false;
        _faceEmbedding = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasFaceData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce yüz verinizi kaydedin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Embedding'i JSON string'e çevir
      final embeddingJson = _dbHelper.embeddingToJson(_faceEmbedding!);
      print('🔍 Embedding JSON oluşturuldu, boyut: ${_faceEmbedding!.length}');
      
      // Duplicate face check - aynı yüz verisiyle kayıt var mı?
      print('🔍 Duplicate face check başlatılıyor...');
      final existingUser = await _dbHelper.getUserByFaceEmbedding(embeddingJson);
      
      if (existingUser != null) {
        print('❌ Duplicate face bulundu! Kullanıcı: ${existingUser['email']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu yüz verisi zaten kayıtlı! Lütfen farklı bir yüz kullanın.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } else {
        print('✅ Duplicate face bulunamadı, kayıt devam ediyor...');
      }
      
      // Kullanıcıyı database'e kaydet
      await _dbHelper.insertUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        faceEmbedding: embeddingJson,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context); // Giriş ekranına dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Form Alanları
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Soyad gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta gereklidir';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Geçerli bir e-posta giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre gereklidir';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre Tekrar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre tekrarı gereklidir';
                  }
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Yüz Verisi Bölümü
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _hasFaceData ? Icons.face : Icons.face_retouching_off,
                      size: 48,
                      color: _hasFaceData ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasFaceData ? 'Yüz Verisi Kaydedildi' : 'Yüz Verisi Gerekli',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _hasFaceData ? Colors.green : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_faceErrorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _faceErrorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _captureFaceData,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(_isLoading ? 'İşleniyor...' : 'Yüzünü Kaydet'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Kayıt Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Kaydediliyor...'),
                        ],
                      )
                    : const Text(
                        'Kayıt Ol',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // Giriş Sayfasına Git
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zaten hesabım var, Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


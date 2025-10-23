import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'face_recognition.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        face_embedding TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Kullanıcı kaydı
  Future<int> insertUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? faceEmbedding,
  }) async {
    final db = await database;
    final passwordHash = _hashPassword(password);
    
    return await db.insert(
      'users',
      {
        'email': email,
        'password_hash': passwordHash,
        'first_name': firstName,
        'last_name': lastName,
        'face_embedding': faceEmbedding,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Kullanıcı giriş kontrolü (Güvenli şifre doğrulama)
  Future<Map<String, dynamic>?> getUserByEmailAndPassword(
    String email,
    String password,
  ) async {
    final db = await database;
    
    // Önce kullanıcıyı email ile bul
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isEmpty) return null;

    final user = result.first;
    final storedHash = user['password_hash'] as String;
    
    // Şifreyi güvenli şekilde doğrula
    if (!_verifyPassword(password, storedHash)) {
      return null;
    }

    return user;
  }

  // Kullanıcı bilgilerini email ile getir
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // Yüz embedding'i ile kullanıcı ara (duplicate check) - Optimized
  Future<Map<String, dynamic>?> getUserByFaceEmbedding(String embeddingJson) async {
    print('🔍 Database: Duplicate face check başlatılıyor...');
    final db = await database;
    
    // Sadece face_embedding'i olan kullanıcıları al
    final usersWithFace = await db.query(
      'users',
      where: 'face_embedding IS NOT NULL AND face_embedding != ?',
      whereArgs: [''],
    );
    
    print('📊 Database: ${usersWithFace.length} kullanıcı yüz verisi ile bulundu');
    
    // Yeni embedding'i parse et (bir kez)
    final newEmbedding = _parseEmbeddingFromJson(embeddingJson);
    if (newEmbedding.isEmpty) {
      print('❌ Database: Yeni embedding parse edilemedi');
      return null;
    }
    
    print('✅ Database: Yeni embedding parse edildi, boyut: ${newEmbedding.length}');
    
    for (int i = 0; i < usersWithFace.length; i++) {
      final user = usersWithFace[i];
      final userEmail = user['email'] as String;
      print('🔍 Database: Kullanıcı $i kontrol ediliyor: $userEmail');
      
      final userEmbedding = user['face_embedding'] as String;
      if (userEmbedding.isNotEmpty) {
        // Şifreli embedding'i çöz
        final decryptedEmbedding = _decryptData(userEmbedding);
        if (decryptedEmbedding.isNotEmpty) {
          // Hızlı benzerlik kontrolü yap
          final similarity = _calculateEmbeddingSimilarityFast(newEmbedding, decryptedEmbedding);
          print('📈 Database: Benzerlik skoru: ${(similarity * 100).toStringAsFixed(2)}%');
          
          if (similarity > 0.8) { // %80 benzerlik eşiği
            print('❌ Database: Duplicate face bulundu! Kullanıcı: $userEmail, Benzerlik: ${(similarity * 100).toStringAsFixed(2)}%');
            return user;
          }
        } else {
          print('⚠️ Database: Kullanıcı $userEmail embedding çözülemedi');
        }
      } else {
        print('⚠️ Database: Kullanıcı $userEmail embedding boş');
      }
    }
    
    print('✅ Database: Duplicate face bulunamadı');
    return null;
  }

  // Embedding'i JSON'dan parse et (optimized)
  List<double> _parseEmbeddingFromJson(String embeddingJson) {
    try {
      final List<dynamic> list = json.decode(embeddingJson);
      return list.map((e) => double.parse(e.toString())).toList();
    } catch (e) {
      return [];
    }
  }

  // Hızlı embedding benzerliği hesapla (List<double> ile)
  double _calculateEmbeddingSimilarityFast(List<double> embedding1, String embedding2Json) {
    try {
      final List<dynamic> list2 = json.decode(embedding2Json);
      final List<double> embedding2 = list2.map((e) => double.parse(e.toString())).toList();
      
      if (embedding1.length != embedding2.length) return 0.0;
      
      // Kosinüs benzerliği hesapla (optimized)
      double dotProduct = 0.0;
      double norm1 = 0.0;
      double norm2 = 0.0;
      
      for (int i = 0; i < embedding1.length; i++) {
        final val1 = embedding1[i];
        final val2 = embedding2[i];
        dotProduct += val1 * val2;
        norm1 += val1 * val1;
        norm2 += val2 * val2;
      }
      
      if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
      
      return dotProduct / (sqrt(norm1) * sqrt(norm2));
    } catch (e) {
      return 0.0;
    }
  }


  // Yüz embedding'ini güncelle
  Future<int> updateFaceEmbedding(String email, String embedding) async {
    final db = await database;
    
    return await db.update(
      'users',
      {'face_embedding': embedding},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // Güvenli şifre hash'leme (Salt ile)
  String _hashPassword(String password) {
    // Rastgele salt oluştur
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  // Salt oluştur
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // Şifre doğrulama
  bool _verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == hash;
    } catch (e) {
      return false;
    }
  }

  // Embedding'i JSON'dan parse et (Şifreli veri)
  List<double> parseEmbedding(String? embeddingJson) {
    if (embeddingJson == null || embeddingJson.isEmpty) {
      return [];
    }
    
    try {
      // Önce şifreyi çöz
      final decryptedJson = _decryptData(embeddingJson);
      if (decryptedJson.isEmpty) return [];
      
      final List<dynamic> embeddingList = json.decode(decryptedJson);
      return embeddingList.map((e) => double.parse(e.toString())).toList();
    } catch (e) {
      return [];
    }
  }

  // Embedding'i JSON'a çevir (Şifreli)
  String embeddingToJson(List<double> embedding) {
    final jsonString = json.encode(embedding);
    return _encryptData(jsonString);
  }

  // Veri şifreleme (Basit XOR şifreleme)
  String _encryptData(String data) {
    final key = 'face_encryption_key_2024'; // Gerçek uygulamada daha güvenli olmalı
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    
    final encrypted = <int>[];
    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }

  // Veri şifre çözme
  String _decryptData(String encryptedData) {
    try {
      final key = 'face_encryption_key_2024';
      final keyBytes = utf8.encode(key);
      final encryptedBytes = base64.decode(encryptedData);
      
      final decrypted = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      return '';
    }
  }
}


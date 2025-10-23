# C-Lens-Protoype

Yüz tanıma teknolojisi kullanarak güvenli kimlik doğrulama sağlayan Flutter uygulaması.

## Özellikler

- **Yüz Tanıma**: Google ML Kit ve DeepFace teknolojileri ile gelişmiş yüz tanıma
- **Güvenli Kayıt**: Şifre hashleme ve yüz verisi şifreleme ile güvenli kullanıcı kaydı
- **Duplicate Prevention**: Aynı yüz verisiyle birden fazla kayıt önleme sistemi
- **Cross-Platform**: Android, iOS, Web, Windows, macOS ve Linux desteği

## Teknolojiler

- **Flutter**: Cross-platform mobil uygulama geliştirme
- **Google ML Kit**: Yüz tespit ve tanıma
- **DeepFace**: Python tabanlı gelişmiş yüz tanıma
- **SQLite**: Yerel veritabanı
- **SHA-256**: Güvenli şifre hashleme
- **XOR Encryption**: Yüz verisi şifreleme

## Kurulum

1. Flutter SDK'yı yükleyin
2. Projeyi klonlayın:
   ```bash
   git clone https://github.com/ela-seyitali/C-Lens-Protoype.git
   cd C-Lens-Protoype
   ```
3. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
4. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## Kullanım

1. **Kayıt Ol**: E-posta, şifre ve yüz verisi ile kayıt
2. **Giriş Yap**: E-posta/şifre ile giriş
3. **Yüz Doğrula**: Ana ekranda yüzünüzü tarayarak kimlik doğrulama

## Güvenlik

- Tüm şifreler SHA-256 ile hashlenir
- Yüz verileri XOR şifreleme ile korunur
- Aynı yüz verisiyle birden fazla kayıt engellenir
- Güvenli veritabanı işlemleri

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
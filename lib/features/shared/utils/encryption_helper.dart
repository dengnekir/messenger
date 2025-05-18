import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const _keyStorageKey = 'encryption_key';
  static const _ivStorageKey = 'encryption_iv';

  // Şifreleme anahtarını al veya oluştur
  static Future<String> _getOrCreateKey() async {
    String? key = await _secureStorage.read(key: _keyStorageKey);

    // Anahtar yoksa yeni oluştur
    if (key == null) {
      // Rastgele 32 byte (256-bit) key oluştur
      final newKey = encrypt.Key.fromSecureRandom(32).base64;
      await _secureStorage.write(key: _keyStorageKey, value: newKey);
      return newKey;
    }

    return key;
  }

  // IV (Initialization Vector) al veya oluştur
  static Future<String> _getOrCreateIV() async {
    String? iv = await _secureStorage.read(key: _ivStorageKey);

    // IV yoksa yeni oluştur
    if (iv == null) {
      // Rastgele 16 byte IV oluştur
      final newIV = encrypt.IV.fromSecureRandom(16).base64;
      await _secureStorage.write(key: _ivStorageKey, value: newIV);
      return newIV;
    }

    return iv;
  }

  // Mesaj şifreleme
  static Future<String> encryptMessage(String message) async {
    try {
      final key = await _getOrCreateKey();
      final iv = await _getOrCreateIV();

      final encrypter = encrypt.Encrypter(
        encrypt.AES(
          encrypt.Key.fromBase64(key),
          mode: encrypt.AESMode.cbc,
        ),
      );

      final encrypted = encrypter.encrypt(
        message,
        iv: encrypt.IV.fromBase64(iv),
      );

      return encrypted.base64;
    } catch (e) {
      print('Şifreleme hatası: $e');
      // Şifreleme başarısız olursa, mesajın hash değerini döndür
      return base64Encode(sha256.convert(utf8.encode(message)).bytes);
    }
  }

  // Şifreli mesajı çözme
  static Future<String> decryptMessage(String encryptedMessage) async {
    try {
      final key = await _getOrCreateKey();
      final iv = await _getOrCreateIV();

      final encrypter = encrypt.Encrypter(
        encrypt.AES(
          encrypt.Key.fromBase64(key),
          mode: encrypt.AESMode.cbc,
        ),
      );

      final decrypted = encrypter.decrypt(
        encrypt.Encrypted.fromBase64(encryptedMessage),
        iv: encrypt.IV.fromBase64(iv),
      );

      return decrypted;
    } catch (e) {
      print('Şifre çözme hatası: $e');
      return '[Şifrelenmiş mesaj çözülemedi]';
    }
  }

  // Kullanıcıya özel şifreleme anahtarları oluşturma (ileri seviye güvenlik için)
  static Future<void> generateUserSpecificKeys(String userId) async {
    // Kullanıcı ID'sine göre benzersiz bir anahtar oluşturabiliriz
    final userKeyBase = sha256.convert(utf8.encode(userId)).toString();

    // Kullanıcıya özel şifreleme anahtarı
    final userKey = encrypt.Key(
            Uint8List.fromList(utf8.encode(userKeyBase.substring(0, 32))))
        .base64;

    // Kullanıcıya özel IV
    final userIv = encrypt
        .IV(Uint8List.fromList(utf8.encode(userKeyBase.substring(0, 16))))
        .base64;

    // Anahtarları kaydet
    await _secureStorage.write(
        key: '${_keyStorageKey}_$userId', value: userKey);
    await _secureStorage.write(key: '${_ivStorageKey}_$userId', value: userIv);
  }
}

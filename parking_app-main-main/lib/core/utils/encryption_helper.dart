import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  final key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final iv = encrypt.IV.fromLength(16);

  String encryptData(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
    return decrypted;
  }
}

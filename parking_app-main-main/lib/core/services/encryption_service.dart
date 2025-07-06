import 'dart:convert';
import 'package:crypto/crypto.dart';  // For sha256 hashing
import "package:encrypt/encrypt.dart" as encrypt;  // For AES encryption

class EncryptionService {
  final _key = encrypt.Key.fromUtf8('your_32_length_key_for_AES_encryption'); // Must be 32 bytes
  final _iv = encrypt.IV.fromLength(16); // IV should be 16 bytes for AES encryption
  
  // Encrypt the plain text
  String encryptText(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;  // Return the encrypted text in base64 format
  }

  // Decrypt the encrypted text
  String decryptText(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    return encrypter.decrypt(encrypted, iv: _iv);  // Decrypt the text
  }

  // Hash the password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);  // Convert password to bytes
    final digest = sha256.convert(bytes);  // Generate SHA-256 hash
    return digest.toString();  // Return the hash as a string
  }
}

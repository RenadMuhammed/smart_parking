using System;
using System.Security.Cryptography;
using System.Text;

namespace SmartParkingAPI.Helpers
{
    public static class AesGcmHelper
    {
        private static readonly byte[] aad = Encoding.UTF8.GetBytes("LicensePlateEncryption");

        public static string Encrypt(string plainText, out string keyBase64, out string nonceBase64)
        {
            byte[] key = RandomNumberGenerator.GetBytes(32);   // ✅ 256-bit random key (was 16 bytes → now 32 bytes)
            byte[] nonce = RandomNumberGenerator.GetBytes(12); // 96-bit random nonce

            byte[] plainBytes = Encoding.UTF8.GetBytes(plainText);
            byte[] cipherBytes = new byte[plainBytes.Length];
            byte[] tag = new byte[16];

            using var aes = new AesGcm(key);
            aes.Encrypt(nonce, plainBytes, cipherBytes, tag, aad);

            keyBase64 = Convert.ToBase64String(key);
            nonceBase64 = Convert.ToBase64String(nonce);

            return Convert.ToBase64String(cipherBytes) + ":" + Convert.ToBase64String(tag);
        }

        public static string Decrypt(string encryptedData, string keyBase64, string nonceBase64)
        {
            try
            {
                var parts = encryptedData.Split(':');
                if (parts.Length != 2) return null;

                byte[] key = Convert.FromBase64String(keyBase64);
                byte[] nonce = Convert.FromBase64String(nonceBase64);
                byte[] cipherBytes = Convert.FromBase64String(parts[0]);
                byte[] tag = Convert.FromBase64String(parts[1]);
                byte[] plainBytes = new byte[cipherBytes.Length];

                using var aes = new AesGcm(key);
                aes.Decrypt(nonce, cipherBytes, tag, plainBytes, aad);

                return Encoding.UTF8.GetString(plainBytes);
            }
            catch
            {
                return null;
            }
        }
    }
}

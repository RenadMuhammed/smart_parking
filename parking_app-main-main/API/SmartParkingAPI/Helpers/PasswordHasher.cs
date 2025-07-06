using BCrypt.Net;

namespace SmartParkingAPI.Helpers
{
    public static class PasswordHasher
    {
        // Hash a password with a strong work factor (default is 10; 12 is recommended)
        public static string HashPassword(string plainPassword, int workFactor = 12)
        {
            return BCrypt.Net.BCrypt.HashPassword(plainPassword, workFactor);
        }

        // Verify a password against its stored hash
        public static bool VerifyPassword(string plainPassword, string hashedPassword)
        {
            if (string.IsNullOrWhiteSpace(plainPassword) || string.IsNullOrWhiteSpace(hashedPassword))
                return false;

            return BCrypt.Net.BCrypt.Verify(plainPassword, hashedPassword);
        }
    }
}

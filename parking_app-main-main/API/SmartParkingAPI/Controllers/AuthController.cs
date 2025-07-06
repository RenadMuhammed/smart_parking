using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SmartParkingAPI.Helpers;
using SmartParkingAPI.Models.Requests;

namespace SmartParkingAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public AuthController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // ✅ REGISTER
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            Console.WriteLine($"📥 Registering user: {request.Email}");

            using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
            await connection.OpenAsync();

            // 🔎 Check if email already exists by decrypting all
            var checkCmd = new SqlCommand("SELECT Email, Key_email, Nonce_email FROM [User]", connection);
            var reader = await checkCmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                string encEmail = reader.GetString(0);
                string key = reader.GetString(1);
                string nonce = reader.GetString(2);

                string decryptedEmail = AesGcmHelper.Decrypt(encEmail, key, nonce);
                if (decryptedEmail == request.Email)
                {
                    reader.Close();
                    return BadRequest(new { success = false, message = "Email already registered." });
                }
            }
            reader.Close();

            // 🔐 Encrypt sensitive fields
            string encryptedPlateLetters = AesGcmHelper.Encrypt(request.PlateLetters, out string keyLetters, out string nonceLetters);
            string encryptedPlateNumbers = AesGcmHelper.Encrypt(request.PlateNumbers, out string keyNumbers, out string nonceNumbers);
            string encryptedNationalId = AesGcmHelper.Encrypt(request.NationalId, out string keyNat, out string nonceNat);
            string encryptedEmail = AesGcmHelper.Encrypt(request.Email, out string keyEmail, out string nonceEmail);
            string hashedPassword = PasswordHasher.HashPassword(request.Password);

            // 💾 Save to DB (NO EmailPlain)
            var insertCmd = new SqlCommand(@"
                INSERT INTO [User] 
                    (National_id, Username, Password, Email, Plate_letters, Plate_numbers, Disability, 
                    Key_letters, Nonce_letters, Key_numbers, Nonce_numbers,
                    Key_nid, Nonce_nid, Key_email, Nonce_email)
                VALUES 
                    (@National_id, @Username, @Password, @Email, @Plate_letters, @Plate_numbers, @Disability, 
                    @Key_letters, @Nonce_letters, @Key_numbers, @Nonce_numbers,
                    @Key_nid, @Nonce_nid, @Key_email, @Nonce_email)", connection);

            insertCmd.Parameters.AddWithValue("@National_id", encryptedNationalId);
            insertCmd.Parameters.AddWithValue("@Username", request.Username);
            insertCmd.Parameters.AddWithValue("@Password", hashedPassword);
            insertCmd.Parameters.AddWithValue("@Email", encryptedEmail);
            insertCmd.Parameters.AddWithValue("@Plate_letters", encryptedPlateLetters);
            insertCmd.Parameters.AddWithValue("@Plate_numbers", encryptedPlateNumbers);
            insertCmd.Parameters.AddWithValue("@Disability", request.Disability);
            insertCmd.Parameters.AddWithValue("@Key_letters", keyLetters);
            insertCmd.Parameters.AddWithValue("@Nonce_letters", nonceLetters);
            insertCmd.Parameters.AddWithValue("@Key_numbers", keyNumbers);
            insertCmd.Parameters.AddWithValue("@Nonce_numbers", nonceNumbers);
            insertCmd.Parameters.AddWithValue("@Key_nid", keyNat);
            insertCmd.Parameters.AddWithValue("@Nonce_nid", nonceNat);
            insertCmd.Parameters.AddWithValue("@Key_email", keyEmail);
            insertCmd.Parameters.AddWithValue("@Nonce_email", nonceEmail);

            await insertCmd.ExecuteNonQueryAsync();

            Console.WriteLine("✅ Registration successful.");
            return Ok(new { success = true, message = "Registration successful." });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Exception: {ex.Message}");
            return StatusCode(500, new { success = false, error = ex.Message });
        }
    }


        // ✅ LOGIN (now using Username instead of Email)
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                Console.WriteLine($"🔐 Login attempt (Username): {request.Username}");

                using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
                await connection.OpenAsync();

                var cmd = new SqlCommand("SELECT Password FROM [User] WHERE Username = @Username", connection);
                cmd.Parameters.AddWithValue("@Username", request.Username);
                var result = await cmd.ExecuteScalarAsync();

                if (result == null)
                {
                    Console.WriteLine("❌ Username not found.");
                    return Unauthorized(new { success = false, message = "Invalid username or password." });
                }

                string storedHash = result.ToString();
                bool isValid = PasswordHasher.VerifyPassword(request.Password, storedHash);

                if (!isValid)
                {
                    Console.WriteLine("❌ Invalid password.");
                    return Unauthorized(new { success = false, message = "Invalid username or password." });
                }

                Console.WriteLine("✅ Login successful.");
                return Ok(new { success = true, message = "Login successful." });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Login error: {ex.Message}");
                return StatusCode(500, new { success = false, error = ex.Message });
            }
        }

    }
}

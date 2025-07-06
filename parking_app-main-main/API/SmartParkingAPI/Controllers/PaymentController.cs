using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SmartParkingAPI.Models.DTO;
using SmartParkingAPI.Helpers;
using System.Data;

namespace SmartParkingAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public PaymentController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpPost]
        public async Task<IActionResult> ProcessPayment([FromBody] PaymentDTO payment)
        {
            try
            {
                using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
                await connection.OpenAsync();

                // ✅ Encrypt card number before storing
                string encryptedCardNumber = AesGcmHelper.Encrypt(payment.CardNumber, out string keyBase64, out string nonceBase64);

                // 🪵 Debugging logs to trace values
                Console.WriteLine("Payment Insert Debug Info:");
                Console.WriteLine($"Username: {payment.Username}");
                Console.WriteLine($"CardType: {payment.CardType}");
                Console.WriteLine($"EncryptedCardNumber: {encryptedCardNumber}");
                Console.WriteLine($"EncryptionKey: {keyBase64}");
                Console.WriteLine($"Nonce: {nonceBase64}");

                // Insert Payment (removed User_id)
                var insertCmd = new SqlCommand(@"
                    INSERT INTO Payment (Username, Card_number, Card_type, Encryption_key, Nonce)
                    VALUES (@Username, @CardNumber, @CardType, @Key, @Nonce)", connection);

                insertCmd.Parameters.AddWithValue("@Username", payment.Username);
                insertCmd.Parameters.AddWithValue("@CardNumber", encryptedCardNumber);
                insertCmd.Parameters.AddWithValue("@CardType", payment.CardType);
                insertCmd.Parameters.AddWithValue("@Key", keyBase64);
                insertCmd.Parameters.AddWithValue("@Nonce", nonceBase64);

                await insertCmd.ExecuteNonQueryAsync();

                // Update Reservation status to 'confirmed' using Username
                var updateCmd = new SqlCommand(@"
                    UPDATE Reservation
                    SET Status = 'confirmed'
                    WHERE Username = @Username AND Status = 'pending'", connection);

                updateCmd.Parameters.AddWithValue("@Username", payment.Username);
                await updateCmd.ExecuteNonQueryAsync();

                return StatusCode(201, new
                {
                    success = true,
                    message = "✅ Payment recorded and reservation confirmed."
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ Payment error: " + ex.Message);
                Console.WriteLine("🔍 StackTrace: " + ex.StackTrace);
                if (ex.InnerException != null)
                {
                    Console.WriteLine("🧠 InnerException: " + ex.InnerException.Message);
                }

                return StatusCode(500, new
                {
                    success = false,
                    message = "❌ Payment processing failed.",
                    error = ex.Message,
                    inner = ex.InnerException?.Message
                });
            }
        }
    }
}
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Dapper;
using System.Linq;
using SmartParkingAPI.Helpers; // Add this to use your AesGcmHelper

namespace SmartParkingAPI.Controllers
{
    [ApiController]
    [Route("api/profile")]
    public class UserProfileController : ControllerBase
    {
        private readonly string _connectionString;
        
        public UserProfileController(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection");
        }
        
        // Get complete user profile with decrypted email
        [HttpGet("{username}")]
        public async Task<IActionResult> GetUserProfile(string username)
        {
            using var connection = new SqlConnection(_connectionString);
            
            // Get all necessary data including encryption keys
            var query = @"
                SELECT 
                    u.User_id as UserId,
                    u.Username,
                    u.Email as EncryptedEmail,
                    u.Key_email,
                    u.Nonce_email,
                    u.Plate_letters as EncryptedPlateLetters,
                    u.Plate_numbers as EncryptedPlateNumbers,
                    u.Key_letters,
                    u.Nonce_letters,
                    u.Key_numbers,
                    u.Nonce_numbers,
                    u.ProfilePicture
                FROM [User] u
                WHERE u.Username = @Username";
            
            var user = await connection.QueryFirstOrDefaultAsync<dynamic>(query, new { Username = username });
            
            if (user == null)
                return NotFound(new { success = false, message = "User not found" });
            
            // Decrypt email using your AesGcmHelper
            string decryptedEmail = null;
            try
            {
                if (user.EncryptedEmail != null && user.Key_email != null && user.Nonce_email != null)
                {
                    decryptedEmail = AesGcmHelper.Decrypt(
                        user.EncryptedEmail, 
                        user.Key_email, 
                        user.Nonce_email
                    );
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error decrypting email: {ex.Message}");
                decryptedEmail = "Unable to decrypt";
            }
            
            // Decrypt license plate
            string licensePlate = null;
            try
            {
                string plateLetters = AesGcmHelper.Decrypt(
                    user.EncryptedPlateLetters, 
                    user.Key_letters, 
                    user.Nonce_letters
                );
                
                string plateNumbers = AesGcmHelper.Decrypt(
                    user.EncryptedPlateNumbers, 
                    user.Key_numbers, 
                    user.Nonce_numbers
                );
                
                licensePlate = $"{plateLetters}-{plateNumbers}";
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error decrypting license plate: {ex.Message}");
                licensePlate = "Unable to decrypt";
            }
            
            return Ok(new
            {
                success = true,
                userId = user.UserId,
                username = user.Username,
                email = decryptedEmail ?? "Not available",
                licensePlate = licensePlate ?? "Not available",
                profilePicture = user.ProfilePicture
            });
        }
        
        // Get user reservation history
        [HttpGet("{userId}/reservations")]
        public async Task<IActionResult> GetUserReservations(int userId)
        {
            using var connection = new SqlConnection(_connectionString);
            
            // First get username from userId
            var usernameQuery = "SELECT Username FROM [User] WHERE User_id = @UserId";
            var username = await connection.QueryFirstOrDefaultAsync<string>(usernameQuery, new { UserId = userId });
            
            if (username == null)
                return NotFound(new { success = false, message = "User not found" });
            
            // Updated query to match actual database schema
            var query = @"
                SELECT 
                    r.Reservation_id as ReservationId,
                    r.Garage_id as GarageId,
                    g.Garage_name as GarageName,
                    r.Section_id as SectionId,
                    r.Start_time as StartTime,
                    r.End_time as EndTime,
                    r.Duration,
                    r.Status,
                    p.Payment_id as PaymentId,
                    CASE 
                        WHEN p.Payment_id IS NOT NULL THEN 
                            CAST(DATEDIFF(MINUTE, r.Start_time, r.End_time) * 10.0 / 60.0 AS DECIMAL(10,2))
                        ELSE NULL 
                    END as PaidAmount
                FROM Reservation r
                INNER JOIN Garage g ON r.Garage_id = g.Garage_id
                LEFT JOIN Payment p ON p.Username = r.Username 
                WHERE r.Username = @Username
                ORDER BY r.Start_time DESC";
            
            var reservations = await connection.QueryAsync<dynamic>(query, new { Username = username });
            
            return Ok(reservations);
        }
        
        // Upload profile picture
        [HttpPost("{userId}/picture")]
        public async Task<IActionResult> UploadProfilePicture(int userId, [FromBody] ProfilePictureDto dto)
        {
            using var connection = new SqlConnection(_connectionString);
            
            // Now update the profile picture
            var query = @"
                UPDATE [User] 
                SET ProfilePicture = @ProfilePicture 
                WHERE User_id = @UserId";
            
            var result = await connection.ExecuteAsync(query, new 
            { 
                UserId = userId,
                ProfilePicture = dto.ImageBase64
            });
            
            if (result > 0)
                return Ok(new { success = true, message = "Profile picture updated" });
            
            return BadRequest(new { success = false, message = "Failed to update profile picture" });
        }
        // Add this method to your existing UserProfileController
[HttpDelete("{userId}/picture")]
public async Task<IActionResult> DeleteProfilePicture(int userId)
{
    using var connection = new SqlConnection(_connectionString);
    
    var query = @"
        UPDATE [User] 
        SET ProfilePicture = NULL 
        WHERE User_id = @UserId";
    
    var result = await connection.ExecuteAsync(query, new { UserId = userId });
    
    if (result > 0)
        return Ok(new { success = true, message = "Profile picture removed" });
    
    return BadRequest(new { success = false, message = "Failed to remove profile picture" });
}
    }
    

    public class ProfilePictureDto
    {
        public string ImageBase64 { get; set; }
    }
}
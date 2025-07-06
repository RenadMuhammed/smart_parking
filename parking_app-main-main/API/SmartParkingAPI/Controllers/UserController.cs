using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;

namespace SmartParkingAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public UserController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpGet("{username}")]
        public async Task<IActionResult> GetUserByUsername(string username)
        {
            try
            {
                using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
                await connection.OpenAsync();

                var cmd = new SqlCommand(@"
                    SELECT User_id, Username, Email, National_id, Plate_letters, Plate_numbers, Disability 
                    FROM [User] 
                    WHERE Username = @Username", connection);
                
                cmd.Parameters.AddWithValue("@Username", username);

                using var reader = await cmd.ExecuteReaderAsync();
                
                if (await reader.ReadAsync())
                {
                    return Ok(new
                    {
                        success = true,
                        userId = reader.GetInt32(0),
                        username = reader.GetString(1),
                        email = reader.GetString(2),
                        nationalId = reader.GetString(3),
                        plateLetters = reader.GetString(4),
                        plateNumbers = reader.GetString(5),
                        disability = reader.GetBoolean(6)
                    });
                }
                else
                {
                    return NotFound(new { success = false, message = "User not found" });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Error getting user: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Error retrieving user information", error = ex.Message });
            }
        }
    }
}
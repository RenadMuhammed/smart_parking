using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace SmartParkingAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestConnectionController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public TestConnectionController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpGet("test")]
        public async Task<IActionResult> TestConnection()
        {
            try
            {
                using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
                await connection.OpenAsync();
                
                var command = new SqlCommand("SELECT COUNT(*) FROM [User]", connection);
                var userCount = await command.ExecuteScalarAsync();
                
                return Ok(new 
                { 
                    success = true, 
                    message = "Database connection successful", 
                    userCount = userCount,
                    serverVersion = connection.ServerVersion
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new 
                { 
                    success = false, 
                    message = "Database connection failed", 
                    error = ex.Message 
                });
            }
        }
    }
}
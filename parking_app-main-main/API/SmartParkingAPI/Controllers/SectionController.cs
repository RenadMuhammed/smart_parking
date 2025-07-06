using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SmartParkingAPI.Models.Entities;
using System.Data;

namespace SmartParkingAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SectionController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public SectionController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpGet("garage/{garageId}")]
        public async Task<IActionResult> GetSectionsByGarage(int garageId)
        {
            Console.WriteLine($"📥 Received request for sections in Garage ID = {garageId}");

            try
            {
                var sections = new List<Section>();

                using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
                await connection.OpenAsync();
                Console.WriteLine("✅ DB connection opened");

                var query = @"SELECT Section_id, Garage_id, Total_spots, Available 
                              FROM Section 
                              WHERE Garage_id = @GarageId";

                using var command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("@GarageId", garageId);

                Console.WriteLine("✅ SQL query prepared, executing...");

                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    var section = new Section
                    {
                        SectionId = reader["Section_id"].ToString() ?? "",
                        GarageId = Convert.ToInt32(reader["Garage_id"]),
                        TotalSpots = Convert.ToInt32(reader["Total_spots"]),
                        Available = Convert.ToInt32(reader["Available"])
                    };

                    sections.Add(section);
                }

                Console.WriteLine($"✅ Retrieved {sections.Count} sections");

                return Ok(sections);
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ ERROR in GetSectionsByGarage:");
                Console.WriteLine(ex.ToString()); // full stack trace

                return StatusCode(500, new
                {
                    success = false,
                    message = "Server error occurred while fetching sections.",
                    error = ex.Message
                });
            }
        }
    }
}

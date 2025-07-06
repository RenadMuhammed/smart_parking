using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;

[Route("api/[controller]")]
[ApiController]
public class GarageController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public GarageController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

   
    [HttpGet]
    public async Task<IActionResult> GetGarages()
    {
        try
    {
        using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await connection.OpenAsync();

        var command = new SqlCommand(@"
            SELECT Garage_id, Garage_name, Latitude, Longitude 
            FROM Garage", connection);

        var reader = await command.ExecuteReaderAsync();

        var garages = new List<object>();

        while (await reader.ReadAsync())
        {
            if (reader.IsDBNull(2) || reader.IsDBNull(3))
        {
        continue; // Skip rows with missing coordinates
        }

        garages.Add(new
        {
             garageId = reader.GetInt32(0),
             name = reader.GetString(1),
             latitude = reader.GetDouble(2),
             longitude = reader.GetDouble(3)
        });
}


        return Ok(garages);
    }
    catch (Exception ex)
    {
        return StatusCode(500, new
        {
            success = false,
            message = "Error retrieving garages",
            error = ex.Message
        });
    }
}
    [HttpGet("{garageId}/sections")]
public async Task<IActionResult> GetSections(int garageId)
{
    try
    {
        using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
        await connection.OpenAsync();

        var command = new SqlCommand(@"
            SELECT Section_id, Total_slots, Available 
            FROM Sections 
            WHERE Garage_id = @GarageId", connection);

        command.Parameters.AddWithValue("@GarageId", garageId);

        var reader = await command.ExecuteReaderAsync();

        var sections = new List<object>();

        while (await reader.ReadAsync())
        {
            sections.Add(new
            {
                sectionId = reader.GetString(0),       // Section_id (string)
                totalSlots = reader.GetInt32(1),        // Total_slots (int)
                available = reader.GetBoolean(2)        // Available (bool/bit)
            });
        }

        return Ok(sections);
    }
    catch (Exception ex)
    {
        return StatusCode(500, new
        {
            success = false,
            message = "Error retrieving sections",
            error = ex.Message
        });
    }
}

}
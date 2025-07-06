using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Text.Json;
using SmartParkingAPI.Models.DTO;

namespace SmartParkingAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReservationController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public ReservationController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpPost]
        public async Task<IActionResult> CreateReservation([FromBody] ReservationDTO reservation)
        {
            Console.WriteLine($"🟡 Incoming Reservation: {JsonSerializer.Serialize(reservation)}");

            try
            {
                using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
                await connection.OpenAsync();

                using var transaction = connection.BeginTransaction();

                // First, get the User_id from Username
                var getUserIdCmd = new SqlCommand("SELECT User_id FROM [User] WHERE Username = @Username", connection, transaction);
                getUserIdCmd.Parameters.AddWithValue("@Username", reservation.Username);
                var userId = await getUserIdCmd.ExecuteScalarAsync();

                if (userId == null)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new { success = false, message = "❌ User not found." });
                }

                var checkCmd = new SqlCommand("SELECT Available FROM Section WHERE Section_id = @SectionId", connection, transaction);
                checkCmd.Parameters.AddWithValue("@SectionId", reservation.SectionId);
                var availableSpots = (int?)await checkCmd.ExecuteScalarAsync();

                Console.WriteLine($"🔍 Available spots for Section {reservation.SectionId}: {availableSpots}");

                if (availableSpots == null || availableSpots <= 0)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new { success = false, message = "❌ No available spots in this section." });
                }

                // Since your DB table uses Username, not User_id, we need to use Username
                var insertCmd = new SqlCommand(@"
                    INSERT INTO Reservation (Username, Garage_id, Section_id, Start_time, End_time, Duration, Status)
                    OUTPUT INSERTED.Reservation_id
                    VALUES (@Username, @GarageId, @SectionId, @StartTime, @EndTime, @Duration, @Status)", connection, transaction);

                insertCmd.Parameters.AddWithValue("@Username", reservation.Username);
                insertCmd.Parameters.AddWithValue("@GarageId", reservation.GarageId);
                insertCmd.Parameters.AddWithValue("@SectionId", reservation.SectionId);
                insertCmd.Parameters.AddWithValue("@StartTime", reservation.StartTime);
                insertCmd.Parameters.AddWithValue("@EndTime", reservation.EndTime);
                insertCmd.Parameters.AddWithValue("@Duration", reservation.Duration);
                insertCmd.Parameters.AddWithValue("@Status", reservation.Status);

                var reservationId = (int)await insertCmd.ExecuteScalarAsync();
                Console.WriteLine($"🟢 Reservation created with ID: {reservationId}");

                var updateCmd = new SqlCommand(@"
                    UPDATE Section
                    SET Available = Available - 1
                    WHERE Section_id = @SectionId", connection, transaction);

                updateCmd.Parameters.AddWithValue("@SectionId", reservation.SectionId);
                await updateCmd.ExecuteNonQueryAsync();

                await transaction.CommitAsync();

                return StatusCode(201, new
                {
                    success = true,
                    message = "✅ Reservation created and available spot decremented.",
                    reservationId = reservationId
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ EXCEPTION: " + ex.Message);
                return StatusCode(500, new
                {
                    success = false,
                    message = "❌ Error creating reservation.",
                    error = ex.Message
                });
            }
        }

        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateReservationStatus(int id, [FromBody] StatusUpdateDto dto)
        {
            try
            {
                using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
                await connection.OpenAsync();

                var updateCmd = new SqlCommand(@"
                    UPDATE Reservation 
                    SET Status = @Status 
                    WHERE Reservation_id = @Id", connection);

                updateCmd.Parameters.AddWithValue("@Status", dto.Status);
                updateCmd.Parameters.AddWithValue("@Id", id);

                var rowsAffected = await updateCmd.ExecuteNonQueryAsync();

                if (rowsAffected > 0)
                {
                    // If cancelling, increment available spots
                    if (dto.Status == "cancelled")
                    {
                        var getSection = new SqlCommand(@"
                            SELECT Section_id FROM Reservation 
                            WHERE Reservation_id = @Id", connection);
                        getSection.Parameters.AddWithValue("@Id", id);
                        
                        var sectionId = await getSection.ExecuteScalarAsync() as string;
                        
                        if (!string.IsNullOrEmpty(sectionId))
                        {
                            var incrementCmd = new SqlCommand(@"
                                UPDATE Section 
                                SET Available = Available + 1 
                                WHERE Section_id = @SectionId", connection);
                            incrementCmd.Parameters.AddWithValue("@SectionId", sectionId);
                            await incrementCmd.ExecuteNonQueryAsync();
                        }
                    }

                    return Ok(new { success = true, message = "Status updated successfully" });
                }

                return NotFound(new { success = false, message = "Reservation not found" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, error = ex.Message });
            }
        }

        [HttpGet("pending/{username}")]
        public async Task<IActionResult> GetLatestPendingReservation(string username)
        {
            try
            {
                using var connection = new SqlConnection(_configuration.GetConnectionString("DefaultConnection"));
                await connection.OpenAsync();

                var cmd = new SqlCommand(@"
                    SELECT TOP 1 Reservation_id 
                    FROM Reservation 
                    WHERE Username = @Username AND Status = 'pending' 
                    ORDER BY Start_time DESC", connection);

                cmd.Parameters.AddWithValue("@Username", username);
                
                var reservationId = await cmd.ExecuteScalarAsync();
                
                if (reservationId != null)
                {
                    return Ok(new { reservationId = (int)reservationId });
                }

                return NotFound(new { message = "No pending reservation found" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    public class StatusUpdateDto
    {
        public string Status { get; set; }
    }
}
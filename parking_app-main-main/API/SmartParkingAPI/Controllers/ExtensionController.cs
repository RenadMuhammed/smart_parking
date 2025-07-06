using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Dapper;
using System;

namespace SmartParkingAPI.Controllers
{
    [ApiController]
    [Route("api/extension")]
    public class ExtensionController : ControllerBase
    {
        private readonly string _connectionString;
        
        public ExtensionController(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection");
        }
        
        [HttpGet("check/{reservationId}")]
        public async Task<IActionResult> CheckExtensionEligibility(int reservationId)
        {
            using var connection = new SqlConnection(_connectionString);
            
            // Get reservation details
            var query = @"
                SELECT r.*, g.Garage_name, s.Total_spots, s.Available
                FROM Reservation r
                INNER JOIN Garage g ON r.Garage_id = g.Garage_id
                INNER JOIN Section s ON r.Section_id = s.Section_id
                WHERE r.Reservation_id = @ReservationId 
                AND r.Status = 'active'";
            
            var reservation = await connection.QueryFirstOrDefaultAsync<dynamic>(query, 
                new { ReservationId = reservationId });
            
            if (reservation == null)
                return NotFound(new { success = false, message = "Active reservation not found" });
            
            // Check if reservation ends within 20 minutes
            var endTime = (DateTime)reservation.End_time;
            var minutesRemaining = (endTime - DateTime.Now).TotalMinutes;
            
            if (minutesRemaining > 20)
                return BadRequest(new { 
                    success = false, 
                    message = "Can only extend within 20 minutes of expiry",
                    minutesRemaining = minutesRemaining
                });
            
            return Ok(new
            {
                success = true,
                reservationId = reservation.Reservation_id,
                garageName = reservation.Garage_name,
                sectionId = reservation.Section_id,
                currentEndTime = reservation.End_time,
                minutesRemaining = minutesRemaining,
                canExtend = true
            });
        }
        
        [HttpPost("create")]
        public async Task<IActionResult> CreateExtension([FromBody] ExtensionRequest request)
        {
            using var connection = new SqlConnection(_connectionString);
            
            // Get current reservation
            var currentReservation = await connection.QueryFirstOrDefaultAsync<dynamic>(
                @"SELECT * FROM Reservation WHERE Reservation_id = @ReservationId AND Status = 'active'",
                new { ReservationId = request.OriginalReservationId });
            
            if (currentReservation == null)
                return BadRequest(new { success = false, message = "Active reservation not found" });
            
            // Create new reservation for extension
            var newEndTime = ((DateTime)currentReservation.End_time).AddMinutes(request.ExtensionMinutes);
            
            var insertQuery = @"
                INSERT INTO Reservation (Username, Garage_id, Section_id, Start_time, End_time, Status, Duration)
                VALUES (@Username, @GarageId, @SectionId, @StartTime, @EndTime, 'pending', @Duration)
                SELECT SCOPE_IDENTITY()";
            
            var newReservationId = await connection.QuerySingleAsync<int>(insertQuery, new
            {
                Username = currentReservation.Username,
                GarageId = currentReservation.Garage_id,
                SectionId = currentReservation.Section_id,
                StartTime = currentReservation.End_time, // Extension starts when current ends
                EndTime = newEndTime,
                Duration = request.ExtensionMinutes
            });
            
            // Link the extension to original reservation
            await connection.ExecuteAsync(
                @"INSERT INTO ReservationExtensions (Original_id, Extension_id) VALUES (@Original, @Extension)",
                new { Original = request.OriginalReservationId, Extension = newReservationId });
            
            return Ok(new
            {
                success = true,
                extensionReservationId = newReservationId,
                newEndTime = newEndTime,
                extensionMinutes = request.ExtensionMinutes,
                price = request.ExtensionMinutes * 10.0 / 60.0 // Calculate price
            });
        }
        
        [HttpPost("confirm/{extensionId}")]
        public async Task<IActionResult> ConfirmExtension(int extensionId)
        {
            using var connection = new SqlConnection(_connectionString);
            
            // Update extension reservation to active
            await connection.ExecuteAsync(
                "UPDATE Reservation SET Status = 'active' WHERE Reservation_id = @Id",
                new { Id = extensionId });
            
            // Get the original reservation ID
            var originalId = await connection.QuerySingleOrDefaultAsync<int>(
                "SELECT Original_id FROM ReservationExtensions WHERE Extension_id = @ExtensionId",
                new { ExtensionId = extensionId });
            
            if (originalId > 0)
            {
                // Update original reservation end time to match extension start time
                var extensionStart = await connection.QuerySingleAsync<DateTime>(
                    "SELECT Start_time FROM Reservation WHERE Reservation_id = @Id",
                    new { Id = extensionId });
                
                await connection.ExecuteAsync(
                    "UPDATE Reservation SET End_time = @EndTime WHERE Reservation_id = @Id",
                    new { EndTime = extensionStart, Id = originalId });
            }
            
            return Ok(new { success = true, message = "Extension confirmed" });
        }
    }
    
    public class ExtensionRequest
    {
        public int OriginalReservationId { get; set; }
        public int ExtensionMinutes { get; set; }
    }
}
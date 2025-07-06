using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Data.SqlClient;
using Dapper;
using Microsoft.Extensions.Configuration;

namespace SmartParkingAPI.Services
{
    public class ReservationExpiryService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private Timer? _timer; // ✅ Removed 'readonly'
        private readonly string _connectionString;

        public ReservationExpiryService(IServiceProvider serviceProvider, IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _connectionString = configuration.GetConnectionString("DefaultConnection")!;
        }

        protected override Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _timer = new Timer(CheckExpiredReservations, null, TimeSpan.Zero, TimeSpan.FromMinutes(1));
            return Task.CompletedTask;
        }

        private async void CheckExpiredReservations(object? state)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);

                var expiredReservations = await connection.QueryAsync<dynamic>(@"
                    SELECT r.Reservation_id, r.Section_id, r.Username, r.End_time
                    FROM Reservation r
                    WHERE r.Status = 'active' 
                    AND r.End_time < GETDATE()");

                foreach (var reservation in expiredReservations)
                {
                    await connection.ExecuteAsync("UPDATE Reservation SET Status = 'expired' WHERE Reservation_id = @ReservationId",
                        new { ReservationId = reservation.Reservation_id });

                    await connection.ExecuteAsync("UPDATE Section SET Available = Available + 1 WHERE Section_id = @SectionId",
                        new { SectionId = reservation.Section_id });

                    Console.WriteLine($"✅ Expired reservation {reservation.Reservation_id} and freed up spot");
                }

                var soonToExpire = await connection.QueryAsync<dynamic>(@"
                    SELECT r.Reservation_id, r.Username, r.Section_id, r.Garage_id, 
                           r.Start_time, r.End_time, g.Garage_name
                    FROM Reservation r
                    INNER JOIN Garage g ON r.Garage_id = g.Garage_id
                    WHERE r.Status = 'active' 
                    AND r.End_time > GETDATE() 
                    AND r.End_time <= DATEADD(minute, 20, GETDATE())
                    AND NOT EXISTS (
                        SELECT 1 FROM ExtensionNotifications 
                        WHERE Reservation_id = r.Reservation_id)");

                foreach (var reservation in soonToExpire)
                {
                    await connection.ExecuteAsync(
                        "INSERT INTO ExtensionNotifications (Reservation_id, Sent_at) VALUES (@ReservationId, GETDATE())",
                        new { ReservationId = reservation.Reservation_id });

                    Console.WriteLine($"📱 Should send extension notification for reservation {reservation.Reservation_id}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Error in expiry service: {ex.Message}");
            }
        }

        public override void Dispose()
        {
            _timer?.Dispose();
            base.Dispose();
        }
    }
}

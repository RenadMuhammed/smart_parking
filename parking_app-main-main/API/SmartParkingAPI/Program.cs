using Microsoft.EntityFrameworkCore;
using SmartParkingAPI.Data; // Make sure this namespace matches your ApplicationDbContext location
using Microsoft.Data.SqlClient;
using SmartParkingAPI.Services;
var builder = WebApplication.CreateBuilder(args);

// Add controllers
builder.Services.AddControllers();
builder.Services.AddHostedService<ReservationExpiryService>();
// Enable CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder =>
        {
            builder.AllowAnyOrigin()
                   .AllowAnyMethod()
                   .AllowAnyHeader();
        });
});

// ✅ Register ApplicationDbContext with SQL Server
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

// ✅ Test connection on startup
try
{
    using var connection = new SqlConnection(builder.Configuration.GetConnectionString("DefaultConnection"));
    connection.Open();
    Console.WriteLine("Database connected successfully!");
}
catch (Exception ex)
{
    Console.WriteLine($"Database connection failed: {ex.Message}");
}

app.UseCors("AllowAll");
app.MapControllers();

app.Run("http://0.0.0.0:5000");

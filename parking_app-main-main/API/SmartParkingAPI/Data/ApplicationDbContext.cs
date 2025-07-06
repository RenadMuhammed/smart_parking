using Microsoft.EntityFrameworkCore;
using SmartParkingAPI.Models.Entities;
using Microsoft.Data.SqlClient;

namespace SmartParkingAPI.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // Register your tables here
        public DbSet<User> Users { get; set; }
        public DbSet<Garage> Garages { get; set; }
        public DbSet<Section> Sections { get; set; }
        public DbSet<Reservation> Reservations { get; set; }

        // Customize model behavior and relationships
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Section → Garage (many-to-one)
            modelBuilder.Entity<Section>()
                .HasOne(s => s.Garage)
                .WithMany(g => g.Sections)
                .HasForeignKey(s => s.GarageId);

            // Reservation → User (many-to-one)
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId);

            // Reservation → Garage (many-to-one)
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Garage)
                .WithMany()
                .HasForeignKey(r => r.GarageId);

            // Reservation → Section (many-to-one)
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Section)
                .WithMany()
                .HasForeignKey(r => r.SectionId);
        }
    }
}

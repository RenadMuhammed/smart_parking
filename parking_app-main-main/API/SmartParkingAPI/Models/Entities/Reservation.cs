namespace SmartParkingAPI.Models.Entities
{
    public class Reservation
    {
        public int ReservationId { get; set; }

        public int UserId { get; set; }
        public int GarageId { get; set; }
        public string SectionId { get; set; }  // 🔁 Updated from int to string

        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }

        public int Duration { get; set; }
        public string Status { get; set; }

        public User User { get; set; }
        public Garage Garage { get; set; }
        public Section Section { get; set; }   // Add this for navigation
    }
}

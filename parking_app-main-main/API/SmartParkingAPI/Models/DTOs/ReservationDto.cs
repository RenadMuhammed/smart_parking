namespace SmartParkingAPI.Models.DTO
{
    public class ReservationDTO
    {
        public string Username { get; set; }  // Add this
        public int UserId { get; set; }      // Keep this if needed for other purposes
        public int GarageId { get; set; }
        public string SectionId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public int Duration { get; set; }
        public string Status { get; set; }
    }
}
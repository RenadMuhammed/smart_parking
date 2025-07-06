namespace SmartParkingAPI.Models.Entities
{
    public class User
    {
        public int UserId { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }
        public string Email { get; set; }
        public string LicensePlate { get; set; }
        public bool Disability { get; set; }
    }
}

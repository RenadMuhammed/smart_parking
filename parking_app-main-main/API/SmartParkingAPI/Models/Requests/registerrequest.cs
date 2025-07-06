namespace SmartParkingAPI.Models.Requests
{
    public class RegisterRequest
    {
        public string NationalId { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Password { get; set; } = null!;
        public string PlateLetters { get; set; } = null!;   
        public string PlateNumbers { get; set; } = null!;   
        public bool Disability { get; set; }
    }
}

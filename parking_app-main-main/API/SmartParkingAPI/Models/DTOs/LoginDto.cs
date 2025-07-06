namespace SmartParkingAPI.Models.DTO
{
    public class LoginDTO
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
    }
}

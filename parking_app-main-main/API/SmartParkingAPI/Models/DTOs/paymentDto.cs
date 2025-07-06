namespace SmartParkingAPI.Models.DTO
{
    public class PaymentDTO
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string CardNumber { get; set; } = string.Empty;
        public string CardType { get; set; } = string.Empty;
        public string ExpiryDate { get; set; } = string.Empty;
        public string Cvv { get; set; } = string.Empty;
    }
}
using System.ComponentModel.DataAnnotations.Schema;
namespace SmartParkingAPI.Models.Entities

{
    public class Section
    {
        public string SectionId { get; set; }
        public int GarageId { get; set; }
        public int TotalSpots { get; set; }
        public int Available { get; set; }

        // ✅ Add this if EF expects navigation between Section → Garage
        [ForeignKey("GarageId")]
        public Garage Garage { get; set; }  // <-- this resolves the error
    }
}

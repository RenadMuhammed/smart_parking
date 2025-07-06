using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SmartParkingAPI.Models.Entities;

public class Garage
{
    public int GarageId { get; set; }
    public string GarageName { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }

    // ✅ Optional: if you want to navigate from Garage to its Sections
    public ICollection<Section> Sections { get; set; }
}

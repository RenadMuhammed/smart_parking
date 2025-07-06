class ParkingSpotModel {
  final String id;
  final String floorId;
  final bool isOccupied;

  ParkingSpotModel({required this.id, required this.floorId, required this.isOccupied});

  factory ParkingSpotModel.fromJson(Map<String, dynamic> json) {
    return ParkingSpotModel(
      id: json['id'],
      floorId: json['floorId'],
      isOccupied: json['isOccupied'],
    );
  }
}
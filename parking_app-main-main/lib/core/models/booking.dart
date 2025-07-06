class BookingModel {
  final String id;
  final String userId;
  final String spotId;
  final DateTime startTime;
  final DateTime endTime;

  BookingModel({
    required this.id,
    required this.userId,
    required this.spotId,
    required this.startTime,
    required this.endTime,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userId: json['userId'],
      spotId: json['spotId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }

  get status => null;
}
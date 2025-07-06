class Section {
  final String sectionId;
  final int garageId;
  final int totalSpots;
  final int available; // stored as int (e.g., 1 or 0)

  Section({
    required this.sectionId,
    required this.garageId,
    required this.totalSpots,
    required this.available,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      sectionId: json['sectionId'] ?? '',
      garageId: json['garageId'] ?? 0,
      totalSpots: json['totalSpots'] ?? 0,
      available: json['available'] ?? 0,
    );
  }
}

class LocationModel {
  final List<double> coordinates;

  LocationModel({required this.coordinates});

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawCoordinates = json['coordinates'] as List;
    return LocationModel(
      coordinates: rawCoordinates.map((coord) => (coord as num).toDouble()).toList(),
    );
  }
}

class AgeRangeModel {
  final int lowerLimit;
  final int upperLimit;

  AgeRangeModel({
    required this.lowerLimit,
    required this.upperLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'lower_limit': lowerLimit,
      'upper_limit': upperLimit,
    };
  }

  factory AgeRangeModel.fromJson(Map<String, dynamic> json) {
    return AgeRangeModel(
      lowerLimit: json['lower_limit'] as int,
      upperLimit: json['upper_limit'] as int,
    );
  }
} 
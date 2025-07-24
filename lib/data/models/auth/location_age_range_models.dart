import 'package:nookly/core/utils/logger.dart';

class LocationModel {
  final List<double> coordinates;

  LocationModel({required this.coordinates});

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.info('LocationModel.fromJson - Input JSON: $json');
      
      final coordinatesRaw = json['coordinates'];
      AppLogger.info('LocationModel.fromJson - Raw coordinates: $coordinatesRaw (type: ${coordinatesRaw.runtimeType})');
      
      if (coordinatesRaw == null) {
        AppLogger.warning('LocationModel.fromJson - Coordinates is null, using default');
        return LocationModel(coordinates: [0.0, 0.0]);
      }
      
      if (coordinatesRaw is! List) {
        AppLogger.error('LocationModel.fromJson - Coordinates is not a List, it is: ${coordinatesRaw.runtimeType}');
        return LocationModel(coordinates: [0.0, 0.0]);
      }
      
      final coordinates = coordinatesRaw.map((coord) {
        AppLogger.info('LocationModel.fromJson - Processing coordinate: $coord (type: ${coord.runtimeType})');
        
        if (coord is int) {
          return coord.toDouble();
        } else if (coord is double) {
          return coord;
        } else if (coord is String) {
          return double.tryParse(coord) ?? 0.0;
        } else {
          AppLogger.error('LocationModel.fromJson - Unknown coordinate type: ${coord.runtimeType}');
          return 0.0;
        }
      }).toList();
      
      AppLogger.info('LocationModel.fromJson - Final coordinates: $coordinates');
      return LocationModel(coordinates: coordinates);
      
    } catch (e, stackTrace) {
      AppLogger.error('LocationModel.fromJson - Error parsing location: $e', e, stackTrace);
      return LocationModel(coordinates: [0.0, 0.0]);
    }
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
      lowerLimit: json['lower_limit'] as int? ?? 18,
      upperLimit: json['upper_limit'] as int? ?? 80,
    );
  }
} 
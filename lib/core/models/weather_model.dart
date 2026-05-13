class WeatherModel {
  const WeatherModel({
    required this.city,
    required this.region,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.precipitationMm,
    required this.chanceOfRain,
    required this.condition,
    required this.windKph,
    required this.agriculturalRecommendation,
    required this.fetchedAt,
  });

  final String city;
  final String region;
  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final double precipitationMm;
  final int chanceOfRain;
  final String condition;
  final double windKph;
  final String agriculturalRecommendation;
  final DateTime fetchedAt;
}

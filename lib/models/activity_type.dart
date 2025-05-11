enum ActivityType {
  start,
  end,
  accommodation,
  restaurant,
  attraction,
  afternoon,
  breakfast,
  lunch,
  dinner,
  beach,
  cafe,
  bar,
  night,
  returnHome;

  String get turkceAdi {
    switch (this) {
      case ActivityType.start:
        return 'Başlangıç';
      case ActivityType.end:
        return 'Bitiş';
      case ActivityType.accommodation:
        return 'Konaklama';
      case ActivityType.restaurant:
        return 'Restoran';
      case ActivityType.attraction:
        return 'Gezilecek Yer';
      case ActivityType.afternoon:
        return 'Öğleden Sonra';
      case ActivityType.breakfast:
        return 'Kahvaltı';
      case ActivityType.lunch:
        return 'Öğle';
      case ActivityType.dinner:
        return 'Akşam';
      case ActivityType.beach:
        return 'Plaj';
      case ActivityType.cafe:
        return 'Kafe';
      case ActivityType.bar:
        return 'Bar';
      case ActivityType.night:
        return 'Gece';
      case ActivityType.returnHome:
        return 'Dönüş';
    }
  }
} 
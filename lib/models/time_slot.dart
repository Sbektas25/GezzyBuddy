enum TimeSlot {
  morning,
  breakfast,
  lunch,
  afternoon,
  dinner,
  beach,      // plaj etkinliği
  cafe,
  bar,
  night,      // dönüş öncesi gece aktivitesi
  returnHome;

  String get turkceAdi {
    switch (this) {
      case TimeSlot.morning:
        return 'Sabah';
      case TimeSlot.breakfast:
        return 'Kahvaltı';
      case TimeSlot.lunch:
        return 'Öğle';
      case TimeSlot.afternoon:
        return 'Öğleden Sonra';
      case TimeSlot.dinner:
        return 'Akşam';
      case TimeSlot.beach:
        return 'Plaj';
      case TimeSlot.cafe:
        return 'Kafe';
      case TimeSlot.bar:
        return 'Bar';
      case TimeSlot.night:
        return 'Gece';
      case TimeSlot.returnHome:
        return 'Dönüş';
    }
  }
} 
enum Category {
  all,
  farmhouse,
  villa,
  hotel,
  car,
  hourly,
  flights,
}

extension CategoryExt on Category {
  String get label {
    switch (this) {
      case Category.farmhouse:
        return 'Farmhouses';
      case Category.villa:
        return 'Villas';
      case Category.hotel:
        return 'Hotels';
      case Category.car:
        return 'Car Rentals';
      case Category.hourly:
        return 'Hourly';
      case Category.flights:
        return 'Flights';
      case Category.all:
        return 'All';
    }
  }

  static Category fromLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('farm')) return Category.farmhouse;
    if (l.contains('villa')) return Category.villa;
    if (l.contains('hotel')) return Category.hotel;
    if (l.contains('car')) return Category.car;
    if (l.contains('hour')) return Category.hourly;
    if (l.contains('flight')) return Category.flights;
    return Category.all;
  }
}

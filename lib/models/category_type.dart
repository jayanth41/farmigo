enum CategoryType {
  all,
  farmhouses,
  villas,
  hotels,
  carRentals,
  hourlyRentals,
}

CategoryType parseCategory(String label) {
  final l = label.toLowerCase();
  if (l.contains('farm')) return CategoryType.farmhouses;
  if (l.contains('villa')) return CategoryType.villas;
  if (l.contains('hotel')) return CategoryType.hotels;
  if (l.contains('car')) return CategoryType.carRentals;
  if (l.contains('hour')) return CategoryType.hourlyRentals;
  return CategoryType.all;
}

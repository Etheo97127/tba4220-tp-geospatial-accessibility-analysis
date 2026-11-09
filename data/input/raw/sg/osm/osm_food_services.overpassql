[out:json][timeout:600];
area(id:3600536780)->.sg;
(
  nwr["amenity"~"^(cafe|fast_food|food_court|ice_cream|restaurant)$"](area.sg);
);
out center meta;

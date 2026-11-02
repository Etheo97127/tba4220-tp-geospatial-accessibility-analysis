[out:json][timeout:600];
area(id:3600536780)->.sg;
(
  nwr["amenity"~"^(clinic|dentist|doctors|hospital|pharmacy)$"](area.sg);
  nwr["healthcare"~"^(centre|clinic|dentist|doctor|hospital|pharmacy)$"](area.sg);
);
out center meta;

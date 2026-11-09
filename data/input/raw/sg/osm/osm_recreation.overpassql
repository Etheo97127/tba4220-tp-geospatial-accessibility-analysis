[out:json][timeout:600];
area(id:3600536780)->.sg;
(
  nwr["amenity"~"^(arts_centre|cinema|community_centre|theatre)$"](area.sg);
  nwr["leisure"~"^(fitness_centre|fitness_station|park|playground|sports_centre|sports_hall|stadium)$"](area.sg);
  nwr["tourism"~"^(gallery|museum)$"](area.sg);
);
out center meta;

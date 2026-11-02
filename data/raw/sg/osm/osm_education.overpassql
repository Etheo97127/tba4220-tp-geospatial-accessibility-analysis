[out:json][timeout:600];
area(id:3600536780)->.sg;
(
  nwr["amenity"~"^(childcare|college|kindergarten|language_school|library|music_school|prep_school|school|university)$"](area.sg);
);
out center meta;

[out:json][timeout:600];
area(id:3600536780)->.sg;
(
  nwr["amenity"~"^(marketplace)$"](area.sg);
  nwr["shop"~"^(bakery|beverages|butcher|coffee|confectionery|convenience|dairy|deli|frozen_food|greengrocer|pastry|seafood|supermarket|tea)$"](area.sg);
);
out center meta;

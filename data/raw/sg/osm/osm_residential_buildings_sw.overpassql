[out:json][timeout:600];
area(id:3600536780)->.sg;
way["building"~"^(apartments|residential|house|detached|semidetached_house|terrace|bungalow|dormitory)$"](area.sg)(1.15,103.55,1.35,103.85);
out tags geom qt;

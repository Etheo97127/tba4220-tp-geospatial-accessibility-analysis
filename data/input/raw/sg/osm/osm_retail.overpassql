[out:json][timeout:600];
area(id:3600536780)->.sg;
(
  nwr["shop"~"^(appliance|bag|bed|boutique|clothes|curtain|department_store|doityourself|electronics|fashion_accessories|furniture|general|hardware|household_linen|houseware|interior_decoration|kitchen|lighting|mall|shoes|variety_store)$"](area.sg);
);
out center meta;

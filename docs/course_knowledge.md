# TBA4220 Geospatial Analytics — Course Knowledge (Lectures 1–8)

Context for AI assistants helping our group project. This summarises what the team has been taught in TBA4220 (NUS, Sem 1 2026/27, lecturer Jithin Vachery). All work is in **R**. Prefer the packages, functions and methods listed here; if you suggest something outside them, explain it briefly because we have not been taught it.

---

## Packages we know

| Area | Packages |
| --- | --- |
| Core R / functional | base R, `purrr` (tidyverse) |
| Plotting | base graphics, `ggplot2`, `patchwork` |
| Spatial data | `sf` (main), `sp` (legacy S4), `units` |
| Maps | `ggplot2` + `geom_sf`, `tmap` (v4 syntax) |
| Data manipulation | `dplyr` (tidyverse), base R |
| Point patterns | `eks` (spatial KDE), `spatstat` (K/L functions) |
| Spatial autocorrelation | `spdep` |
| Course datasets | `spData`, `ozmaps`, `GISTools`/`spgwr`, `SpatialEpi`, `eks` |

---

## L1 — GIS concepts and R fundamentals

- **GIS**: links *location data* (where) with *attribute data* (what) in layers; the geospatial question is "what happened where" (e.g. John Snow's 1854 cholera map).
- **R basics**: everything is an object; every action is a function call; functions return their last expression (`return()` exits early).
- **Vectors**: 1-based indexing; element-wise arithmetic; **recycling** of shorter vectors; `:` binds tighter than arithmetic (`1:n-1` ≠ `1:(n-1)`); `seq()`, `rep(times=, each=)`, `sort()` vs `order()`, `pmax()/pmin()`.
- **Indexing**: positive (select), negative (exclude), logical (filter, recycled), character (by `names`); assignment into subsets can extend vectors with `NA`.
- **Missing values**: `NA` spreads through operations; test with `is.na()` (never `x == NA`); `NaN` from `0/0`; `is.nan()`.
- **Objects**: atomic vectors (one mode, coercion via `c()`) vs recursive (lists, functions); `mode()`, `length()`, `class()`, `attributes()`.
- **Structures**: factor (`levels`, integer codes), `tapply()` for group-wise summaries, arrays/matrices (column-major, `dim`), lists (`[[ ]]`/`$` element vs `[ ]` sub-list), data frames (list of equal-length columns; `df[rows, cols]`, `rbind`, `cbind`).
- **Control flow**: `if/else`, `for`, `while`, `repeat`, `break`, `next`; functions with default and named arguments.

## L2 — Functionals and plotting

- **Functional programming**: first-class and pure functions; functionals replace `for` loops.
- **purrr**: `map` (→ list), `modify` (same type as input), `walk` (side effects, returns input invisibly), `map2`, `imap`, `pmap` (named list → named args); predicates `some/every/none`, `detect/detect_index`, `keep/discard`.
- **Base apply family**: `lapply`, `tapply`, `apply(m, 1 = rows / 2 = cols, f)` (never on data frames).
- **Base graphics**: high-level (`plot`, `hist`, `qqnorm`, `contour`), low-level (`points`, `lines`, `abline`, `text`, `legend`, `polygon`), interactive (`locator`, `identify`); `type=` options; `par()` (e.g. `mfrow`) vs per-call parameters.
- **ggplot2 (grammar of graphics)**: data + aesthetic mappings (`aes`) + layers (geoms + stats) + scales + coord + facets + theme. Mapping inside `aes()` vs setting outside it. Geoms: point, smooth, boxplot, histogram, freqpoly, bar, line/path, polygon. `facet_wrap`, `facet_grid`.
- **patchwork**: combine plots with `+`, `|`, `/`, `plot_layout()`.

## L3 — Mapping, spatial data models, CRS

- **Vector vs raster** data; vector = points, lines, polygons (shapefiles).
- Draw a polygon from its coordinate matrix (`plot(type='n')` + `polygon()`, or `geom_polygon`).
- **sp**: `SpatialPolygonsDataFrame` is an S4 object; slots via `@`: `data`, `polygons`, `plotOrder`, `bbox`, `proj4string`. Spatial*/Spatial*DataFrame = without/with attributes.
- **sf**: data frame + geometry column; `ggplot() + geom_sf(aes(fill = var)) + coord_sf()`; layering multiple sf objects; `geom_sf_label`; normal geoms on top.
- **CRS** = datum + projection + additional parameters. No projection preserves both area (equal-area) and shape (conformal). `st_crs()`, `coord_sf(crs = st_crs("EPSG:3112"))`.
- **sf helpers**: `st_geometry_type`, `st_bbox`, `st_area`, `st_cast` (e.g. MULTIPOLYGON → POLYGON), `st_as_sf`, `st_combine`, `st_union`. MULTIPOLYGON needed for islands or polygons with holes.

## L4 — tmap and spatial operations

- **tmap**: `qtm()` quick map; full map = `tm_shape(data)` + layers (`tm_polygons`, `tm_fill`, `tm_borders`, `tm_dots`, `tm_bubbles`, `tm_lines`, `tm_text`); **choropleth** via `tm_polygons("column")`; binning with `fill.scale = tm_scale_intervals(style = "quantile" | "kmeans", values = "brewer.*")` or `tm_scale(breaks = …)`; `tm_layout`, `tm_title`, `tm_style`; `tmap_mode("plot" | "view")` for static vs interactive.
- **Spatial operations (sf)**:
  - Clip by extent: `x[y, ]` (keeps x's columns only)
  - `st_intersection(x, y)` (combines attributes of both)
  - `st_buffer(x, dist)` (distance in CRS units; use a projected CRS)
  - `st_union()` (dissolve; returns `sfc`, wrap with `st_sf()`)
  - Point-in-polygon: `st_contains(polys, pts)` + `lengths()` to count
  - `st_area()` (with units; `units::set_units(a, km^2)`), `st_distance()` (matrix with units)
- All inputs must share the same CRS.

## L5 — Attribute operations, spatial joins, sf internals

- **Attribute data** = non-spatial information attached to geometries. Geometry is **sticky** (kept unless `st_drop_geometry()`, `$`, `[[ ]]`, `pull()`).
- **Subsetting**: base `[ ]`, `subset()`; dplyr `filter()` (rows by condition), `slice()` family (`slice_head/tail/sample/min/max`), `select()` (columns; helpers `a:b`, `-col`, `new = old`, `starts_with`, `ends_with`, `contains`, `last_col`, `all_of` (errors on missing), `any_of`, `where(is.numeric)`, combined with `! & | c()`), `mutate()`, `pull()`, `arrange()`.
- **Pipes**: `|>` / `%>%`.
- **Aggregation**: `aggregate(x["col"], by = list(group), FUN)` or `group_by() |> summarise(…, n = n())`; grouped geometries are unioned.
- **Attribute joins**: `inner_join`, `left_join`, `right_join`, `full_join`; `by = join_by(a == b)`.
- **Spatial subsetting**: `x[y, , op = st_intersects]` (default) or other predicates (`st_disjoint`, `st_within`, `st_touches`); predicates return sparse `sgbp` lists (or a logical matrix with `sparse = FALSE`); `st_filter()`.
- **Spatial join**: `st_join(x, y)` adds y's columns to x by spatial relationship (left join by default, `left = FALSE` for inner; `join = st_is_within_distance, dist = …` for non-overlapping features); may add rows (then re-aggregate).
- **Spatial aggregation**: `aggregate(x = points, by = polygons, FUN = mean)`.
- **Geometry ops**: `st_simplify(dTolerance = …)` (Douglas–Peucker), `st_centroid()` (may fall outside), `st_point_on_surface()` (always inside).
- **Simple Features model (OGC standard)**: `sfg` (one geometry: POINT, LINESTRING, POLYGON, MULTI*, GEOMETRYCOLLECTION) → `sfc` (list column of geometries + CRS) → `sf` (data frame + sfc column, `st_sf()`).

## L6 — Kernel density estimation (first-order point patterns)

- Spatial statistics motivations: explore/visualise, model the generating process, test hypotheses; spatial data needs cluster detection and allows for spatial autocorrelation.
- **Tobler's first law**: near things are more related than distant things.
- **KDE**: nonparametric PDF from points; `f(x) = 1/(nh) · Σ K((x − xᵢ)/h)`; Gaussian kernel `K(x) = e^(−x²/2)/√(2π)`; other kernels: uniform, triangular, Epanechnikov, biweight.
- **Bandwidth h** is crucial (small → overfit/spiky, large → underfit/smooth; Silverman, Sheather–Jones); kernel choice matters little with lots of data.
- R: `geom_histogram(aes(y = after_stat(density)))`, `geom_density(bw = h)`, `geom_density_2d()` (contour lines), `geom_density_2d_filled()` (contour bands).
- **Spatial KDE (eks)**: `st_kde(sf_points)` (returns `tidy_ks`, `grid`, `sf` contour polygons); `st_get_contour(kde, cont = c(25, 50, 75))`; plot with `geom_sf` or tmap; grouped tibbles + `facet_wrap` for comparisons. Convert factor contour labels with `as.numeric(as.character(x))`.

## L7 — Hex binning and second-order point patterns

- **2-D binning** against overplotting: `geom_bin_2d()`, `geom_hex()` (needs X/Y columns, e.g. from `st_coordinates()`); hexagons preferred (equidistant neighbours, efficient tessellation, less visual bias).
- **Second-order analysis**: fixed intensity but points not independent (e.g. contagion); compare with **complete spatial randomness (CSR)** / Poisson process.
- **K-function** `K(d) = λ⁻¹E(N_d)`; under CSR `K(d) = πd²`; above → clustering at scale d, below → dispersion; estimator `K̂(d) = A/(n(n−1)) · ΣΣ I(dᵢⱼ < d)`, with edge correction weights `wᵢⱼ`.
- **L-function** `L(d) = √(K(d)/π)`; equals d under CSR.
- **Inference**: simulation **envelopes** (visual) and the **MAD test** (`max |K̂ − K_CSR|`, p-value).
- **Marked point patterns** (e.g. forced vs non-forced burglaries): **cross-K/cross-L** functions.
- R (`spatstat`): `as.ppp()`, `Kest`, `Lest`, `envelope(x, Kest)`, `mad.test(x, Lest)`, `marks()`, `Kcross/Lcross(x, i, j)`, `superimpose(a = ppp1, b = ppp2)`; `correction = 'border'`.

## L8 — Spatial attribute analysis and autocorrelation

- Locations (polygons/points) are **fixed**; the attribute values zᵢ are random.
- Models: trend in mean (`zᵢ ~ N(a + bxᵢ + cyᵢ, σ²)`) or correlation depending on distance / polygon **adjacency matrix**.
- **Spatial autocorrelation**: nearby values are related; violates the independence assumption of standard statistics.
- **Visual test**: map the real variable among randomly permuted copies (`sample()`).
- **Neighbours** (`spdep`): `poly2nb()` (queen default; `queen = FALSE` for rook), `nb2lines()` to plot the network, `nb2listw()` (row-standardised weights, style "W").
- **Lagged mean** `z̃ᵢ` = mean of neighbours' values (`lag.listw()`); **Moran plot** (`moran.plot()`).
- **Moran's I**: range set by eigenvalues of (W + Wᵀ)/2; null expectation `E(I) = −1/(n−1)`; `moran.test(z, listw)` (randomisation null by default; `randomisation = FALSE` for normality); low p-value + I > E(I) → positive autocorrelation.

---

## How the course fits together

1. **R foundations** (L1–L2) → **spatial data models and maps** (L3–L4) → **attribute and spatial manipulation** (L5) → **spatial statistics** (L6–L8).
2. The statistics lectures all quantify Tobler's law with a "near" weighting (bandwidth h, distance d, or weights W) and a randomness benchmark (CSR simulation or random permutation):
   - L6: where are events dense? (KDE, descriptive)
   - L7: do events cluster around each other? (K/L functions vs CSR)
   - L8: do nearby areas have similar values? (Moran's I vs random permutation)

## Course datasets we have used

`georgia` (gSRDF), `ozmaps` (states, electorates), `newhaven` (blocks, tracts, roads, breach, burglaries `burgres.f`/`burgres.n`), `tornados` (torn, us_states), `spData` (world, coffee_data, nz, nz_height, cycle_hire, seine), `eks` (grevilleasf, wa), `spatstat` (bramblecanes), `SpatialEpi` (pennLC), plus `mpg`, `iris`, `diamonds`, `faithful`.

# watershedtools <img src="man/figures/logo.svg" align="right" height="139" alt="" />

[![R-CMD-check](https://github.com/chrislyonsKY/watershedtools/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/chrislyonsKY/watershedtools/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/watershedtools)](https://CRAN.R-project.org/package=watershedtools)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![codecov](https://app.codecov.io/gh/chrislyonsKY/watershedtools/branch/main/graph/badge.svg)](https://app.codecov.io/gh/chrislyonsKY/watershedtools)

> Hydrologic Analysis Utilities Built on NHDPlus

Provides HUC code validation and hierarchy resolution, watershed boundary
retrieval, upstream and downstream stream tracing via NHDPlus flow direction,
pour point snapping, and feature-watershed spatial overlay. Built on
`nhdplusTools` for data access and `sf` for spatial operations.

## Installation

```r
# Install from CRAN (when available)
install.packages("watershedtools")

# Or install the development version from GitHub
# install.packages("pak")
pak::pak("chrislyonsKY/watershedtools")
```

## Quick Start

```r
library(watershedtools)

# Validate Kentucky HUC codes
validate_huc(c("05", "0510", "05100205"))
#> [1] TRUE TRUE TRUE

# Load bundled Elkhorn Creek flowlines
flowlines <- sf::st_read(
  system.file("extdata", "elkhorn_flowlines.geojson", package = "watershedtools"),
  quiet = TRUE
)

# Trace everything upstream of the main stem confluence
upstream <- trace_upstream(flowlines, comid = 9734460)

# Snap a point to the nearest stream
pt <- sf::st_sf(geometry = sf::st_sfc(sf::st_point(c(-84.68, 38.155)), crs = 4326))
snapped <- snap_pour_point(pt, flowlines)

# Overlay monitoring sites with watershed boundary
sites <- sf::st_read(
  system.file("extdata", "elkhorn_sites.geojson", package = "watershedtools"),
  quiet = TRUE
)
basin <- sf::st_read(
  system.file("extdata", "elkhorn_basin.geojson", package = "watershedtools"),
  quiet = TRUE
)
result <- overlay_features(sites, basin)
```

## Functions

| Function | Description |
|----------|-------------|
| `validate_huc()` | Check HUC code format and validity |
| `huc_level()` | Get the HUC level (2, 4, 6, 8, 10, 12) |
| `parent_huc()` | Truncate to a coarser HUC level |
| `get_watershed()` | Retrieve basin boundary via NLDI |
| `trace_upstream()` | Walk upstream through flowline network |
| `trace_downstream()` | Walk downstream through flowline network |
| `snap_pour_point()` | Snap a point to the nearest flowline |
| `overlay_features()` | Spatial join of features to watershed polygons |

## Sample Data

The package ships with GeoJSON data for **Elkhorn Creek, Kentucky** (HUC8 05100205):

- `elkhorn_flowlines.geojson` — 7 NHDPlus-style flowline segments
- `elkhorn_basin.geojson` — watershed boundary polygon
- `elkhorn_sites.geojson` — 5 monitoring sites (USGS gages + KPDES outfalls)

## Real-World Examples

The `examples/` directory contains standalone scripts demonstrating integration
with production data sources:

- **`ky_watershed_analysis.R`** — Full Elkhorn Creek analysis (runs offline)
- **`usgs_gage_delineation.R`** — Delineate watersheds for KY USGS gages via NLDI
- **`permit_watershed_overlay.R`** — Overlay KPDES permits with HUC boundaries

All scripts save maps and results to `examples/output/`.

## License

GPL (>= 3) — see [LICENSE](LICENSE).

## Author

**Chris Lyons** — Kentucky Division of Information Services, GIS Branch

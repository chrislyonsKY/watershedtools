# ============================================================================
# USGS Gage Watershed Delineation — Kentucky
# ============================================================================
# Demonstrates using watershedtools to delineate watersheds for real USGS
# stream gages in Kentucky via the NLDI (Network Linked Data Index).
#
# Data sources:
#   - USGS NWIS (National Water Information System)
#     https://waterdata.usgs.gov/nwis
#   - NLDI API for watershed delineation
#     https://labs.waterdata.usgs.gov/api/nldi/
#   - NHDPlus COMIDs linked to USGS gages
#
# Requirements: nhdplusTools, sf, watershedtools
# Outputs saved to: examples/output/
# ============================================================================

library(watershedtools)
library(sf)

output_dir <- file.path(dirname(sys.frame(1)$ofile %||% "."), "output")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

if (!requireNamespace("nhdplusTools", quietly = TRUE)) {
  stop("This example requires the 'nhdplusTools' package.\n",
       "Install with: install.packages('nhdplusTools')")
}

# --- Kentucky USGS gage sites ------------------------------------------------
# Real USGS gaging stations in central Kentucky with their NHDPlus COMIDs.
# These COMIDs can be looked up at:
#   https://labs.waterdata.usgs.gov/api/nldi/linked-data/nwissite/USGS-{site_no}

ky_gages <- data.frame(
  site_no   = c("03287500",  "03284000",  "03289500",  "03290500",  "03286000"),
  name      = c("Elkhorn Cr at Frankfort",
                 "Kentucky R at Lock 4 nr Frankfort",
                 "S Elkhorn Cr at Fort Spring",
                 "Dix River near Danville",
                 "N Elkhorn Cr near Georgetown"),
  comid     = c(9734472, 9731804, 9735140, 9752810, 9734432),
  longitude = c(-84.870, -84.856, -84.719, -84.633, -84.532),
  latitude  = c(38.200, 38.224, 38.023, 37.557, 38.197),
  stringsAsFactors = FALSE
)

ky_gages_sf <- st_as_sf(ky_gages, coords = c("longitude", "latitude"), crs = 4326)

cat("Kentucky USGS Gages:\n")
for (i in seq_len(nrow(ky_gages))) {
  cat(sprintf("  USGS %s  COMID %-8d  %s\n",
              ky_gages$site_no[i], ky_gages$comid[i], ky_gages$name[i]))
}

# --- Validate associated HUC codes ------------------------------------------

cat("\n--- HUC Validation for Kentucky River Basin ---\n")

ky_river_hucs <- c(
  "05" ,            # Ohio Region
  "0510",           # Kentucky River
  "051001",         # N Fork Kentucky River
  "051002",         # Lower Kentucky River
  "05100205",       # Elkhorn Creek
  "05100101",       # N Fork KY River - upper
  "051003",         # Dix River / Herrington Lake
  "05100301"        # Dix River
)

for (h in ky_river_hucs) {
  cat(sprintf("  HUC%-2d %s  valid=%s\n",
              huc_level(h), h, validate_huc(h)))
}

# --- Delineate watersheds for each gage -------------------------------------

cat("\n--- Watershed Delineation (via NLDI) ---\n")
cat("Note: This requires an internet connection.\n\n")

basins <- list()
for (i in seq_len(nrow(ky_gages))) {
  cat(sprintf("Delineating: %s (COMID %d)...\n",
              ky_gages$name[i], ky_gages$comid[i]))
  tryCatch({
    basins[[i]] <- get_watershed(comid = ky_gages$comid[i])
    cat("  Success\n")
  }, error = function(e) {
    cat(sprintf("  Failed: %s\n", conditionMessage(e)))
    basins[[i]] <<- NULL
  })
}

# Combine successful results
good <- !vapply(basins, is.null, logical(1))
if (any(good)) {
  all_basins <- do.call(rbind, basins[good])
  all_basins$gage_name <- ky_gages$name[good]
  all_basins$site_no <- ky_gages$site_no[good]

  cat(sprintf("\nSuccessfully delineated %d of %d watersheds.\n",
              sum(good), nrow(ky_gages)))

  # Save as GeoPackage
  gpkg_path <- file.path(output_dir, "ky_gage_watersheds.gpkg")
  st_write(all_basins, gpkg_path, delete_dsn = TRUE, quiet = TRUE)
  cat(sprintf("Saved: %s\n", basename(gpkg_path)))

  # Save gage points
  st_write(ky_gages_sf, file.path(output_dir, "ky_gages.gpkg"),
           delete_dsn = TRUE, quiet = TRUE)

  # --- Map ---
  png(file.path(output_dir, "ky_gage_watersheds.png"), width = 1000, height = 700)
  plot(st_geometry(all_basins), col = sf.colors(sum(good), alpha = 0.3),
       border = "grey40",
       main = "Delineated Watersheds for Kentucky USGS Gages")
  plot(st_geometry(ky_gages_sf[good, ]), add = TRUE, pch = 17, col = "red", cex = 1.5)
  text(st_coordinates(ky_gages_sf[good, ]),
       labels = ky_gages$site_no[good],
       pos = 3, cex = 0.7, col = "grey30")
  legend("bottomright",
         legend = ky_gages$name[good],
         fill = sf.colors(sum(good), alpha = 0.3),
         border = "grey40", bg = "white", cex = 0.8)
  dev.off()
  cat("Saved: ky_gage_watersheds.png\n")
} else {
  cat("No watersheds could be delineated. Check internet connection.\n")
}

cat("\nDone!\n")

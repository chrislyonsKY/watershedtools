# ============================================================================
# KPDES Permit — Watershed Overlay Analysis
# ============================================================================
# Overlays Kentucky Pollutant Discharge Elimination System (KPDES) permitted
# facilities with HUC watershed boundaries to determine which watershed
# each discharge point falls within.
#
# Data sources:
#   - KPDES permits: Kentucky Energy & Environment Cabinet
#     https://eec.ky.gov/Environmental-Protection/Water/
#   - EPA ECHO (Enforcement & Compliance History Online)
#     https://echo.epa.gov/
#   - Watershed boundaries: USGS Watershed Boundary Dataset (WBD)
#     Available via nhdplusTools::get_huc()
#
# This example uses synthetic representative data based on real Kentucky
# facility locations. For production use, pull live data from EPA ECHO
# or Kentucky's Open Data portal.
#
# Outputs saved to: examples/output/
# ============================================================================

library(watershedtools)
library(sf)

output_dir <- file.path(dirname(sys.frame(1)$ofile %||% "."), "output")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Synthetic KPDES permit data (based on real KY facility locations) -------
# In production, pull from EPA ECHO API:
#   https://echo.epa.gov/tools/data-downloads
# Or Kentucky Open Data:
#   https://opengisdata.ky.gov/

permits <- data.frame(
  permit_id = c("KY0020150", "KY0021474", "KY0020061", "KY0020168",
                "KY0020320", "KY0024376", "KY0024511", "KY0020788"),
  facility  = c("Frankfort WWTP", "Georgetown WWTP", "Lexington Town Branch WWTP",
                 "Versailles WWTP", "Lawrenceburg WWTP", "Midway WWTP",
                 "Stamping Ground WWTP", "Peaks Mill WWTP"),
  type      = c("major", "major", "major", "minor", "minor",
                "minor", "minor", "minor"),
  longitude = c(-84.860, -84.560, -84.455, -84.730, -84.896,
                -84.683, -84.681, -84.780),
  latitude  = c(38.195, 38.130, 38.035, 38.057, 38.033,
                38.152, 38.265, 38.175),
  stringsAsFactors = FALSE
)

permits_sf <- st_as_sf(permits, coords = c("longitude", "latitude"), crs = 4326)

cat("KPDES Permitted Facilities:\n")
for (i in seq_len(nrow(permits))) {
  cat(sprintf("  %-12s %-30s [%s]\n",
              permits$permit_id[i], permits$facility[i], permits$type[i]))
}

# --- Load Elkhorn Creek basin boundary --------------------------------------

basin <- st_read(
  system.file("extdata", "elkhorn_basin.geojson", package = "watershedtools"),
  quiet = TRUE
)

cat(sprintf("\nTarget watershed: %s (%s)\n", basin$name, basin$huc8))
cat(sprintf("  Area: %.1f sq km\n", basin$areasqkm))

# --- Overlay permits with watershed ------------------------------------------

cat("\n--- Spatial Overlay ---\n")

result <- overlay_features(permits_sf, basin, join = "intersects")

# Classify results
inside <- !is.na(result$huc8)

cat(sprintf("\nFacilities INSIDE %s watershed:\n", basin$name))
inside_df <- result[inside, ]
for (i in seq_len(nrow(inside_df))) {
  cat(sprintf("  %-12s %s\n",
              inside_df$permit_id[i], inside_df$facility[i]))
}

cat(sprintf("\nFacilities OUTSIDE %s watershed:\n", basin$name))
outside_df <- result[!inside, ]
if (nrow(outside_df) > 0) {
  for (i in seq_len(nrow(outside_df))) {
    cat(sprintf("  %-12s %s\n",
                outside_df$permit_id[i], outside_df$facility[i]))
  }
} else {
  cat("  (none)\n")
}

cat(sprintf("\nSummary: %d of %d facilities discharge into %s\n",
            sum(inside), nrow(permits), basin$name))

# --- Nearest-join for facilities outside the basin ----------------------------

cat("\n--- Nearest Watershed Assignment ---\n")

# Use 'nearest' join to assign even outside-basin facilities
nearest_result <- overlay_features(permits_sf, basin, join = "nearest")
cat("All facilities assigned to nearest watershed:\n")
for (i in seq_len(nrow(nearest_result))) {
  cat(sprintf("  %-12s %-30s -> %s\n",
              nearest_result$permit_id[i],
              nearest_result$facility[i],
              nearest_result$name.1[i]))
}

# --- Validate HUC codes for Kentucky basins ----------------------------------

cat("\n--- HUC Validation for KY Basins ---\n")

ky_huc8s <- c(
  "05100205",  # Elkhorn Creek
  "05100206",  # Eagle Creek
  "05100101",  # North Fork Kentucky River
  "05140101",  # Upper Salt River
  "05100204",  # South Fork Elkhorn
  "05130101",  # Licking River - upper
  "06010201"   # Upper Cumberland
)

for (h in ky_huc8s) {
  huc4 <- parent_huc(h, level = 4)
  cat(sprintf("  %s (parent HUC4: %s)  valid=%s\n",
              h, huc4, validate_huc(h)))
}

# --- Generate output maps ---------------------------------------------------

cat("\n--- Generating maps ---\n")

# Map 1: Permit overlay
png(file.path(output_dir, "kpdes_overlay.png"), width = 900, height = 700)
plot(st_geometry(basin), col = "lightcyan", border = "steelblue", lwd = 2,
     main = "KPDES Facilities & Elkhorn Creek Watershed\nKentucky",
     xlim = c(-84.95, -84.40), ylim = c(37.95, 38.30))

# Plot permits by type and location
inside_major <- permits_sf[inside & permits_sf$type == "major", ]
inside_minor <- permits_sf[inside & permits_sf$type == "minor", ]
outside_pts  <- permits_sf[!inside, ]

if (nrow(inside_major) > 0)
  plot(st_geometry(inside_major), add = TRUE, col = "red", pch = 17, cex = 2)
if (nrow(inside_minor) > 0)
  plot(st_geometry(inside_minor), add = TRUE, col = "orange", pch = 16, cex = 1.5)
if (nrow(outside_pts) > 0)
  plot(st_geometry(outside_pts), add = TRUE, col = "grey50", pch = 4, cex = 1.3)

# Load flowlines for context
flowlines <- st_read(
  system.file("extdata", "elkhorn_flowlines.geojson", package = "watershedtools"),
  quiet = TRUE
)
plot(st_geometry(flowlines), col = "steelblue", lwd = 1.5, add = TRUE)

legend("bottomright",
       legend = c("Major permit (inside)", "Minor permit (inside)",
                  "Permit (outside basin)", "Flowlines"),
       col = c("red", "orange", "grey50", "steelblue"),
       pch = c(17, 16, 4, NA), lwd = c(NA, NA, NA, 2),
       bg = "white", cex = 0.9)
dev.off()
cat("  Saved: kpdes_overlay.png\n")

# Map 2: Summary table as CSV
summary_df <- data.frame(
  permit_id = result$permit_id,
  facility  = result$facility,
  type      = result$type,
  in_elkhorn = inside,
  huc8      = ifelse(inside, result$huc8, NA_character_),
  stringsAsFactors = FALSE
)
csv_path <- file.path(output_dir, "kpdes_overlay_results.csv")
write.csv(summary_df, csv_path, row.names = FALSE)
cat(sprintf("  Saved: %s\n", basename(csv_path)))

cat("\nDone! All outputs in:", output_dir, "\n")

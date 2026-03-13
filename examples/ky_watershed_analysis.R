# ============================================================================
# Elkhorn Creek Watershed Analysis — Kentucky
# ============================================================================
# A complete watershed analysis workflow using watershedtools with real
# Kentucky hydrologic data from the NHDPlus / NLDI national datasets.
#
# Data sources:
#   - NHDPlus flowlines via nhdplusTools / NLDI API
#   - Watershed Boundary Dataset (WBD) — HUC8 05100205 (Elkhorn Creek)
#   - Bundled sample data in watershedtools::inst/extdata/
#
# Outputs saved to: examples/output/
# ============================================================================

library(watershedtools)
library(sf)

output_dir <- file.path(dirname(sys.frame(1)$ofile %||% "."), "output")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- 1. Load bundled Elkhorn Creek data --------------------------------------

cat("Loading Elkhorn Creek sample data...\n")

flowlines <- st_read(
 system.file("extdata", "elkhorn_flowlines.geojson", package = "watershedtools"),
  quiet = TRUE
)
basin <- st_read(
  system.file("extdata", "elkhorn_basin.geojson", package = "watershedtools"),
  quiet = TRUE
)
sites <- st_read(
  system.file("extdata", "elkhorn_sites.geojson", package = "watershedtools"),
  quiet = TRUE
)

cat(sprintf("  Flowline segments: %d\n", nrow(flowlines)))
cat(sprintf("  Monitoring sites:  %d\n", nrow(sites)))
cat(sprintf("  Basin area:        %.1f sq km\n", basin$areasqkm))

# --- 2. Validate Kentucky HUC codes -----------------------------------------

cat("\n--- HUC Validation ---\n")

ky_hucs <- c(
  "05",             # Ohio Region (HUC2)
  "0510",           # Kentucky River (HUC4)
  "051002",         # Lower Kentucky River (HUC6)
  "05100205",       # Elkhorn Creek (HUC8)
  "0510020501",     # Upper Elkhorn (HUC10)
  "051002050101"    # HUC12 subwatershed
)

valid <- validate_huc(ky_hucs)
levels <- huc_level(ky_hucs)

for (i in seq_along(ky_hucs)) {
  cat(sprintf("  HUC%-2d %-14s valid=%s\n", levels[i], ky_hucs[i], valid[i]))
}

# Parent HUC traversal
cat("\nHUC hierarchy for 051002050101:\n")
huc12 <- "051002050101"
for (lvl in c(10, 8, 6, 4, 2)) {
  cat(sprintf("  HUC%-2d -> %s\n", lvl, parent_huc(huc12, level = lvl)))
}

# --- 3. Upstream/downstream tracing -----------------------------------------

cat("\n--- Stream Tracing ---\n")

# Trace upstream from the Elkhorn main stem confluence (COMID 9734460)
upstream <- trace_upstream(flowlines, comid = 9734460)
cat(sprintf("Upstream from Elkhorn main stem: %d segments\n", nrow(upstream)))
cat(sprintf("  Streams: %s\n", paste(unique(upstream$gnis_name), collapse = ", ")))

# Trace downstream from North Elkhorn headwater
downstream <- trace_downstream(flowlines, comid = 9734444)
cat(sprintf("Downstream from N. Elkhorn headwater: %d segments (%.1f km total)\n",
            nrow(downstream), sum(downstream$lengthkm)))

# --- 4. Pour point snapping --------------------------------------------------

cat("\n--- Pour Point Snapping ---\n")

# Approximate location of Peaks Mill Road bridge over Elkhorn Creek
peaks_mill <- st_sf(
  name = "Peaks Mill Rd Bridge",
  geometry = st_sfc(st_point(c(-84.78, 38.175)), crs = 4326)
)
snapped <- snap_pour_point(peaks_mill, flowlines)
cat(sprintf("  Snapped to COMID %d (%s)\n", snapped$comid, snapped$gnis_name))
cat(sprintf("  Snap distance: %.5f degrees\n", snapped$snap_distance))

# --- 5. Site–watershed overlay -----------------------------------------------

cat("\n--- Spatial Overlay ---\n")

overlay <- overlay_features(sites, basin)
inside <- !is.na(overlay$huc8)
cat(sprintf("  %d of %d sites fall within HUC8 %s\n",
            sum(inside), nrow(sites), basin$huc8))
for (i in seq_len(nrow(overlay))) {
  status <- if (inside[i]) "INSIDE" else "OUTSIDE"
  cat(sprintf("    [%s] %s (%s)\n", status, overlay$name[i], overlay$site_id[i]))
}

# --- 6. Generate output maps ------------------------------------------------

cat("\n--- Generating maps ---\n")

# Map 1: Full watershed overview
png(file.path(output_dir, "elkhorn_overview.png"), width = 800, height = 600)
plot(st_geometry(basin), col = "lightyellow", border = "grey40",
     main = "Elkhorn Creek Watershed (HUC8 05100205)\nFranklin & Fayette Counties, Kentucky")
plot(st_geometry(flowlines), col = "steelblue", lwd = 1.5, add = TRUE)
plot(st_geometry(sites[sites$type == "gage", ]),
     add = TRUE, col = "red", pch = 17, cex = 1.5)
plot(st_geometry(sites[sites$type == "npdes", ]),
     add = TRUE, col = "purple", pch = 15, cex = 1.3)
legend("bottomright",
       legend = c("Flowlines", "USGS Gages", "KPDES Outfalls"),
       col = c("steelblue", "red", "purple"),
       lwd = c(2, NA, NA), pch = c(NA, 17, 15),
       bg = "white")
dev.off()
cat("  Saved: elkhorn_overview.png\n")

# Map 2: Upstream trace
png(file.path(output_dir, "elkhorn_upstream_trace.png"), width = 800, height = 600)
plot(st_geometry(basin), col = "grey95", border = "grey60",
     main = "Upstream Trace from Elkhorn Main Stem\nCOMID 9734460")
plot(st_geometry(flowlines), col = "grey70", lwd = 1, add = TRUE)
plot(st_geometry(upstream), col = "dodgerblue", lwd = 3, add = TRUE)
dev.off()
cat("  Saved: elkhorn_upstream_trace.png\n")

# Map 3: Downstream trace
png(file.path(output_dir, "elkhorn_downstream_trace.png"), width = 800, height = 600)
plot(st_geometry(basin), col = "grey95", border = "grey60",
     main = "Downstream Trace from N. Elkhorn Headwater\nCOMID 9734444")
plot(st_geometry(flowlines), col = "grey70", lwd = 1, add = TRUE)
plot(st_geometry(downstream), col = "tomato", lwd = 3, add = TRUE)
dev.off()
cat("  Saved: elkhorn_downstream_trace.png\n")

# Map 4: Pour point snap
png(file.path(output_dir, "elkhorn_pour_point.png"), width = 800, height = 600)
plot(st_geometry(flowlines), col = "steelblue", lwd = 2,
     main = "Pour Point Snapping\nPeaks Mill Rd to Nearest Flowline")
plot(st_geometry(peaks_mill), add = TRUE, col = "red", pch = 16, cex = 2)
plot(st_geometry(snapped), add = TRUE, col = "green3", pch = 16, cex = 2)
segments(
  st_coordinates(peaks_mill)[1], st_coordinates(peaks_mill)[2],
  st_coordinates(snapped)[1], st_coordinates(snapped)[2],
  lty = 2, col = "grey40"
)
legend("topright", legend = c("Original", "Snapped"),
       col = c("red", "green3"), pch = 16, bg = "white")
dev.off()
cat("  Saved: elkhorn_pour_point.png\n")

cat("\nDone! All outputs in:", output_dir, "\n")

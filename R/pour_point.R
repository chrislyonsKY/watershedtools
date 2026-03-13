# pour_point.R — watershedtools
# Pour point snapping to the nearest flowline

#' Snap Pour Point to Nearest Flowline
#'
#' Moves a point to the nearest location on a flowline network, ensuring
#' that subsequent analyses reference an actual stream reach rather than an
#' off-network location. Uses [sf::st_nearest_points()] for geometric
#' snapping.
#'
#' @param point An `sf` or `sfc` point object (single feature) representing
#'   the approximate pour point.
#' @param flowlines An `sf` data frame of flowlines (linestring geometry)
#'   to snap to.
#' @param tolerance Numeric. Maximum snap distance in metres. When s2
#'   geometry is enabled (the default in sf >= 1.0), distances are always
#'   geodesic metres regardless of CRS. Points farther than this from all
#'   flowlines produce an error. Default is `Inf` (always snap).
#'
#' @returns An `sf` point object located on the nearest flowline. Attributes
#'   from the matched flowline are attached, along with a `snap_distance`
#'   column recording how far the point was moved.
#'
#' @export
#'
#' @examples
#' flowlines <- sf::st_read(
#'   system.file("extdata", "elkhorn_flowlines.geojson", package = "watershedtools"),
#'   quiet = TRUE
#' )
#'
#' # A point near Elkhorn Creek
#' pt <- sf::st_sf(geometry = sf::st_sfc(sf::st_point(c(-84.68, 38.155)), crs = 4326))
#' snapped <- snap_pour_point(pt, flowlines)
#'
#' # Visualise the snap
#' plot(sf::st_geometry(flowlines), col = "steelblue", lwd = 2)
#' plot(sf::st_geometry(pt), add = TRUE, col = "red", pch = 16, cex = 1.4)
#' plot(sf::st_geometry(snapped), add = TRUE, col = "green3", pch = 16, cex = 1.4)
#' legend("topright", legend = c("Original", "Snapped"),
#'        col = c("red", "green3"), pch = 16)
snap_pour_point <- function(point, flowlines, tolerance = Inf) {
  if (!inherits(point, "sf") && !inherits(point, "sfc")) {
    stop("`point` must be an sf or sfc object.", call. = FALSE)
  }
  if (!inherits(flowlines, "sf")) {
    stop("`flowlines` must be an sf data frame.", call. = FALSE)
  }

  # Ensure same CRS
  if (sf::st_crs(point) != sf::st_crs(flowlines)) {
    point <- sf::st_transform(point, sf::st_crs(flowlines))
  }

  # Find nearest flowline segment
  nearest_idx <- sf::st_nearest_feature(point, flowlines)
  nearest_line <- flowlines[nearest_idx, ]

  # Compute the snapped location on the line
  snap_linestring <- sf::st_nearest_points(
    sf::st_geometry(point)[1L],
    sf::st_geometry(nearest_line)[1L]
  )
  snapped_pts <- sf::st_cast(snap_linestring, "POINT")
  snapped_pt <- snapped_pts[2L]  # second point lies on the line

  # Distance check
  dist <- sf::st_distance(sf::st_geometry(point)[1L], snapped_pt)
  dist_val <- as.numeric(dist)
  if (dist_val > tolerance) {
    stop(
      "Nearest flowline is ", round(dist_val, 2), " units away, ",
      "exceeding tolerance of ", tolerance, ".",
      call. = FALSE
    )
  }

  # Assemble result
  attrs <- sf::st_drop_geometry(nearest_line)
  attrs$snap_distance <- dist_val
  sf::st_sf(attrs, geometry = sf::st_sfc(snapped_pt, crs = sf::st_crs(flowlines)))
}

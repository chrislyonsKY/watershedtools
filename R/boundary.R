# boundary.R — watershedtools
# Watershed boundary retrieval via NLDI

#' Get Watershed Boundary
#'
#' Retrieves the drainage basin boundary for a given NHDPlus COMID or
#' geographic point using the NLDI (Network Linked Data Index) web service.
#' Requires an internet connection and the \pkg{nhdplusTools} package.
#'
#' When a `point` is supplied the nearest NHDPlus flowline is identified
#' automatically with [nhdplusTools::discover_nhdplus_id()], and its
#' drainage basin is returned.
#'
#' @param point An `sf` or `sfc` point object (single feature) to use as
#'   the watershed outlet. Automatically transformed to WGS 84 if needed.
#'   Supply either `point` or `comid`, not both.
#' @param comid Integer. An NHDPlus COMID identifying the flowline whose
#'   drainage basin to retrieve. Supply either `comid` or `point`, not both.
#'
#' @returns An `sf` polygon (or multipolygon) object representing the
#'   upstream drainage basin in WGS 84 (EPSG:4326).
#'
#' @export
#'
#' @examplesIf requireNamespace("nhdplusTools", quietly = TRUE)
#' \donttest{
#' # Get watershed for a COMID on Elkhorn Creek, KY
#' basin <- get_watershed(comid = 9734460)
#' plot(sf::st_geometry(basin))
#'
#' # Get watershed from a point (Frankfort, KY)
#' pt <- sf::st_sfc(sf::st_point(c(-84.87, 38.20)), crs = 4326)
#' basin2 <- get_watershed(point = pt)
#' }
get_watershed <- function(point = NULL, comid = NULL) {
  check_package("nhdplusTools")

  if (is.null(point) && is.null(comid)) {
    stop("One of `point` or `comid` must be provided.", call. = FALSE)
  }
  if (!is.null(point) && !is.null(comid)) {
    stop("Provide either `point` or `comid`, not both.", call. = FALSE)
  }

  if (!is.null(point)) {
    if (!inherits(point, "sf") && !inherits(point, "sfc")) {
      stop("`point` must be an sf or sfc object.", call. = FALSE)
    }
    # Transform to WGS 84 if needed
    if (!is.na(sf::st_crs(point)) && sf::st_crs(point) != sf::st_crs(4326)) {
      point <- sf::st_transform(point, 4326)
    }
    comid <- nhdplusTools::discover_nhdplus_id(point = point)
    if (is.null(comid) || length(comid) == 0L || is.na(comid[1L])) {
      stop("No NHDPlus flowline found near the provided point.", call. = FALSE)
    }
    comid <- comid[1L]
  }

  nldi_feature <- list(
    featureSource = "comid",
    featureID     = as.character(comid)
  )
  basin <- nhdplusTools::get_nldi_basin(nldi_feature = nldi_feature)

  if (is.null(basin) || nrow(basin) == 0L) {
    stop("No basin returned for COMID ", comid, ".", call. = FALSE)
  }

  basin
}

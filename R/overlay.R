# overlay.R — watershedtools
# Spatial overlay of features with watershed polygons

#' Overlay Features with Watersheds
#'
#' Performs a spatial join to determine which watershed polygon each feature
#' falls within. This is useful for attributing monitoring sites, permits,
#' or other point data to their containing watershed or HUC boundary.
#'
#' When column names collide between `features` and `watersheds`, the
#' watershed columns receive a `.ws` suffix (e.g. `name` becomes `name.ws`).
#'
#' @param features An `sf` data frame of features (typically points) to
#'   overlay.
#' @param watersheds An `sf` data frame of watershed polygons.
#' @param join Character. Spatial predicate: `"intersects"` (default),
#'   `"within"`, or `"nearest"`. `"nearest"` assigns each feature to the
#'   closest watershed regardless of containment.
#'
#' @returns An `sf` data frame with the original `features` geometry and
#'   both feature and matched watershed attributes. Features that do not
#'   fall within any watershed will have `NA` for watershed columns
#'   (except when `join = "nearest"`). Duplicate column names from
#'   `watersheds` are disambiguated with a `.ws` suffix.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Load sample Elkhorn Creek data
#' sites <- sf::st_read(
#'   system.file("extdata", "elkhorn_sites.geojson", package = "watershedtools"),
#'   quiet = TRUE
#' )
#' basin <- sf::st_read(
#'   system.file("extdata", "elkhorn_basin.geojson", package = "watershedtools"),
#'   quiet = TRUE
#' )
#'
#' # Which sites fall inside the basin?
#' result <- overlay_features(sites, basin)
#' print(result[, c("site_id", "huc8")])
#' }
overlay_features <- function(features, watersheds, join = "intersects") {
  if (!inherits(features, "sf")) {
    stop("`features` must be an sf data frame.", call. = FALSE)
  }
  if (!inherits(watersheds, "sf")) {
    stop("`watersheds` must be an sf data frame.", call. = FALSE)
  }

  join <- match.arg(join, c("intersects", "within", "nearest"))

  # Harmonise CRS
  if (sf::st_crs(features) != sf::st_crs(watersheds)) {
    watersheds <- sf::st_transform(watersheds, sf::st_crs(features))
  }

  # Disambiguate shared column names by renaming in watersheds
  feat_names <- setdiff(names(features), attr(features, "sf_column"))
  ws_names   <- setdiff(names(watersheds), attr(watersheds, "sf_column"))
  shared     <- intersect(feat_names, ws_names)
  if (length(shared) > 0L) {
    new_names <- names(watersheds)
    for (s in shared) {
      new_names[new_names == s] <- paste0(s, ".ws")
    }
    names(watersheds) <- new_names
  }

  if (join == "nearest") {
    nearest_idx <- sf::st_nearest_feature(features, watersheds)
    ws_attrs <- sf::st_drop_geometry(watersheds[nearest_idx, ])
    result <- cbind(features, ws_attrs)
  } else {
    join_fn <- switch(join,
      intersects = sf::st_intersects,
      within     = sf::st_within
    )
    result <- sf::st_join(features, watersheds, join = join_fn, left = TRUE)
  }

  result
}

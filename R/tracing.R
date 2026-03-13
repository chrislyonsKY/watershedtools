# tracing.R — watershedtools
# Upstream and downstream network tracing on local flowline data

#' Trace Upstream Network
#'
#' Traverses a local NHDPlus flowline network upstream from a starting
#' COMID, following the `hydroseq` / `dnhydroseq` topology. Returns all
#' flowline segments that drain into the specified reach (inclusive).
#'
#' @param flowlines An `sf` data frame of NHDPlus flowlines containing at
#'   minimum the columns `comid`, `hydroseq`, and `dnhydroseq`.
#' @param comid Integer. The NHDPlus COMID to trace upstream from.
#'
#' @returns An `sf` data frame — the subset of `flowlines` that are
#'   upstream of (and including) the specified COMID.
#'
#' @export
#'
#' @examples
#' # Load Elkhorn Creek sample flowlines
#' flowlines <- sf::st_read(
#'   system.file("extdata", "elkhorn_flowlines.geojson", package = "watershedtools"),
#'   quiet = TRUE
#' )
#'
#' # Everything upstream of the main-stem confluence
#' upstream <- trace_upstream(flowlines, comid = 9734460)
#' plot(sf::st_geometry(upstream), col = "steelblue", lwd = 2)
trace_upstream <- function(flowlines, comid) {
  validate_flowlines(flowlines)

  start_row <- flowlines[flowlines$comid == comid, ]
  if (nrow(start_row) == 0L) {
    stop("COMID ", comid, " not found in flowlines.", call. = FALSE)
  }

  start_hs <- start_row$hydroseq[1L]
  collected <- start_hs
  queue <- start_hs

  while (length(queue) > 0L) {
    current <- queue[1L]
    queue <- queue[-1L]
    upstream_hs <- flowlines$hydroseq[flowlines$dnhydroseq == current]
    upstream_hs <- upstream_hs[!upstream_hs %in% collected]
    if (length(upstream_hs) > 0L) {
      collected <- c(collected, upstream_hs)
      queue <- c(queue, upstream_hs)
    }
  }

  flowlines[flowlines$hydroseq %in% collected, ]
}

#' Trace Downstream Network
#'
#' Traverses a local NHDPlus flowline network downstream from a starting
#' COMID, following the `dnhydroseq` linkages. Returns all flowline
#' segments reached by flowing downstream (inclusive).
#'
#' @param flowlines An `sf` data frame of NHDPlus flowlines containing at
#'   minimum the columns `comid`, `hydroseq`, and `dnhydroseq`.
#' @param comid Integer. The NHDPlus COMID to trace downstream from.
#'
#' @returns An `sf` data frame — the subset of `flowlines` that are
#'   downstream of (and including) the specified COMID.
#'
#' @export
#'
#' @examples
#' # Load Elkhorn Creek sample flowlines
#' flowlines <- sf::st_read(
#'   system.file("extdata", "elkhorn_flowlines.geojson", package = "watershedtools"),
#'   quiet = TRUE
#' )
#'
#' # Follow North Elkhorn Creek downstream to the mouth
#' downstream <- trace_downstream(flowlines, comid = 9734444)
#' plot(sf::st_geometry(flowlines), col = "grey70")
#' plot(sf::st_geometry(downstream), col = "tomato", lwd = 2, add = TRUE)
trace_downstream <- function(flowlines, comid) {
  validate_flowlines(flowlines)

  start_row <- flowlines[flowlines$comid == comid, ]
  if (nrow(start_row) == 0L) {
    stop("COMID ", comid, " not found in flowlines.", call. = FALSE)
  }

  collected_hs <- start_row$hydroseq[1L]
  current_hs <- start_row$dnhydroseq[1L]

  while (current_hs != 0 && !is.na(current_hs)) {
    if (current_hs %in% collected_hs) break
    match_row <- flowlines[flowlines$hydroseq == current_hs, ]
    if (nrow(match_row) == 0L) break
    collected_hs <- c(collected_hs, current_hs)
    current_hs <- match_row$dnhydroseq[1L]
  }

  flowlines[flowlines$hydroseq %in% collected_hs, ]
}

# ---- internal helpers -------------------------------------------------------

#' Validate flowline input
#' @param flowlines Object to check.
#' @returns Invisible `TRUE`; throws an error on failure.
#' @noRd
validate_flowlines <- function(flowlines) {
  if (!inherits(flowlines, "sf")) {
    stop("`flowlines` must be an sf data frame.", call. = FALSE)
  }
  required <- c("comid", "hydroseq", "dnhydroseq")
  missing <- setdiff(required, names(flowlines))
  if (length(missing) > 0L) {
    stop(
      "`flowlines` is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

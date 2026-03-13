# utils.R — watershedtools
# Internal utility functions (not exported)

#' Check if an internet connection is available
#'
#' Tests connectivity by attempting to reach the NLDI web service.
#'
#' @returns Logical scalar.
#' @noRd
has_internet <- function() {
  tryCatch({
    suppressWarnings(
      readLines("https://labs.waterdata.usgs.gov/api/nldi/", n = 1L)
    )
    TRUE
  }, error = function(e) FALSE)
}

#' Require a suggested package
#'
#' @param pkg Character. Package name.
#' @returns Invisible `TRUE` if available; throws an error otherwise.
#' @noRd
check_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      sprintf(
        "Package '%s' is required but not installed. Install with: install.packages(\"%s\")",
        pkg, pkg
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Load bundled sample data
#'
#' @param filename Character. File name within `inst/extdata/`.
#' @returns An `sf` object.
#' @noRd
load_sample_data <- function(filename) {
  path <- system.file("extdata", filename, package = "watershedtools")
  if (path == "") {
    stop("Sample data file '", filename, "' not found.", call. = FALSE)
  }
  sf::st_read(path, quiet = TRUE)
}

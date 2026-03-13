# GitHub Copilot Instructions — watershedtools

> Hydrologic Analysis Utilities Built on NHDPlus
> Part of [Null Island Labs](https://github.com/null-island-labs) R geospatial toolkit

## Package Context

HUC codes are ALWAYS character type (preserve leading zeros). Built on NHDPlus data model. nhdplusTools is Suggests — check with requireNamespace(). Tracing uses NHDPlus flow direction attributes. Spatial filter before loading NHD data (never load entire dataset).

## Exported API

validate_huc(), get_watershed(), trace_upstream(), trace_downstream(), snap_pour_point(), overlay_features()

## Dependencies

- **Imports (always available):** sf
- **Suggests (check at runtime):** nhdplusTools, dplyr

When using a Suggested package, ALWAYS check first:
```r
if (!requireNamespace("pkg", quietly = TRUE)) {
  cli::cli_abort(c(
    "Package {.pkg pkg} is required for this feature.",
    "i" = "Install it with: {.code install.packages('pkg')}"
  ))
}
```

## CRAN Compliance (Non-Negotiable)

This package targets CRAN. Every function must:

- Have `@returns` documenting the return value
- Have `@examples` with runnable code, or `@examplesIf` for network-dependent examples
- Never write outside `tempdir()` in examples or tests
- Use `\donttest{}` for slow examples (> 5 sec), NEVER `\dontrun{}`
- Never comment out example code
- Never use `library()` or `require()` inside package code — use `::` notation
- Pass `R CMD check --as-cran` with 0 errors, 0 warnings

## R Coding Conventions

- R >= 4.1.0 (native pipe `|>` is acceptable)
- roxygen2 with markdown enabled (`Roxygen: list(markdown = TRUE)`)
- testthat edition 3
- Function names: `snake_case`
- Use `cli::cli_abort()` for user-facing errors (if cli is imported), `stop()` otherwise
- Use `withr::local_tempdir()` in tests for temp file cleanup
- File paths via explicit arguments, never `getwd()` assumptions
- No `print()` for user messages — use `cli::cli_inform()` or `message()`

## Documentation Style

```r
#' Brief Title of Function
#'
#' Longer description of what the function does. Reference other functions
#' with [other_function()]. Reference other packages with 'pkgname'.
#'
#' @param x Description of x. An [sf] object or path to spatial file.
#' @param bbox Numeric vector of length 4: `c(xmin, ymin, xmax, ymax)`.
#'
#' @returns An [sf] tibble with columns: `id`, `name`, `geometry`.
#'
#' @export
#'
#' @examplesIf has_internet()
#' result <- my_function(bbox = c(-84.5, 38.0, -84.3, 38.2))
#'
#' @examples
#' # Using bundled sample data (always runs)
#' sample <- system.file("extdata", "sample.gpkg", package = "watershedtools")
#' result <- my_function(sample)
```

## Testing Conventions

```r
test_that("function returns sf", {
  # Use bundled sample data
  sample <- system.file("extdata", "sample.gpkg", package = "watershedtools")
  result <- my_function(sample)
  expect_s3_class(result, "sf")
})

test_that("network function works", {
  skip_on_cran()
  skip_if_not(has_internet())
  result <- network_function(bbox = c(-84.5, 38.0, -84.3, 38.2))
  expect_s3_class(result, "sf")
})
```

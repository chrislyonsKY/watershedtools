# huc.R — watershedtools
# HUC code validation and hierarchy utilities

#' Validate HUC Codes
#'
#' Checks whether hydrologic unit codes (HUC) are syntactically valid.
#' Validates that codes are character strings of the correct length
#' (2, 4, 6, 8, 10, or 12 digits) containing only numeric characters.
#' HUC codes must be stored as character to preserve leading zeros.
#'
#' @param huc Character vector of HUC codes to validate.
#'
#' @returns A logical vector the same length as `huc`. `TRUE` indicates
#'   a valid HUC code; `FALSE` indicates an invalid one. `NA` inputs
#'   yield `FALSE`.
#'
#' @export
#'
#' @examples
#' # Valid Kentucky HUC codes at different levels
#' validate_huc(c("05", "0510", "051002", "05100205"))
#'
#' # HUC12 — finest resolution
#' validate_huc("051002050101")
#'
#' # Invalid: wrong length, non-digits, or stripped leading zeros
#' validate_huc(c("5", "abc", "123", "0510020"))
#'
#' # NA values return FALSE
#' validate_huc(c("05100205", NA_character_))
validate_huc <- function(huc) {
  if (!is.character(huc)) {
    stop(
      "`huc` must be a character vector. ",
      "HUC codes have leading zeros that are lost when stored as numeric.",
      call. = FALSE
    )
  }

  valid_lengths <- c(2L, 4L, 6L, 8L, 10L, 12L)

  vapply(huc, function(h) {
    if (is.na(h)) return(FALSE)
    nch <- nchar(h)
    nch %in% valid_lengths && grepl("^[0-9]+$", h)
  }, logical(1), USE.NAMES = FALSE)
}

#' Get HUC Level
#'
#' Returns the HUC level (2, 4, 6, 8, 10, or 12) for each code.
#' Invalid codes return `NA`.
#'
#' @param huc Character vector of HUC codes.
#'
#' @returns An integer vector of HUC levels, or `NA_integer_` for invalid codes.
#'
#' @export
#'
#' @examples
#' huc_level(c("05", "0510", "05100205", "051002050101"))
huc_level <- function(huc) {
  valid <- validate_huc(huc)
  lvl <- nchar(huc)
  lvl[!valid] <- NA_integer_
  as.integer(lvl)
}

#' Extract Parent HUC Code
#'
#' Truncates a HUC code to a coarser resolution. For example, a HUC12 can
#' be truncated to its parent HUC10, HUC8, etc.
#'
#' @param huc Character vector of HUC codes.
#' @param level Integer. Target HUC level (2, 4, 6, 8, or 10). Must be
#'   coarser (shorter) than the input codes.
#'
#' @returns A character vector of parent HUC codes. Returns `NA_character_`
#'   where the input is invalid or `level` is not coarser than the input.
#'
#' @export
#'
#' @examples
#' # Get the HUC8 parent of a HUC12
#' parent_huc("051002050101", level = 8)
#'
#' # Vectorised
#' parent_huc(c("05100205", "05100206"), level = 4)
parent_huc <- function(huc, level) {
  valid_levels <- c(2L, 4L, 6L, 8L, 10L)
  level <- as.integer(level)
  if (length(level) != 1L || !level %in% valid_levels) {
    stop("`level` must be one of 2, 4, 6, 8, or 10.", call. = FALSE)
  }

  valid <- validate_huc(huc)
  result <- rep(NA_character_, length(huc))
  can_truncate <- valid & nchar(huc) > level
  result[can_truncate] <- substr(huc[can_truncate], 1L, level)
  result
}
